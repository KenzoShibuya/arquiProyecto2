module datapath(
    input         clk, reset,
    // Control via 1
    input  [1:0]  ResultSrcD,
    input         ALUSrcD,
    input         RegWriteD,
    input         MemWriteD,
    input         JumpD,
    input         BranchD,
    input  [1:0]  ImmSrcD,
    input  [2:0]  ALUControlD,
    // Control via 2
    input  [1:0]  ResultSrcD2,
    input         ALUSrcD2,
    input         RegWriteD2,
    input         MemWriteD2,
    input         JumpD2,
    input         BranchD2,
    input  [1:0]  ImmSrcD2,
    input  [2:0]  ALUControlD2,
    // Issue Unit
    input         IssueSlot2D,
    input         PCInc8F,
    // Hazard Unit
    input  [1:0]  ForwardAE,
    input  [1:0]  ForwardBE,
    input         StallF,
    input         StallD,
    input         FlushD,
    input         FlushE,
    // Hacia controladores / hazard / issue
    output [31:0] InstrD,
    output [31:0] InstrD2,
    output [4:0]  Rs1D, Rs2D,
    output [4:0]  Rs1E, Rs2E, RdE,
    output        PCSrcE,
    output        ResultSrcEb0,
    output [4:0]  RdM,
    output        RegWriteM,
    output [4:0]  RdW,
    output        RegWriteW,
    //  Memoria de instrucciones (doble lectura)
    output [31:0] PCF,
    input  [31:0] InstrF,
    input  [31:0] InstrF2,
    // Memoria de datos (un solo puerto)
    output        MemWriteM,
    output [31:0] ALUResultM,
    output [31:0] WriteDataM,
    input  [31:0] ReadDataM
);

  // IF
  wire [31:0] PCNextF, PCSeqF, PCPlus4F, PCPlus8F;
  // ID via 1
  wire [31:0] PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
  wire [4:0]  RdD;
  // ID via 2
  wire [31:0] PCD2, PCPlus4D2, RD1D2, RD2D2, ImmExtD2;
  wire [4:0]  Rs1D2, Rs2D2, RdD2;
  wire        RegWriteI2, MemWriteI2, JumpI2, BranchI2;   // control via 2 ya filtrado por IssueSlot2D
  // EX via 1
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, ZeroE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE, PCTargetE;
  // EX via 2
  wire        RegWriteE2, MemWriteE2, JumpE2, BranchE2, ALUSrcE2, ZeroE2;
  wire [1:0]  ResultSrcE2;
  wire [2:0]  ALUControlE2;
  wire [31:0] RD1E2, RD2E2, PCE2, ImmExtE2, PCPlus4E2;
  wire [31:0] SrcAE2, SrcBE2, ALUResultE2;
  wire [4:0]  Rs1E2, Rs2E2, RdE2;
  // MEM via 1
  wire [1:0]  ResultSrcM;
  wire [31:0] PCPlus4M;
  // MEM via 2
  wire        RegWriteM2;
  wire [1:0]  ResultSrcM2;
  wire [31:0] ALUResultM2, PCPlus4M2;
  wire [4:0]  RdM2;
  // WB via 1
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
  // WB via 2
  wire        RegWriteW2;
  wire [1:0]  ResultSrcW2;
  wire [31:0] ALUResultW2, PCPlus4W2, ResultW2;
  wire [4:0]  RdW2;

  // FETCH
  adder pcadd4 (.a(PCF), .b(32'd4), .y(PCPlus4F));   // PC de la via 2
  adder pcadd8 (.a(PCF), .b(32'd8), .y(PCPlus8F));   // siguiente par

  // Avance secuencial: +4 (unica emitida) o +8 (par emitido)
  mux2 #(32) pcseqmux (.d0(PCPlus4F), .d1(PCPlus8F), .s(PCInc8F), .y(PCSeqF));
  // Redireccion por salto tomado (resuelto en EX de la via 1)
  mux2 #(32) pcmux    (.d0(PCSeqF), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));

  flopenr #(32) pcreg (.clk(clk), .reset(reset), .en(~StallF), .d(PCNextF), .q(PCF));

  // Registro IF/ID (par de instrucciones) 
  // via 1
  flopenrc #(32) instrd_reg   (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(InstrF),   .q(InstrD));
  flopenrc #(32) pcd_reg      (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(PCF),      .q(PCD));
  flopenrc #(32) pcplus4d_reg (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(PCPlus4F), .q(PCPlus4D));
  // via 2: su PC es PCF+4 y su PC+4 es PCF+8
  flopenrc #(32) instrd2_reg   (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(InstrF2),  .q(InstrD2));
  flopenrc #(32) pcd2_reg      (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(PCPlus4F), .q(PCD2));
  flopenrc #(32) pcplus4d2_reg (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(PCPlus8F), .q(PCPlus4D2));

  // DECODE
  assign Rs1D  = InstrD[19:15];
  assign Rs2D  = InstrD[24:20];
  assign RdD   = InstrD[11:7];

  assign Rs1D2 = InstrD2[19:15];
  assign Rs2D2 = InstrD2[24:20];
  assign RdD2  = InstrD2[11:7];

  // Register File 4R/2W
  regfile rf (
    .clk(clk),
    .a1(Rs1D),  .a2(Rs2D),  .a3(Rs1D2), .a4(Rs2D2),
    .rd1(RD1D), .rd2(RD2D), .rd3(RD1D2), .rd4(RD2D2),
    .we0(RegWriteW),  .wa0(RdW),  .wd0(ResultW),
    .we1(RegWriteW2), .wa1(RdW2), .wd1(ResultW2)
  );

  extend ext  (.instr(InstrD[31:7]),  .immsrc(ImmSrcD),  .immext(ImmExtD));
  extend ext2 (.instr(InstrD2[31:7]), .immsrc(ImmSrcD2), .immext(ImmExtD2));

  // La via 2 solo pasa a EX si la Issue Unit la emite; si no, entra una burbuja
  assign RegWriteI2 = RegWriteD2 & IssueSlot2D;
  assign MemWriteI2 = MemWriteD2 & IssueSlot2D;
  assign JumpI2     = JumpD2     & IssueSlot2D;
  assign BranchI2   = BranchD2   & IssueSlot2D;

  // Registro ID/EX via 1
  floprc #(1)  regwrite_e_reg   (.clk(clk), .reset(reset), .clear(FlushE), .d(RegWriteD),   .q(RegWriteE));
  floprc #(2)  resultsrc_e_reg  (.clk(clk), .reset(reset), .clear(FlushE), .d(ResultSrcD),  .q(ResultSrcE));
  floprc #(1)  memwrite_e_reg   (.clk(clk), .reset(reset), .clear(FlushE), .d(MemWriteD),   .q(MemWriteE));
  floprc #(1)  jump_e_reg       (.clk(clk), .reset(reset), .clear(FlushE), .d(JumpD),       .q(JumpE));
  floprc #(1)  branch_e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(BranchD),     .q(BranchE));
  floprc #(3)  alucontrol_e_reg (.clk(clk), .reset(reset), .clear(FlushE), .d(ALUControlD), .q(ALUControlE));
  floprc #(1)  alusrc_e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(ALUSrcD),     .q(ALUSrcE));
  floprc #(32) rd1_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(RD1D),        .q(RD1E));
  floprc #(32) rd2_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(RD2D),        .q(RD2E));
  floprc #(32) pce_reg          (.clk(clk), .reset(reset), .clear(FlushE), .d(PCD),         .q(PCE));
  floprc #(5)  rs1e_reg         (.clk(clk), .reset(reset), .clear(FlushE), .d(Rs1D),        .q(Rs1E));
  floprc #(5)  rs2e_reg         (.clk(clk), .reset(reset), .clear(FlushE), .d(Rs2D),        .q(Rs2E));
  floprc #(5)  rde_reg          (.clk(clk), .reset(reset), .clear(FlushE), .d(RdD),         .q(RdE));
  floprc #(32) imm_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(ImmExtD),     .q(ImmExtE));
  floprc #(32) pcplus4e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(PCPlus4D),    .q(PCPlus4E));

  // Registro ID/EX via 2
  floprc #(1)  regwrite_e2_reg   (.clk(clk), .reset(reset), .clear(FlushE), .d(RegWriteI2),   .q(RegWriteE2));
  floprc #(2)  resultsrc_e2_reg  (.clk(clk), .reset(reset), .clear(FlushE), .d(ResultSrcD2),  .q(ResultSrcE2));
  floprc #(1)  memwrite_e2_reg   (.clk(clk), .reset(reset), .clear(FlushE), .d(MemWriteI2),   .q(MemWriteE2));
  floprc #(1)  jump_e2_reg       (.clk(clk), .reset(reset), .clear(FlushE), .d(JumpI2),       .q(JumpE2));
  floprc #(1)  branch_e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(BranchI2),     .q(BranchE2));
  floprc #(3)  alucontrol_e2_reg (.clk(clk), .reset(reset), .clear(FlushE), .d(ALUControlD2), .q(ALUControlE2));
  floprc #(1)  alusrc_e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(ALUSrcD2),     .q(ALUSrcE2));
  floprc #(32) rd1_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(RD1D2),        .q(RD1E2));
  floprc #(32) rd2_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(RD2D2),        .q(RD2E2));
  floprc #(32) pce2_reg          (.clk(clk), .reset(reset), .clear(FlushE), .d(PCD2),         .q(PCE2));
  floprc #(5)  rs1e2_reg         (.clk(clk), .reset(reset), .clear(FlushE), .d(Rs1D2),        .q(Rs1E2));
  floprc #(5)  rs2e2_reg         (.clk(clk), .reset(reset), .clear(FlushE), .d(Rs2D2),        .q(Rs2E2));
  floprc #(5)  rde2_reg          (.clk(clk), .reset(reset), .clear(FlushE), .d(RdD2),         .q(RdE2));
  floprc #(32) imm_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .d(ImmExtD2),     .q(ImmExtE2));
  floprc #(32) pcplus4e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .d(PCPlus4D2),    .q(PCPlus4E2));

  // EXECUTE
  mux3 #(32) forwarda_mux (.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
  mux3 #(32) forwardb_mux (.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(WriteDataE));
  mux2 #(32) srcbmux      (.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));

  alu alu_unit (.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE));

  adder pcaddbranch (.a(PCE), .b(ImmExtE), .y(PCTargetE));

  assign PCSrcE       = (BranchE & ZeroE) | JumpE;   // unico recurso de resolucion de saltos
  assign ResultSrcEb0 = ResultSrcE[0];

  // via 2 (sin forwarding todavia)
  assign SrcAE2 = RD1E2;
  mux2 #(32) srcbmux2 (.d0(RD2E2), .d1(ImmExtE2), .s(ALUSrcE2), .y(SrcBE2));

  alu alu_unit2 (.a(SrcAE2), .b(SrcBE2), .alucontrol(ALUControlE2), .result(ALUResultE2), .zero(ZeroE2));

  // Registro EX/MEM via 1 
  flopr #(1)  regwrite_m_reg  (.clk(clk), .reset(reset), .d(RegWriteE),  .q(RegWriteM));
  flopr #(2)  resultsrc_m_reg (.clk(clk), .reset(reset), .d(ResultSrcE), .q(ResultSrcM));
  flopr #(1)  memwrite_m_reg  (.clk(clk), .reset(reset), .d(MemWriteE),  .q(MemWriteM));
  flopr #(32) aluresult_m_reg (.clk(clk), .reset(reset), .d(ALUResultE), .q(ALUResultM));
  flopr #(32) writedata_m_reg (.clk(clk), .reset(reset), .d(WriteDataE), .q(WriteDataM));
  flopr #(5)  rdm_reg         (.clk(clk), .reset(reset), .d(RdE),        .q(RdM));
  flopr #(32) pcplus4m_reg    (.clk(clk), .reset(reset), .d(PCPlus4E),   .q(PCPlus4M));

  // Registro EX/MEM via 2
  flopr #(1)  regwrite_m2_reg  (.clk(clk), .reset(reset), .d(RegWriteE2),  .q(RegWriteM2));
  flopr #(2)  resultsrc_m2_reg (.clk(clk), .reset(reset), .d(ResultSrcE2), .q(ResultSrcM2));
  flopr #(32) aluresult_m2_reg (.clk(clk), .reset(reset), .d(ALUResultE2), .q(ALUResultM2));
  flopr #(5)  rdm2_reg         (.clk(clk), .reset(reset), .d(RdE2),        .q(RdM2));
  flopr #(32) pcplus4m2_reg    (.clk(clk), .reset(reset), .d(PCPlus4E2),   .q(PCPlus4M2));

  // MEMORY 
  // Un solo puerto de memoria de datos: lo usa la via 1 (en E2 se asignara dinamicamente a la via que lleve el Load/Store)

  // Registro MEM/WB via 1
  flopr #(1)  regwrite_w_reg  (.clk(clk), .reset(reset), .d(RegWriteM),  .q(RegWriteW));
  flopr #(2)  resultsrc_w_reg (.clk(clk), .reset(reset), .d(ResultSrcM), .q(ResultSrcW));
  flopr #(32) aluresult_w_reg (.clk(clk), .reset(reset), .d(ALUResultM), .q(ALUResultW));
  flopr #(32) readdata_w_reg  (.clk(clk), .reset(reset), .d(ReadDataM),  .q(ReadDataW));
  flopr #(5)  rdw_reg         (.clk(clk), .reset(reset), .d(RdM),        .q(RdW));
  flopr #(32) pcplus4w_reg    (.clk(clk), .reset(reset), .d(PCPlus4M),   .q(PCPlus4W));

  // Registro MEM/WB via 2 
  flopr #(1)  regwrite_w2_reg  (.clk(clk), .reset(reset), .d(RegWriteM2),  .q(RegWriteW2));
  flopr #(2)  resultsrc_w2_reg (.clk(clk), .reset(reset), .d(ResultSrcM2), .q(ResultSrcW2));
  flopr #(32) aluresult_w2_reg (.clk(clk), .reset(reset), .d(ALUResultM2), .q(ALUResultW2));
  flopr #(5)  rdw2_reg         (.clk(clk), .reset(reset), .d(RdM2),        .q(RdW2));
  flopr #(32) pcplus4w2_reg    (.clk(clk), .reset(reset), .d(PCPlus4M2),   .q(PCPlus4W2));

  // WRITEBACK
  mux3 #(32) resultmux  (.d0(ALUResultW),  .d1(ReadDataW), .d2(PCPlus4W),  .s(ResultSrcW),  .y(ResultW));
  mux3 #(32) resultmux2 (.d0(ALUResultW2), .d1(ReadDataW), .d2(PCPlus4W2), .s(ResultSrcW2), .y(ResultW2));

endmodule