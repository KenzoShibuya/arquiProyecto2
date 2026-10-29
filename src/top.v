module top #(
    parameter MEM_FILE = "riscvtest.mem"   // programa a cargar en la memoria de instrucciones
)(
    input         clk, reset,
    output [31:0] WriteData, DataAdr,
    output        MemWrite
);

  wire [31:0] PC, Instr, Instr2, ReadData;

  riscvpipe rvpipe (
    .clk(clk), .reset(reset),
    .PC(PC), .Instr(Instr), .Instr2(Instr2),
    .MemWrite(MemWrite), .DataAdr(DataAdr),
    .WriteData(WriteData), .ReadData(ReadData)
  );

  imem #(.MEM_FILE(MEM_FILE)) imem (
    .a(PC), .rd0(Instr), .rd1(Instr2)
  );

  dmem dmem (
    .clk(clk), .we(MemWrite), .a(DataAdr), .wd(WriteData), .rd(ReadData)
  );
endmodule