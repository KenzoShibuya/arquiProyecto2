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

  // Hazard unit signals
  wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;
  wire       PCSrcE, ResultSrcEb0, RegWriteM, RegWriteW;
  wire [1:0] ForwardAE, ForwardBE;
  wire       StallF, StallD, FlushD, FlushE;

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

  // Hazard Unit (Harris & Harris)
  hazard hu(
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .PCSrcE(PCSrcE),
    .ResultSrcEb0(ResultSrcEb0),
    .RdM(RdM),
    .RegWriteM(RegWriteM),
    .RdW(RdW),
    .RegWriteW(RegWriteW),
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE)
  );

  // Datapath encompassing all 5 pipeline stages
  datapath dp(
    .clk(clk),
    .reset(reset),
    // Control inputs
    .ResultSrcD(ResultSrcD),
    .ALUSrcD(ALUSrcD),
    .RegWriteD(RegWriteD),
    .MemWriteD(MemWriteD),
    .JumpD(JumpD),
    .BranchD(BranchD),
    .ImmSrcD(ImmSrcD),
    .ALUControlD(ALUControlD),
    // Hazard inputs
    .ForwardAE(ForwardAE),
    .ForwardBE(ForwardBE),
    .StallF(StallF),
    .StallD(StallD),
    .FlushD(FlushD),
    .FlushE(FlushE),
    // Outputs to controller & hazard unit
    .InstrD(InstrD),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .PCSrcE(PCSrcE),
    .ResultSrcEb0(ResultSrcEb0),
    .RdM(RdM),
    .RegWriteM(RegWriteM),
    .RdW(RdW),
    .RegWriteW(RegWriteW),
    // Memory interface
    .PCF(PC),
    .InstrF(Instr),
    .MemWriteM(MemWrite),
    .ALUResultM(DataAdr),
    .WriteDataM(WriteData),
    .ReadDataM(ReadData)
  );

endmodule
