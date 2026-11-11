`timescale 1ns/1ps

// ============================================================================
// Testbench para Entrega Final (EF):
//   1. tb_prog10         : Simula prog10_cache_eval.mem en Configuracion C
//                          (Dual-Issue + Cache L1 Fully Associative de 8 lineas)
//                          exponiendo todas las senales de cache para waveforms.
//   2. tb_ef_compare_all : Instancia simultaneamente las 3 configuraciones:
//                          - Config A: Single-Issue (E1)       [SINGLE_ISSUE=1, ENABLE_DCACHE=0]
//                          - Config B: Dual-Issue Base (E2)    [SINGLE_ISSUE=0, ENABLE_DCACHE=0]
//                          - Config C: Dual-Issue + L1 (EF)    [SINGLE_ISSUE=0, ENABLE_DCACHE=1]
//                          Verifica equivalencia funcional 100% en registros y
//                          memoria, e imprime la tabla comparativa de desempeno.
// ============================================================================

module tb_ef_core #(
    parameter MEM_FILE      = "prog10_cache_eval.mem",
    parameter ENABLE_DCACHE = 1,
    parameter SINGLE_ISSUE  = 0,
    parameter [31:0] DONE_PC = 32'h000000e8,
    parameter [31:0] FIRST0  = 32'h04000a13,
    parameter [31:0] FIRST1  = 32'h00300913
);
    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    top #(
        .MEM_FILE(MEM_FILE),
        .ENABLE_DCACHE(ENABLE_DCACHE),
        .SINGLE_ISSUE(SINGLE_ISSUE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Senales de Fetch y Decode
    wire [31:0] PCF     = dut.PC;
    wire [31:0] InstrF  = dut.Instr;
    wire [31:0] InstrF2 = dut.Instr2;
    wire [31:0] InstrD  = dut.rvpipe.InstrD;
    wire [31:0] InstrD2 = dut.rvpipe.InstrD2;
    wire [31:0] PCD     = dut.rvpipe.dp.PCD;
    wire [31:0] PCD2    = dut.rvpipe.dp.PCD2;

    // Issue Unit y Conflictos
    wire IssueSlot2D     = dut.rvpipe.IssueSlot2D;
    wire PCInc8F         = dut.rvpipe.PCInc8F;
    wire raw_conflict    = dut.rvpipe.iu.raw_hazard;
    wire mem_conflict    = dut.rvpipe.iu.mem_conflict;
    wire ctrl_conflict   = dut.rvpipe.iu.ctrl_conflict;
    wire lw_hazard_slot2 = dut.rvpipe.iu.lw_hazard_slot2;

    // Hazard Unit y Stalls/Flushes
    wire StallF   = dut.rvpipe.StallF;
    wire StallD   = dut.rvpipe.StallD;
    wire FlushD   = dut.rvpipe.FlushD;
    wire FlushE   = dut.rvpipe.FlushE;
    wire FlushM2  = dut.rvpipe.FlushM2;
    wire MemStall = dut.rvpipe.MemStall;

    // Etapa EX
    wire [31:0] PCE        = dut.rvpipe.dp.PCE;
    wire [31:0] PCE2       = dut.rvpipe.dp.PCE2;
    wire [31:0] ALUResultE = dut.rvpipe.dp.ALUResultE;
    wire [31:0] ALUResultE2= dut.rvpipe.dp.ALUResultE2;
    wire PCSrcE            = dut.rvpipe.PCSrcE;
    wire PCSrcE1           = dut.rvpipe.PCSrcE1;
    wire PCSrcE2           = dut.rvpipe.dp.PCSrcE2;

    // Etapa MEM y Cache L1 (dcache)
    wire        MemReadM        = dut.rvpipe.MemReadM;
    wire        MemWriteM       = dut.rvpipe.MemWriteM;
    wire [31:0] ALUResultM      = dut.rvpipe.ALUResultM;
    wire [31:0] WriteDataM      = dut.rvpipe.WriteDataM;
    wire [31:0] ReadDataM_cache = dut.rvpipe.ReadDataM_cache;

    wire        MemReadM2        = dut.rvpipe.MemReadM2;
    wire        MemWriteM2       = dut.rvpipe.MemWriteM2;
    wire [31:0] ALUResultM2      = dut.rvpipe.ALUResultM2;
    wire [31:0] WriteDataM2      = dut.rvpipe.WriteDataM2;
    wire [31:0] ReadDataM2_cache = dut.rvpipe.ReadDataM2_cache;

    wire        hit1            = dut.rvpipe.dc.hit1;
    wire        hit2            = dut.rvpipe.dc.hit2;
    wire        st_to_ld_bypass = dut.rvpipe.dc.st_to_ld_bypass;
    wire        need_dmem1      = dut.rvpipe.dc.need_dmem1;
    wire        need_dmem2      = dut.rvpipe.dc.need_dmem2;
    wire [2:0]  fifo_ptr        = dut.rvpipe.dc.fifo_ptr;
    wire [2:0]  alloc_idx       = dut.rvpipe.dc.alloc_idx;

    wire [31:0] cache_accesses  = dut.rvpipe.dc.cache_accesses;
    wire [31:0] cache_hits      = dut.rvpipe.dc.cache_hits;
    wire [31:0] cache_misses    = dut.rvpipe.dc.cache_misses;
    wire [31:0] dual_mem_pairs  = dut.rvpipe.dc.dual_mem_pairs;

    // Lineas de la Cache L1 (0..7) para inspeccion en waveform
    wire [31:0] cache_data0 = dut.rvpipe.dc.cache_data[0];
    wire [31:0] cache_data1 = dut.rvpipe.dc.cache_data[1];
    wire [31:0] cache_data2 = dut.rvpipe.dc.cache_data[2];
    wire [31:0] cache_data3 = dut.rvpipe.dc.cache_data[3];
    wire [31:0] cache_data4 = dut.rvpipe.dc.cache_data[4];
    wire [31:0] cache_data5 = dut.rvpipe.dc.cache_data[5];
    wire [31:0] cache_data6 = dut.rvpipe.dc.cache_data[6];
    wire [31:0] cache_data7 = dut.rvpipe.dc.cache_data[7];

    // Etapa WB
    wire        RegWriteW  = dut.rvpipe.RegWriteW;
    wire        RegWriteW2 = dut.rvpipe.RegWriteW2;
    wire [4:0]  RdW        = dut.rvpipe.RdW;
    wire [4:0]  RdW2       = dut.rvpipe.RdW2;
    wire [31:0] ResultW    = dut.rvpipe.dp.ResultW;
    wire [31:0] ResultW2   = dut.rvpipe.dp.ResultW2;

    // Memoria de datos M[64..112]
    wire [31:0] mem64  = dut.dmem.RAM[16];
    wire [31:0] mem68  = dut.dmem.RAM[17];
    wire [31:0] mem72  = dut.dmem.RAM[18];
    wire [31:0] mem76  = dut.dmem.RAM[19];
    wire [31:0] mem80  = dut.dmem.RAM[20];
    wire [31:0] mem84  = dut.dmem.RAM[21];
    wire [31:0] mem88  = dut.dmem.RAM[22];
    wire [31:0] mem92  = dut.dmem.RAM[23];
    wire [31:0] mem96  = dut.dmem.RAM[24];
    wire [31:0] mem100 = dut.dmem.RAM[25];
    wire [31:0] mem104 = dut.dmem.RAM[26];
    wire [31:0] mem108 = dut.dmem.RAM[27];
    wire [31:0] mem112 = dut.dmem.RAM[28];

    // Registros clave
    wire [31:0] x1  = dut.rvpipe.dp.rf.rf[1];
    wire [31:0] x3  = dut.rvpipe.dp.rf.rf[3];
    wire [31:0] x5  = dut.rvpipe.dp.rf.rf[5];
    wire [31:0] x7  = dut.rvpipe.dp.rf.rf[7];
    wire [31:0] x11 = dut.rvpipe.dp.rf.rf[11];
    wire [31:0] x13 = dut.rvpipe.dp.rf.rf[13];
    wire [31:0] x14 = dut.rvpipe.dp.rf.rf[14];
    wire [31:0] x15 = dut.rvpipe.dp.rf.rf[15];
    wire [31:0] x21 = dut.rvpipe.dp.rf.rf[21];
    wire [31:0] x22 = dut.rvpipe.dp.rf.rf[22];
    wire [31:0] x23 = dut.rvpipe.dp.rf.rf[23];

    integer ciclos, dual_issue, single_issue;
    integer raw_conflicts, mem_conflicts, ctrl_conflicts;
    integer stalls, mem_stalls, flushes;
    integer done_seen, errores, finalizado;

    initial begin
        reset = 1;
        ciclos = 0;
        dual_issue = 0;
        single_issue = 0;
        raw_conflicts = 0;
        mem_conflicts = 0;
        ctrl_conflicts = 0;
        stalls = 0;
        mem_stalls = 0;
        flushes = 0;
        done_seen = 0;
        errores = 0;
        finalizado = 0;

        #1;
        if ((dut.imem.RAM[0] !== FIRST0) || (dut.imem.RAM[1] !== FIRST1)) begin
            errores = errores + 1;
            finalizado = 1;
        end
        #21;
        reset = 0;
    end

    always @(posedge clk) begin
        if (!reset && !finalizado) begin
            ciclos = ciclos + 1;
            if (!MemStall && !FlushE && !StallD && IssueSlot2D && (InstrD != 0) && (InstrD2 != 0))
                dual_issue = dual_issue + 1;
            if (!MemStall && !FlushE && !StallD && !IssueSlot2D && (InstrD != 0))
                single_issue = single_issue + 1;
            if (!MemStall && !StallD && (InstrD != 0) && (InstrD2 != 0)) begin
                if (raw_conflict)  raw_conflicts  = raw_conflicts  + 1;
                if (mem_conflict)  mem_conflicts  = mem_conflicts  + 1;
                if (ctrl_conflict) ctrl_conflicts = ctrl_conflicts + 1;
            end
            if (StallF)   stalls     = stalls     + 1;
            if (MemStall) mem_stalls = mem_stalls + 1;
            if (FlushD)   flushes    = flushes    + 1;

            if (!MemStall && ((PCSrcE1 && PCE == DONE_PC) || (PCSrcE2 && PCE2 == DONE_PC)))
                done_seen = done_seen + 1;
        end
    end

    always @(negedge clk) begin
        if (!reset && !finalizado) begin
            if (done_seen >= 3) begin
                if (mem64  !== 32'd16)  errores = errores + 1;
                if (mem68  !== 32'd32)  errores = errores + 1;
                if (mem72  !== 32'd48)  errores = errores + 1;
                if (mem76  !== 32'd64)  errores = errores + 1;
                if (mem80  !== 32'd2)   errores = errores + 1;
                if (mem84  !== 32'd4)   errores = errores + 1;
                if (mem88  !== 32'd6)   errores = errores + 1;
                if (mem92  !== 32'd8)   errores = errores + 1;
                if (mem96  !== 32'd160) errores = errores + 1;
                if (mem100 !== 32'd50)  errores = errores + 1;
                if (mem104 !== 32'd192) errores = errores + 1;
                if (mem108 !== 32'd98)  errores = errores + 1;
                if (mem112 !== 32'd100) errores = errores + 1;
                if (x11    !== 32'd160) errores = errores + 1;
                if (x13    !== 32'd160) errores = errores + 1;
                if (x14    !== 32'd32)  errores = errores + 1;
                if (x15    !== 32'd48)  errores = errores + 1;
                if (x21    !== 32'd192) errores = errores + 1;
                if (x22    !== 32'd98)  errores = errores + 1;
                if (x23    !== 32'd100) errores = errores + 1;
                finalizado = 1;
            end else if (ciclos > 500) begin
                errores = errores + 1;
                finalizado = 1;
            end
        end
    end
endmodule

// Top-level para visualizar waveforms de P10 con Cache L1 activa
module tb_prog10;
    tb_ef_core #(
        .MEM_FILE("prog10_cache_eval.mem"),
        .ENABLE_DCACHE(1),
        .SINGLE_ISSUE(0)
    ) u();
endmodule

// Top-level comparativo de las 3 arquitecturas (A: E1, B: E2, C: EF)
module tb_ef_compare_all;
    tb_ef_core #(.MEM_FILE("prog10_cache_eval.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(1)) cfg_A_single();
    tb_ef_core #(.MEM_FILE("prog10_cache_eval.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(0)) cfg_B_dual_base();
    tb_ef_core #(.MEM_FILE("prog10_cache_eval.mem"), .ENABLE_DCACHE(1), .SINGLE_ISSUE(0)) cfg_C_dual_cache();

    integer idx, diff_errors;
    initial begin
        diff_errors = 0;
        wait(cfg_A_single.finalizado && cfg_B_dual_base.finalizado && cfg_C_dual_cache.finalizado);
        #1;
        for (idx = 0; idx < 64; idx = idx + 1) begin
            if (cfg_A_single.dut.dmem.RAM[idx] !== cfg_B_dual_base.dut.dmem.RAM[idx] ||
                cfg_B_dual_base.dut.dmem.RAM[idx] !== cfg_C_dual_cache.dut.dmem.RAM[idx])
                diff_errors = diff_errors + 1;
        end
        for (idx = 1; idx < 32; idx = idx + 1) begin
            if (cfg_A_single.dut.rvpipe.dp.rf.rf[idx] !== cfg_B_dual_base.dut.rvpipe.dp.rf.rf[idx] ||
                cfg_B_dual_base.dut.rvpipe.dp.rf.rf[idx] !== cfg_C_dual_cache.dut.rvpipe.dp.rf.rf[idx])
                diff_errors = diff_errors + 1;
        end
        $display("====================================================================");
        $display(" COMPARACION ENTREGA FINAL (EF) - prog10_cache_eval");
        $display("====================================================================");
        $display(" Config A (Single-Issue E1)    : %0d ciclos (utiles: %0d), errores=%0d",
                 cfg_A_single.ciclos, cfg_A_single.ciclos - 5, cfg_A_single.errores);
        $display(" Config B (Dual-Issue Base E2) : %0d ciclos (utiles: %0d), mem_conflicts=%0d, errores=%0d",
                 cfg_B_dual_base.ciclos, cfg_B_dual_base.ciclos - 5, cfg_B_dual_base.mem_conflicts, cfg_B_dual_base.errores);
        $display(" Config C (Dual-Issue + L1 EF) : %0d ciclos (utiles: %0d), mem_conflicts=%0d, hits=%0d/%0d, dual_mem=%0d, errores=%0d",
                 cfg_C_dual_cache.ciclos, cfg_C_dual_cache.ciclos - 5, cfg_C_dual_cache.mem_conflicts,
                 cfg_C_dual_cache.cache_hits, cfg_C_dual_cache.cache_accesses,
                 cfg_C_dual_cache.dual_mem_pairs, cfg_C_dual_cache.errores);
        $display(" Equivalencia funcional A == B == C : diff_errors = %0d", diff_errors);
        $display("====================================================================");
        $finish;
    end
endmodule
