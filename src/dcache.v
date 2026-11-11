// Cache de Datos L1 Totalmente Asociativa (Fully Associative) de Doble Acceso
// Politica: Write-Through + Write-Allocate, reemplazo FIFO con prioridad a lineas invalidas.
// Soporta 2 accesos concurrentes desde la etapa MEM (via 1 y via 2) hacia 1 unico puerto de dmem.

module dcache #(
    parameter ENABLE_DCACHE = 1,
    parameter NUM_LINES     = 8
)(
    input         clk,
    input         reset,
    // Puerto Via 1 (etapa MEM - mas antigua)
    input         MemReadM,
    input         MemWriteM,
    input  [31:0] AddrM,
    input  [31:0] WriteDataM,
    output [31:0] ReadDataM,
    // Puerto Via 2 (etapa MEM - mas joven)
    input         MemReadM2,
    input         MemWriteM2,
    input  [31:0] AddrM2,
    input  [31:0] WriteDataM2,
    output [31:0] ReadDataM2,
    // Senal de espera cuando ambas vias requieren el puerto unico de dmem a la vez
    output        MemStall,
    // Unico puerto hacia la memoria de datos (dmem)
    output        MemWrite_dmem,
    output [31:0] DataAdr_dmem,
    output [31:0] WriteData_dmem,
    input  [31:0] ReadData_dmem,
    // Telemetria y desempeno
    output        hit1_out,
    output        hit2_out,
    output reg [31:0] cache_accesses,
    output reg [31:0] cache_hits,
    output reg [31:0] cache_misses,
    output reg [31:0] dual_mem_pairs
);

  reg        valid      [0:NUM_LINES-1];
  reg [29:0] cache_tag  [0:NUM_LINES-1];
  reg [31:0] cache_data [0:NUM_LINES-1];
  reg [2:0]  fifo_ptr;
  reg        prev_mem_stall;

  wire [29:0] tag1 = AddrM[31:2];
  wire [29:0] tag2 = AddrM2[31:2];
  wire        same_word = (tag1 == tag2);

  // Busqueda asociativa en paralelo (CAM)
  reg                  hit1, hit2;
  reg [2:0]            hit1_idx, hit2_idx;
  reg [31:0]           cache_rd1, cache_rd2;
  reg                  has_free_line;
  reg [2:0]            free_idx;
  integer              i;

  always @* begin
    hit1          = 1'b0;
    hit2          = 1'b0;
    hit1_idx      = 3'd0;
    hit2_idx      = 3'd0;
    cache_rd1     = 32'b0;
    cache_rd2     = 32'b0;
    has_free_line = 1'b0;
    free_idx      = 3'd0;

    for (i = 0; i < NUM_LINES; i = i + 1) begin
      if (ENABLE_DCACHE && valid[i] && (cache_tag[i] == tag1)) begin
        hit1      = 1'b1;
        hit1_idx  = i[2:0];
        cache_rd1 = cache_data[i];
      end
      if (ENABLE_DCACHE && valid[i] && (cache_tag[i] == tag2)) begin
        hit2      = 1'b1;
        hit2_idx  = i[2:0];
        cache_rd2 = cache_data[i];
      end
      if (!valid[i] && !has_free_line) begin
        has_free_line = 1'b1;
        free_idx      = i[2:0];
      end
    end
  end

  wire [2:0] alloc_idx = has_free_line ? free_idx : fifo_ptr;

  // Bypass Store-to-Load intra-par: si via 1 es sw y via 2 es lw a la misma direccion
  wire st_to_ld_bypass   = ENABLE_DCACHE & MemWriteM & MemReadM2 & same_word;
  wire both_miss_same_lw = ENABLE_DCACHE & MemReadM  & MemReadM2 & ~hit1 & same_word;

  // Determinacion de si cada via necesita el unico puerto de dmem en este ciclo
  wire need_dmem1 = MemWriteM  | (MemReadM  & ~hit1);
  wire need_dmem2 = MemWriteM2 | (MemReadM2 & ~hit2 & ~st_to_ld_bypass);

  // MemStall se activa por 1 ciclo solo si ambas vias necesitan el puerto unico de dmem
  assign MemStall = ENABLE_DCACHE & need_dmem1 & need_dmem2 & ~both_miss_same_lw;

  // Asignacion del unico puerto hacia dmem
  // Si MemStall == 1: se prioriza leer el lw con miss (sin escribir aun el sw) para cargarlo en cache
  wire stall_serve_v1 = MemReadM & ~hit1;
  wire normal_use_v2  = ENABLE_DCACHE ? (need_dmem2 & ~need_dmem1) : (MemWriteM2 | MemReadM2);

  assign DataAdr_dmem   = MemStall ? (stall_serve_v1 ? AddrM : AddrM2) :
                                     (normal_use_v2  ? AddrM2 : AddrM);
  assign WriteData_dmem = normal_use_v2 ? WriteDataM2 : WriteDataM;
  assign MemWrite_dmem  = MemStall ? 1'b0 : (MemWriteM | MemWriteM2);

  // Salidas de lectura hacia la etapa MEM del datapath
  assign ReadDataM  = (ENABLE_DCACHE & hit1) ? cache_rd1 : ReadData_dmem;
  assign ReadDataM2 = st_to_ld_bypass        ? WriteDataM :
                      (ENABLE_DCACHE & hit2) ? cache_rd2  : ReadData_dmem;

  assign hit1_out = hit1 & (MemReadM | MemWriteM);
  assign hit2_out = (hit2 | st_to_ld_bypass) & (MemReadM2 | MemWriteM2);

  wire is_mem1 = MemReadM  | MemWriteM;
  wire is_mem2 = MemReadM2 | MemWriteM2;

  // Actualizacion secuencial de la cache y contadores de desempeno
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      for (i = 0; i < NUM_LINES; i = i + 1) begin
        valid[i]      <= 1'b0;
        cache_tag[i]  <= 30'b0;
        cache_data[i] <= 32'b0;
      end
      fifo_ptr       <= 3'd0;
      prev_mem_stall <= 1'b0;
      cache_accesses <= 32'd0;
      cache_hits     <= 32'd0;
      cache_misses   <= 32'd0;
      dual_mem_pairs <= 32'd0;
    end else begin
      prev_mem_stall <= MemStall;

      // Conteo de metricas una sola vez por par que entra a MEM
      if (!prev_mem_stall) begin
        if (is_mem1 && is_mem2) begin
          dual_mem_pairs <= dual_mem_pairs + 32'd1;
          cache_accesses <= cache_accesses + 32'd2;
          cache_hits     <= cache_hits   + (hit1 ? 32'd1 : 32'd0) + ((hit2 || st_to_ld_bypass) ? 32'd1 : 32'd0);
          cache_misses   <= cache_misses + (hit1 ? 32'd0 : 32'd1) + ((hit2 || st_to_ld_bypass) ? 32'd0 : 32'd1);
        end else if (is_mem1) begin
          cache_accesses <= cache_accesses + 32'd1;
          if (hit1) cache_hits   <= cache_hits   + 32'd1;
          else      cache_misses <= cache_misses + 32'd1;
        end else if (is_mem2) begin
          cache_accesses <= cache_accesses + 32'd1;
          if (hit2 || st_to_ld_bypass) cache_hits   <= cache_hits   + 32'd1;
          else                         cache_misses <= cache_misses + 32'd1;
        end
      end

      if (ENABLE_DCACHE) begin
        if (MemStall) begin
          // Ciclo 1 de MemStall: se aloca en dcache el lw que sufrio miss
          valid[alloc_idx]      <= 1'b1;
          cache_tag[alloc_idx]  <= stall_serve_v1 ? tag1 : tag2;
          cache_data[alloc_idx] <= ReadData_dmem;
          if (!has_free_line)
            fifo_ptr <= fifo_ptr + 3'd1;
        end else begin
          // Ciclo normal (MemStall == 0): actualizacion/alocacion de Via 1 y Via 2
          // 1. Via 1
          if (MemWriteM) begin
            if (hit1) begin
              cache_data[hit1_idx] <= WriteDataM;
            end else begin
              valid[alloc_idx]      <= 1'b1;
              cache_tag[alloc_idx]  <= tag1;
              cache_data[alloc_idx] <= WriteDataM;
              if (!has_free_line)
                fifo_ptr <= fifo_ptr + 3'd1;
            end
          end else if (MemReadM && !hit1) begin
            valid[alloc_idx]      <= 1'b1;
            cache_tag[alloc_idx]  <= tag1;
            cache_data[alloc_idx] <= ReadData_dmem;
            if (!has_free_line)
              fifo_ptr <= fifo_ptr + 3'd1;
          end

          // 2. Via 2 (si ambas escriben la misma linea, prevalece Via 2 por ir despues)
          if (MemWriteM2) begin
            if (hit2) begin
              cache_data[hit2_idx] <= WriteDataM2;
            end else begin
              valid[alloc_idx]      <= 1'b1;
              cache_tag[alloc_idx]  <= tag2;
              cache_data[alloc_idx] <= WriteDataM2;
              if (!has_free_line)
                fifo_ptr <= fifo_ptr + 3'd1;
            end
          end else if (MemReadM2 && !hit2 && !st_to_ld_bypass && !both_miss_same_lw) begin
            valid[alloc_idx]      <= 1'b1;
            cache_tag[alloc_idx]  <= tag2;
            cache_data[alloc_idx] <= ReadData_dmem;
            if (!has_free_line)
              fifo_ptr <= fifo_ptr + 3'd1;
          end
        end
      end
    end
  end

endmodule
