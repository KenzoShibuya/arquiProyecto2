module riscvpipe(
    input         clk,
    input         reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
);

  // Control signals from controller (Decode stage)
  wire [1:0] ResultSrcD;
  wire       MemWriteD;
  wire       BranchD;
  wire       ALUSrcD;
  wire       RegWriteD;
  wire       JumpD;
  wire [1:0] ImmSrcD;
  wire [2:0] ALUControlD;

  // Instruction from datapath (Decode stage)
  wire [31:0] InstrD;

  // Controller in Decode stage
  controller c(
    .op(InstrD[6:0]),
    .funct3(InstrD[14:12]),
    .funct7b5(InstrD[30]),
    .ResultSrc(ResultSrcD),
    .MemWrite(MemWriteD),
    .Branch(BranchD),
    .ALUSrc(ALUSrcD),
    .RegWrite(RegWriteD),
    .Jump(JumpD),
    .ImmSrc(ImmSrcD),
    .ALUControl(ALUControlD)
  );

  // Datapath encompassing all 5 pipeline stages and 4 pipeline registers
  datapath dp(
    .clk(clk),
    .reset(reset),
    .ResultSrcD(ResultSrcD),
    .ALUSrcD(ALUSrcD),
    .RegWriteD(RegWriteD),
    .MemWriteD(MemWriteD),
    .JumpD(JumpD),
    .BranchD(BranchD),
    .ImmSrcD(ImmSrcD),
    .ALUControlD(ALUControlD),
    .InstrD(InstrD),
    .PCF(PC),
    .InstrF(Instr),
    .MemWriteM(MemWrite),
    .ALUResultM(DataAdr),
    .WriteDataM(WriteData),
    .ReadDataM(ReadData)
  );

endmodule
