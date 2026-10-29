// Banco de registros de 4 lecturas y 2 escrituras
//   Lecturas: a1/a2 -> via 1,  a3/a4 -> via 2 (combinacionales)
//   Escrituras (negedge): puerto 0 -> via 1, puerto 1 -> via 2
//   Si ambas vias escriben el mismo registro, gana la via 2 (instruccion mas nueva).
module regfile(
    input         clk,
    input  [4:0]  a1, a2, a3, a4,
    output [31:0] rd1, rd2, rd3, rd4,
    input         we0,
    input  [4:0]  wa0,
    input  [31:0] wd0,
    input         we1,
    input  [4:0]  wa1,
    input  [31:0] wd1
);
  reg [31:0] rf[31:0];

  always @(negedge clk) begin
    if (we0 & (wa0 != 5'b0)) rf[wa0] <= wd0;
    if (we1 & (wa1 != 5'b0)) rf[wa1] <= wd1;   // al ir despues, tiene prioridad
  end

  assign rd1 = (a1 != 5'b0) ? rf[a1] : 32'b0;
  assign rd2 = (a2 != 5'b0) ? rf[a2] : 32'b0;
  assign rd3 = (a3 != 5'b0) ? rf[a3] : 32'b0;
  assign rd4 = (a4 != 5'b0) ? rf[a4] : 32'b0;
endmodule