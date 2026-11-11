module top #(
    parameter MEM_FILE      = "riscvtest.mem",
    parameter ENABLE_DCACHE = 1,
    parameter SINGLE_ISSUE  = 0
)(
    input         clk, reset,
    output [31:0] WriteData, DataAdr,
    output        MemWrite
);

  wire [31:0] PC, Instr, Instr2, ReadData;

  riscvpipe #(
    .ENABLE_DCACHE(ENABLE_DCACHE),
    .SINGLE_ISSUE(SINGLE_ISSUE)
  ) rvpipe (
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