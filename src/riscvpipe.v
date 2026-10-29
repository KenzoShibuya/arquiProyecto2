module riscvpipe(
    input         clk,
    input         reset,
    output [31:0] PC,
    input  [31:0] Instr,      // instruccion en PC     (1)
    input  [31:0] Instr2,     // instruccion en PC + 4 (2)
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
);

  // Control via 1 (Dec)
  wire [1:0] ResultSrcD, ImmSrcD;
  wire       MemWriteD, BranchD, ALUSrcD, RegWriteD, JumpD;
  wire [2:0] ALUControlD;
  // Control via 2 (Dec)
  wire [1:0] ResultSrcD2, ImmSrcD2;
  wire       MemWriteD2, BranchD2, ALUSrcD2, RegWriteD2, JumpD2;
  wire [2:0] ALUControlD2;

  wire [31:0] InstrD, InstrD2;

  // Hazard
  wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;
  wire       PCSrcE, ResultSrcEb0, RegWriteM, RegWriteW;
  wire [1:0] ForwardAE, ForwardBE;
  wire       StallF, StallD, FlushD, FlushE;

  // Issue Unit
  wire       IssueSlot2D, PCInc8F;

  // Dual Decode: un controlador por via
  controller c (
    .op(InstrD[6:0]), .funct3(InstrD[14:12]), .funct7b5(InstrD[30]),
    .ResultSrc(ResultSrcD), .MemWrite(MemWriteD), .Branch(BranchD),
    .ALUSrc(ALUSrcD), .RegWrite(RegWriteD), .Jump(JumpD),
    .ImmSrc(ImmSrcD), .ALUControl(ALUControlD)
  );

  controller c2 (
    .op(InstrD2[6:0]), .funct3(InstrD2[14:12]), .funct7b5(InstrD2[30]),
    .ResultSrc(ResultSrcD2), .MemWrite(MemWriteD2), .Branch(BranchD2),
    .ALUSrc(ALUSrcD2), .RegWrite(RegWriteD2), .Jump(JumpD2),
    .ImmSrc(ImmSrcD2), .ALUControl(ALUControlD2)
  );

  issue_unit iu (
    .InstrD(InstrD), .InstrD2(InstrD2),
    .IssueSlot2D(IssueSlot2D), .PCInc8F(PCInc8F)
  );

  hazard hu (
    .Rs1D(Rs1D), .Rs2D(Rs2D),
    .Rs1E(Rs1E), .Rs2E(Rs2E), .RdE(RdE),
    .PCSrcE(PCSrcE), .ResultSrcEb0(ResultSrcEb0),
    .RdM(RdM), .RegWriteM(RegWriteM),
    .RdW(RdW), .RegWriteW(RegWriteW),
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE)
  );

  datapath dp (
    .clk(clk), .reset(reset),
    // control via 1
    .ResultSrcD(ResultSrcD), .ALUSrcD(ALUSrcD), .RegWriteD(RegWriteD),
    .MemWriteD(MemWriteD), .JumpD(JumpD), .BranchD(BranchD),
    .ImmSrcD(ImmSrcD), .ALUControlD(ALUControlD),
    // control via 2
    .ResultSrcD2(ResultSrcD2), .ALUSrcD2(ALUSrcD2), .RegWriteD2(RegWriteD2),
    .MemWriteD2(MemWriteD2), .JumpD2(JumpD2), .BranchD2(BranchD2),
    .ImmSrcD2(ImmSrcD2), .ALUControlD2(ALUControlD2),
    // issue
    .IssueSlot2D(IssueSlot2D), .PCInc8F(PCInc8F),
    // hazard
    .ForwardAE(ForwardAE), .ForwardBE(ForwardBE),
    .StallF(StallF), .StallD(StallD), .FlushD(FlushD), .FlushE(FlushE),
    // salidas
    .InstrD(InstrD), .InstrD2(InstrD2),
    .Rs1D(Rs1D), .Rs2D(Rs2D), .Rs1E(Rs1E), .Rs2E(Rs2E), .RdE(RdE),
    .PCSrcE(PCSrcE), .ResultSrcEb0(ResultSrcEb0),
    .RdM(RdM), .RegWriteM(RegWriteM), .RdW(RdW), .RegWriteW(RegWriteW),
    // memorias
    .PCF(PC), .InstrF(Instr), .InstrF2(Instr2),
    .MemWriteM(MemWrite), .ALUResultM(DataAdr), .WriteDataM(WriteData),
    .ReadDataM(ReadData)
  );

endmodule