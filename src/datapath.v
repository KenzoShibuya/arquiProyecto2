module datapath(
    input         clk, reset,
    // Control inputs from controller (Decode stage)
    input  [1:0]  ResultSrcD,
    input         ALUSrcD,
    input         RegWriteD,
    input         MemWriteD,
    input         JumpD,
    input         BranchD,
    input  [1:0]  ImmSrcD,
    input  [2:0]  ALUControlD,
    // Instruction output to controller (Decode stage)
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

  // Signals Declaration

  // IF stage
  wire [31:0] PCNextF, PCPlus4F;

  // ID stage
  wire [31:0] PCD, PCPlus4D;
  wire [31:0] RD1D, RD2D, ImmExtD;

  // EX stage
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [4:0]  RdE;
  wire [31:0] SrcBE;
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


  // 1. Fetch (IF)

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

  // Pipeline Register IF / ID
  flopr #(32) pcd_reg(
    .clk(clk),
    .reset(reset),
    .d(PCF),
    .q(PCD)
  );

  flopr #(32) pcplus4d_reg(
    .clk(clk),
    .reset(reset),
    .d(PCPlus4F),
    .q(PCPlus4D)
  );

  flopr #(32) instrd_reg(
    .clk(clk),
    .reset(reset),
    .d(InstrF),
    .q(InstrD)
  );


  // 2. Decode (ID)

  regfile rf(
    .clk(clk),
    .we3(RegWriteW),
    .a1(InstrD[19:15]),
    .a2(InstrD[24:20]),
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

  // Pipeline Register ID / EX

  // Control signals
  flopr #(1) regwrite_e_reg(
    .clk(clk),
    .reset(reset),
    .d(RegWriteD),
    .q(RegWriteE)
  );

  flopr #(2) resultsrc_e_reg(
    .clk(clk),
    .reset(reset),
    .d(ResultSrcD),
    .q(ResultSrcE)
  );

  flopr #(1) memwrite_e_reg(
    .clk(clk),
    .reset(reset),
    .d(MemWriteD),
    .q(MemWriteE)
  );

  flopr #(1) jump_e_reg(
    .clk(clk),
    .reset(reset),
    .d(JumpD),
    .q(JumpE)
  );

  flopr #(1) branch_e_reg(
    .clk(clk),
    .reset(reset),
    .d(BranchD),
    .q(BranchE)
  );

  flopr #(3) alucontrol_e_reg(
    .clk(clk),
    .reset(reset),
    .d(ALUControlD),
    .q(ALUControlE)
  );

  flopr #(1) alusrc_e_reg(
    .clk(clk),
    .reset(reset),
    .d(ALUSrcD),
    .q(ALUSrcE)
  );

  // Data signals
  flopr #(32) rd1_e_reg(
    .clk(clk),
    .reset(reset),
    .d(RD1D),
    .q(RD1E)
  );

  flopr #(32) rd2_e_reg(
    .clk(clk),
    .reset(reset),
    .d(RD2D),
    .q(RD2E)
  );

  flopr #(32) pce_reg(
    .clk(clk),
    .reset(reset),
    .d(PCD),
    .q(PCE)
  );

  flopr #(5) rde_reg(
    .clk(clk),
    .reset(reset),
    .d(InstrD[11:7]),
    .q(RdE)
  );

  flopr #(32) imm_e_reg(
    .clk(clk),
    .reset(reset),
    .d(ImmExtD),
    .q(ImmExtE)
  );

  flopr #(32) pcplus4e_reg(
    .clk(clk),
    .reset(reset),
    .d(PCPlus4D),
    .q(PCPlus4E)
  );

  // 3. Execute (EX)

  mux2 #(WIDTH) srcbmux(
    .d0(RD2E),
    .d1(ImmExtE),
    .s(ALUSrcE),
    .y(SrcBE)
  );

  alu alu_unit(
    .a(RD1E),
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

  // Pipeline Register EX / MEM 

  // Control signals
  flopr #(1) regwrite_m_reg(
    .clk(clk),
    .reset(reset),
    .d(RegWriteE),
    .q(RegWriteM)
  );

  flopr #(2) resultsrc_m_reg(
    .clk(clk),
    .reset(reset),
    .d(ResultSrcE),
    .q(ResultSrcM)
  );

  flopr #(1) memwrite_m_reg(
    .clk(clk),
    .reset(reset),
    .d(MemWriteE),
    .q(MemWriteM)
  );

  // Data signals
  flopr #(32) aluresult_m_reg(
    .clk(clk),
    .reset(reset),
    .d(ALUResultE),
    .q(ALUResultM)
  );

  flopr #(32) writedata_m_reg(
    .clk(clk),
    .reset(reset),
    .d(RD2E),
    .q(WriteDataM)
  );

  flopr #(5) rdm_reg(
    .clk(clk),
    .reset(reset),
    .d(RdE),
    .q(RdM)
  );

  flopr #(32) pcplus4m_reg(
    .clk(clk),
    .reset(reset),
    .d(PCPlus4E),
    .q(PCPlus4M)
  );

  // 4. Memory Stage (MEM)

  // ALUResultM, WriteDataM and MemWriteM go directly to external data memory (dmem).
  // ReadDataM is received from external data memory (dmem).

  // Pipeline Register MEM / WB 

  // Control signals
  flopr #(1) regwrite_w_reg(
    .clk(clk),
    .reset(reset),
    .d(RegWriteM),
    .q(RegWriteW)
  );

  flopr #(2) resultsrc_w_reg(
    .clk(clk),
    .reset(reset),
    .d(ResultSrcM),
    .q(ResultSrcW)
  );

  // Data signals
  flopr #(32) aluresult_w_reg(
    .clk(clk),
    .reset(reset),
    .d(ALUResultM),
    .q(ALUResultW)
  );

  flopr #(32) readdata_w_reg(
    .clk(clk),
    .reset(reset),
    .d(ReadDataM),
    .q(ReadDataW)
  );

  flopr #(5) rdw_reg(
    .clk(clk),
    .reset(reset),
    .d(RdM),
    .q(RdW)
  );

  flopr #(32) pcplus4w_reg(
    .clk(clk),
    .reset(reset),
    .d(PCPlus4M),
    .q(PCPlus4W)
  );

  // 5. Writeback Stage (WB)

  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );

endmodule
