module datapath(
    input         clk,
    input         reset,
    // Control inputs from controller (Decode stage)
    input  [1:0]  ResultSrcD,
    input         ALUSrcD,
    input         RegWriteD,
    input         MemWriteD,
    input         JumpD,
    input         BranchD,
    input  [1:0]  ImmSrcD,
    input  [2:0]  ALUControlD,
    // Instruction outputs to controller for decoding
    output [31:0] InstrD,
    // Memory interface
    output [31:0] PCF,
    input  [31:0] InstrF,
    output        MemWriteM,
    output [31:0] ALUResultM,
    output [31:0] WriteDataM,
    input  [31:0] ReadDataM
);

  localparam WIDTH = 32;

  // -------------------------------------------------------
  // Signals declaration
  // -------------------------------------------------------
  // IF stage
  wire [31:0] PCNextF, PCPlus4F;

  // ID stage
  wire [31:0] PCD, PCPlus4D;
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0]  Rs1D, Rs2D, RdD;

  // EX stage
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [4:0]  Rs1E, Rs2E, RdE;
  wire [31:0] SrcAE, SrcBE, WriteDataE;
  wire [31:0] ALUResultE, PCTargetE;
  wire        ZeroE, PCSrcE;

  // MEM stage
  wire        RegWriteM;
  wire [1:0]  ResultSrcM;
  wire [4:0]  RdM;
  wire [31:0] PCPlus4M;

  // WB stage
  wire        RegWriteW;
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
  wire [4:0]  RdW;
  wire [31:0] ResultW;

  // -------------------------------------------------------
  // 1. Fetch Stage (IF)
  // -------------------------------------------------------
  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNextF)
  );

  flopr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .d(PCNextF),
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF),
    .b(32'd4),
    .y(PCPlus4F)
  );

  // -------------------------------------------------------
  // Pipeline Register IF/ID
  // -------------------------------------------------------
  pipe_if_id reg_if_id(
    .clk(clk),
    .reset(reset),
    .clear(1'b0),
    .en(1'b1),
    .PCF(PCF),
    .PCPlus4F(PCPlus4F),
    .InstrF(InstrF),
    .PCD(PCD),
    .PCPlus4D(PCPlus4D),
    .InstrD(InstrD)
  );

  // -------------------------------------------------------
  // 2. Decode Stage (ID)
  // -------------------------------------------------------
  assign Rs1D = InstrD[19:15];
  assign Rs2D = InstrD[24:20];
  assign RdD  = InstrD[11:7];

  regfile rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1(Rs1D),
    .a2(Rs2D),
    .a3(RdW),
    .wd3(ResultW),
    .rd1(RD1D),
    .rd2(RD2D)
  );

  extend ext(
    .instr(InstrD[31:7]),
    .immsrc(ImmSrcD),
    .immext(ImmExtD)
  );

  // -------------------------------------------------------
  // Pipeline Register ID/EX
  // -------------------------------------------------------
  pipe_id_ex reg_id_ex(
    .clk(clk),
    .reset(reset),
    .clear(1'b0),
    .en(1'b1),
    // Control in
    .RegWriteD(RegWriteD),
    .ResultSrcD(ResultSrcD),
    .MemWriteD(MemWriteD),
    .JumpD(JumpD),
    .BranchD(BranchD),
    .ALUControlD(ALUControlD),
    .ALUSrcD(ALUSrcD),
    // Data in
    .RD1D(RD1D),
    .RD2D(RD2D),
    .PCD(PCD),
    .Rs1D(Rs1D),
    .Rs2D(Rs2D),
    .RdD(RdD),
    .ImmExtD(ImmExtD),
    .PCPlus4D(PCPlus4D),
    // Control out
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    .JumpE(JumpE),
    .BranchE(BranchE),
    .ALUControlE(ALUControlE),
    .ALUSrcE(ALUSrcE),
    // Data out
    .RD1E(RD1E),
    .RD2E(RD2E),
    .PCE(PCE),
    .Rs1E(Rs1E),
    .Rs2E(Rs2E),
    .RdE(RdE),
    .ImmExtE(ImmExtE),
    .PCPlus4E(PCPlus4E)
  );

  // -------------------------------------------------------
  // 3. Execute Stage (EX)
  // -------------------------------------------------------
  assign SrcAE      = RD1E;
  assign WriteDataE = RD2E;

  mux2 #(WIDTH) srcbmux(
    .d0(WriteDataE),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcBE)
  );

  alu alu_unit(
    .a(SrcAE),
    .b(SrcBE),
    .alucontrol(ALUControlE),
    .result(ALUResultE),
    .zero(ZeroE)
  );

  adder pcaddbranch(
    .a(PCE),
    .b(ImmExtE),
    .y(PCTargetE)
  );

  assign PCSrcE = (BranchE & ZeroE) | JumpE;

  // -------------------------------------------------------
  // Pipeline Register EX/MEM
  // -------------------------------------------------------
  pipe_ex_mem reg_ex_mem(
    .clk(clk),
    .reset(reset),
    .clear(1'b0),
    .en(1'b1),
    // Control in
    .RegWriteE(RegWriteE),
    .ResultSrcE(ResultSrcE),
    .MemWriteE(MemWriteE),
    // Data in
    .ALUResultE(ALUResultE),
    .WriteDataE(WriteDataE),
    .RdE(RdE),
    .PCPlus4E(PCPlus4E),
    // Control out
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    .MemWriteM(MemWriteM),
    // Data out
    .ALUResultM(ALUResultM),
    .WriteDataM(WriteDataM),
    .RdM(RdM),
    .PCPlus4M(PCPlus4M)
  );

  // -------------------------------------------------------
  // 4. Memory Stage (MEM)
  // -------------------------------------------------------
  // Outputs to data memory are ALUResultM, WriteDataM, MemWriteM
  // Input from data memory is ReadDataM

  // -------------------------------------------------------
  // Pipeline Register MEM/WB
  // -------------------------------------------------------
  pipe_mem_wb reg_mem_wb(
    .clk(clk),
    .reset(reset),
    .clear(1'b0),
    .en(1'b1),
    // Control in
    .RegWriteM(RegWriteM),
    .ResultSrcM(ResultSrcM),
    // Data in
    .ALUResultM(ALUResultM),
    .ReadDataM(ReadDataM),
    .RdM(RdM),
    .PCPlus4M(PCPlus4M),
    // Control out
    .RegWriteW(RegWriteW),
    .ResultSrcW(ResultSrcW),
    // Data out
    .ALUResultW(ALUResultW),
    .ReadDataW(ReadDataW),
    .RdW(RdW),
    .PCPlus4W(PCPlus4W)
  );

  // -------------------------------------------------------
  // 5. Writeback Stage (WB)
  // -------------------------------------------------------
  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );

endmodule
