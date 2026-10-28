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
    // Hazard unit inputs
    input  [1:0]  ForwardAE,
    input  [1:0]  ForwardBE,
    input         StallF,
    input         StallD,
    input         FlushD,
    input         FlushE,
    // Outputs to controller & hazard unit
    output [31:0] InstrD,
    output [4:0]  Rs1D,
    output [4:0]  Rs2D,
    output [4:0]  Rs1E,
    output [4:0]  Rs2E,
    output [4:0]  RdE,
    output        PCSrcE,
    output        ResultSrcEb0,
    output [4:0]  RdM,
    output        RegWriteM,
    output [4:0]  RdW,
    output        RegWriteW,
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
  wire [4:0]  RdD;

  // EX stage
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [31:0] SrcAE, SrcBE, WriteDataE;
  wire [31:0] ALUResultE, PCTargetE;
  wire        ZeroE;

  // MEM stage
  wire [1:0]  ResultSrcM;
  wire [31:0] PCPlus4M;

  // WB stage
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
  wire [31:0] ResultW;


  // 1. Fetch (IF)

  mux2 #(WIDTH) pcmux(
    .d0(PCPlus4F),
    .d1(PCTargetE),
    .s(PCSrcE),
    .y(PCNextF)
  );

  flopenr #(WIDTH) pcreg(
    .clk(clk),
    .reset(reset),
    .en(~StallF),
    .d(PCNextF),
    .q(PCF)
  );

  adder pcadd4(
    .a(PCF),
    .b(32'd4),
    .y(PCPlus4F)
  );

  // Pipeline Register IF / ID 
  flopenrc #(32) pcd_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushD),
    .en(~StallD),
    .d(PCF),
    .q(PCD)
  );

  flopenrc #(32) pcplus4d_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushD),
    .en(~StallD),
    .d(PCPlus4F),
    .q(PCPlus4D)
  );

  flopenrc #(32) instrd_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushD),
    .en(~StallD),
    .d(InstrF),
    .q(InstrD)
  );

  // 2. Decode (ID)

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

  // Pipeline Register ID / EX 

  // Control signals
  floprc #(1) regwrite_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(RegWriteD),
    .q(RegWriteE)
  );

  floprc #(2) resultsrc_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(ResultSrcD),
    .q(ResultSrcE)
  );

  floprc #(1) memwrite_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(MemWriteD),
    .q(MemWriteE)
  );

  floprc #(1) jump_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(JumpD),
    .q(JumpE)
  );

  floprc #(1) branch_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(BranchD),
    .q(BranchE)
  );

  floprc #(3) alucontrol_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(ALUControlD),
    .q(ALUControlE)
  );

  floprc #(1) alusrc_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(ALUSrcD),
    .q(ALUSrcE)
  );

  // Data signals
  floprc #(32) rd1_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(RD1D),
    .q(RD1E)
  );

  floprc #(32) rd2_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(RD2D),
    .q(RD2E)
  );

  floprc #(32) pce_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(PCD),
    .q(PCE)
  );

  floprc #(5) rs1e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(Rs1D),
    .q(Rs1E)
  );

  floprc #(5) rs2e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(Rs2D),
    .q(Rs2E)
  );

  floprc #(5) rde_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(RdD),
    .q(RdE)
  );

  floprc #(32) imm_e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(ImmExtD),
    .q(ImmExtE)
  );

  floprc #(32) pcplus4e_reg(
    .clk(clk),
    .reset(reset),
    .clear(FlushE),
    .d(PCPlus4D),
    .q(PCPlus4E)
  );

  // 3. Execute (EX)

  // Forwarding mux for Operand A
  mux3 #(WIDTH) forwarda_mux(
    .d0(RD1E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardAE),
    .y(SrcAE)
  );

  // Forwarding mux for Operand B / WriteDataE
  mux3 #(WIDTH) forwardb_mux(
    .d0(RD2E),
    .d1(ResultW),
    .d2(ALUResultM),
    .s(ForwardBE),
    .y(WriteDataE)
  );

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

  assign PCSrcE       = (BranchE & ZeroE) | JumpE;
  assign ResultSrcEb0 = ResultSrcE[0];

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
    .d(WriteDataE),
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

  // 4. Memory (MEM)

  // ALUResultM, WriteDataM and MemWriteM go directly to external data memory (dmem).
  // ReadDataM is received from external data memory (dmem).

  // --- Pipeline Register MEM / WB ---
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


  // 5. Writeback (WB)

  mux3 #(WIDTH) resultmux(
    .d0(ALUResultW),
    .d1(ReadDataW),
    .d2(PCPlus4W),
    .s(ResultSrcW),
    .y(ResultW)
  );

endmodule
