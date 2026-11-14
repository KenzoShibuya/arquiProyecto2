module dmem(input         clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[0:511];
  integer i;

  initial begin
    for (i = 0; i < 512; i = i + 1)
      RAM[i] = 32'h00000000;
  end

  assign rd = RAM[a[10:2]]; // word aligned (soporta hasta byte 2044, incluye x1=1536)

  always @(posedge clk) begin
    if (we) RAM[a[10:2]] <= wd;
  end
endmodule