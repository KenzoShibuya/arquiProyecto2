// Memoria de instrucciones de DOBLE LECTURA (Dual Fetch)
//   rd0 = instruccion en PC      (via 1, la mas antigua)
//   rd1 = instruccion en PC + 4  (via 2, la mas nuevecita)
module imem #(
    parameter MEM_FILE = "riscvtest.mem",
    parameter DEPTH    = 256            // palabras de 32 bits
)(
    input  [31:0] a,
    output [31:0] rd0,
    output [31:0] rd1
);
  reg [31:0] RAM[0:DEPTH-1];
  integer i;

  initial begin
    for (i = 0; i < DEPTH; i = i + 1) RAM[i] = 32'h00000000; // posiciones vacias = burbuja
    $readmemh(MEM_FILE, RAM);
  end

  wire [31:0] idx0 = a[31:2];
  wire [31:0] idx1 = a[31:2] + 1;

  assign rd0 = (idx0 < DEPTH) ? RAM[idx0] : 32'h00000000;
  assign rd1 = (idx1 < DEPTH) ? RAM[idx1] : 32'h00000000;
endmodule