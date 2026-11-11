module datapath #(
    parameter SINGLE_ISSUE = 0
)(
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
    input  [2:0]  ForwardAE,
    input  [2:0]  ForwardBE,
    input  [2:0]  ForwardAE2,
    input  [2:0]  ForwardBE2,
    input         StallF,
    input         StallD,
    input         FlushD,
    input         FlushE,
    input         FlushM2,
    input         MemStall,
    // Hacia controladores / hazard / issue
    output [31:0] InstrD,
    output [31:0] InstrD2,
    output [4:0]  Rs1D, Rs2D,
    output        UsesRs1D, UsesRs2D,
    output [4:0]  Rs1E, Rs2E, RdE,
    output [4:0]  Rs1E2, Rs2E2, RdE2,
    output        PCSrcE,
    output        PCSrcE1,
    output        ResultSrcEb0,
    output        ResultSrcE2b0,
    output [4:0]  RdM,
    output        RegWriteM,
    output [4:0]  RdM2,
    output        RegWriteM2,
    output [4:0]  RdW,
    output        RegWriteW,
    output [4:0]  RdW2,
    output        RegWriteW2,
    // Memoria de instrucciones (doble lectura)
    output [31:0] PCF,
    input  [31:0] InstrF,
    input  [31:0] InstrF2,
    // Etapa MEM hacia dcache (dos vias) y puerto compartido
    output        MemReadM,
    output        MemWriteM,
    output [31:0] ALUResultM,
    output [31:0] WriteDataM,
    output        MemReadM2,
    output        MemWriteM2,
    output [31:0] ALUResultM2,
    output [31:0] WriteDataM2,
    output        MemWriteM_port,
    output [31:0] DataAdrM_port,
    output [31:0] WriteDataM_port,
    input  [31:0] ReadDataM,
    input  [31:0] ReadDataM2
);

  // IF
  wire [31:0] PCNextF, PCSeqF, PCPlus4F, PCPlus8F;
  wire [31:0] NextInstrD, NextPCD, NextPCPlus4D;
  wire [31:0] NextInstrD2, NextPCD2, NextPCPlus4D2;
  // ID via 1
  wire [31:0] PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
  wire [4:0]  RdD;
  // ID via 2
  wire [31:0] PCD2, PCPlus4D2, RD1D2, RD2D2, ImmExtD2;
  wire [4:0]  Rs1D2, Rs2D2, RdD2, RdI2;
  wire [1:0]  ResultSrcI2;
  wire        RegWriteI2, MemWriteI2, JumpI2, BranchI2;   // control via 2 filtrado por IssueSlot2D
  // EX via 1
  wire        RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, ZeroE;
  wire [1:0]  ResultSrcE;
  wire [2:0]  ALUControlE;
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE, PCTargetE;
  wire [31:0] FwdWB_AE, FwdMEM_AE, FwdWB_BE, FwdMEM_BE;
  // EX via 2
  wire        RegWriteE2, MemWriteE2, JumpE2, BranchE2, ALUSrcE2, ZeroE2, PCSrcE2;
  wire [1:0]  ResultSrcE2;
  wire [2:0]  ALUControlE2;
  wire [31:0] RD1E2, RD2E2, PCE2, ImmExtE2, PCPlus4E2;
  wire [31:0] SrcAE2, SrcBE2, WriteDataE2, ALUResultE2;
  wire [31:0] FwdWB_AE2, FwdMEM_AE2, FwdWB_BE2, FwdMEM_BE2;
  // Recurso compartido de calculo de salto en EX
  wire        CtrlE2;
  wire [31:0] BranchBaseE, BranchImmE;
  // MEM via 1
  wire [1:0]  ResultSrcM;
  wire [31:0] PCPlus4M, ForwardDataM1;
  // MEM via 2
  wire        MemAccessM2;
  wire [1:0]  ResultSrcM2;
  wire [31:0] PCPlus4M2, ForwardDataM2;
  // WB via 1
  wire [1:0]  ResultSrcW;
  wire [31:0] ALUResultW, ReadDataW, PCPlus4W, ResultW;
  // WB via 2
  wire [1:0]  ResultSrcW2;
  wire [31:0] ALUResultW2, ReadDataW2, PCPlus4W2, ResultW2;


  // FETCH & REAGRUPAMIENTO (IF -> ID)

  adder pcadd4 (.a(PCF), .b(32'd4), .y(PCPlus4F));   // PC + 4
  adder pcadd8 (.a(PCF), .b(32'd8), .y(PCPlus8F));   // PC + 8

  // Avance secuencial: +4 (solo via 1 emitida) o +8 (par completo emitido)
  mux2 #(32) pcseqmux (.d0(PCPlus4F), .d1(PCPlus8F), .s(PCInc8F), .y(PCSeqF));

  // Redireccion por salto tomado en EX (recurso compartido entre via 1 y via 2)
  mux2 #(32) pcmux    (.d0(PCSeqF), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));

  flopenr #(32) pcreg (.clk(clk), .reset(reset), .en(~StallF), .d(PCNextF), .q(PCF));

  // Conservacion y reagrupamiento cuando IssueSlot2D == 0 (en modo Dual-Issue):
  // IssueSlot2D == 1: entran (InstrF, InstrF2) desde IF
  // IssueSlot2D == 0: la via 2 no emitida (InstrD2) pasa a la via 1 (InstrD), y se reagrupa con InstrF que entra en la via 2 (InstrD2)
  // En modo SINGLE_ISSUE == 1: IF alimenta directamente la via 1 (InstrF -> InstrD) y la via 2 permanece en NOP.
  wire        use_direct_if  = IssueSlot2D | (SINGLE_ISSUE != 0);
  wire [31:0] InstrF2_masked = (SINGLE_ISSUE != 0) ? 32'b0 : InstrF2;
  mux2 #(32) next_instrd_mux   (.d0(InstrD2),   .d1(InstrF),   .s(use_direct_if), .y(NextInstrD));
  mux2 #(32) next_pcd_mux      (.d0(PCD2),      .d1(PCF),      .s(use_direct_if), .y(NextPCD));
  mux2 #(32) next_pcplus4d_mux (.d0(PCPlus4D2), .d1(PCPlus4F), .s(use_direct_if), .y(NextPCPlus4D));

  mux2 #(32) next_instrd2_mux   (.d0(InstrF),   .d1(InstrF2_masked), .s(use_direct_if), .y(NextInstrD2));
  mux2 #(32) next_pcd2_mux      (.d0(PCF),      .d1(PCPlus4F),       .s(use_direct_if), .y(NextPCD2));
  mux2 #(32) next_pcplus4d2_mux (.d0(PCPlus4F), .d1(PCPlus8F),       .s(use_direct_if), .y(NextPCPlus4D2));

  // Registro IF/ID (par de instrucciones)

  // via 1
  flopenrc #(32) instrd_reg   (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextInstrD),   .q(InstrD));
  flopenrc #(32) pcd_reg      (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextPCD),      .q(PCD));
  flopenrc #(32) pcplus4d_reg (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextPCPlus4D), .q(PCPlus4D));
  // via 2
  flopenrc #(32) instrd2_reg   (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextInstrD2),   .q(InstrD2));
  flopenrc #(32) pcd2_reg      (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextPCD2),      .q(PCD2));
  flopenrc #(32) pcplus4d2_reg (.clk(clk), .reset(reset), .clear(FlushD), .en(~StallD), .d(NextPCPlus4D2), .q(PCPlus4D2));


  // DECODE (ID)

  assign Rs1D  = InstrD[19:15];
  assign Rs2D  = InstrD[24:20];
  assign RdD   = InstrD[11:7];

  assign UsesRs1D = ~JumpD & (InstrD[6:0] != 7'b0000000);
  assign UsesRs2D = (InstrD[6:0] == 7'b0110011) | MemWriteD | BranchD;

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

  // La via 2 solo pasa a EX si la Issue Unit la emite; si no, entra una burbuja limpia

  assign RegWriteI2  = RegWriteD2 & IssueSlot2D;
  assign MemWriteI2  = MemWriteD2 & IssueSlot2D;
  assign JumpI2      = JumpD2     & IssueSlot2D;
  assign BranchI2    = BranchD2   & IssueSlot2D;
  assign ResultSrcI2 = IssueSlot2D ? ResultSrcD2 : 2'b00;
  assign RdI2        = IssueSlot2D ? RdD2        : 5'b0;

  // Registro ID/EX via 1
  flopenrc #(1)  regwrite_e_reg   (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RegWriteD),   .q(RegWriteE));
  flopenrc #(2)  resultsrc_e_reg  (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ResultSrcD),  .q(ResultSrcE));
  flopenrc #(1)  memwrite_e_reg   (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(MemWriteD),   .q(MemWriteE));
  flopenrc #(1)  jump_e_reg       (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(JumpD),       .q(JumpE));
  flopenrc #(1)  branch_e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(BranchD),     .q(BranchE));
  flopenrc #(3)  alucontrol_e_reg (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ALUControlD), .q(ALUControlE));
  flopenrc #(1)  alusrc_e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ALUSrcD),     .q(ALUSrcE));
  flopenrc #(32) rd1_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RD1D),        .q(RD1E));
  flopenrc #(32) rd2_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RD2D),        .q(RD2E));
  flopenrc #(32) pce_reg          (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(PCD),         .q(PCE));
  flopenrc #(5)  rs1e_reg         (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(Rs1D),        .q(Rs1E));
  flopenrc #(5)  rs2e_reg         (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(Rs2D),        .q(Rs2E));
  flopenrc #(5)  rde_reg          (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RdD),         .q(RdE));
  flopenrc #(32) imm_e_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ImmExtD),     .q(ImmExtE));
  flopenrc #(32) pcplus4e_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(PCPlus4D),    .q(PCPlus4E));

  // Registro ID/EX via 2
  flopenrc #(1)  regwrite_e2_reg   (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RegWriteI2),   .q(RegWriteE2));
  flopenrc #(2)  resultsrc_e2_reg  (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ResultSrcI2),  .q(ResultSrcE2));
  flopenrc #(1)  memwrite_e2_reg   (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(MemWriteI2),   .q(MemWriteE2));
  flopenrc #(1)  jump_e2_reg       (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(JumpI2),       .q(JumpE2));
  flopenrc #(1)  branch_e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(BranchI2),     .q(BranchE2));
  flopenrc #(3)  alucontrol_e2_reg (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ALUControlD2), .q(ALUControlE2));
  flopenrc #(1)  alusrc_e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ALUSrcD2),     .q(ALUSrcE2));
  flopenrc #(32) rd1_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RD1D2),        .q(RD1E2));
  flopenrc #(32) rd2_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RD2D2),        .q(RD2E2));
  flopenrc #(32) pce2_reg          (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(PCD2),         .q(PCE2));
  flopenrc #(5)  rs1e2_reg         (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(Rs1D2),        .q(Rs1E2));
  flopenrc #(5)  rs2e2_reg         (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(Rs2D2),        .q(Rs2E2));
  flopenrc #(5)  rde2_reg          (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(RdI2),         .q(RdE2));
  flopenrc #(32) imm_e2_reg        (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(ImmExtD2),     .q(ImmExtE2));
  flopenrc #(32) pcplus4e2_reg     (.clk(clk), .reset(reset), .clear(FlushE), .en(~MemStall), .d(PCPlus4D2),    .q(PCPlus4E2));

  // EXECUTE (EX) - Dos ALU + Cross-Forwarding + Recurso compartido de Saltos

  // Datos adelantables desde MEM (incluye soporte para jal que escribe PC+4)
  assign ForwardDataM1 = (ResultSrcM  == 2'b10) ? PCPlus4M  : ALUResultM;
  assign ForwardDataM2 = (ResultSrcM2 == 2'b10) ? PCPlus4M2 : ALUResultM2;

  // Cross-Forwarding via 1: bit [2] selecciona via productora (0=via 1, 1=via 2),
  //                         bits [1:0] seleccionan etapa (00=RegFile, 01=WB, 10=MEM)
  mux2 #(32) fwd_wb_ae_mux  (.d0(ResultW),       .d1(ResultW2),       .s(ForwardAE[2]),   .y(FwdWB_AE));
  mux2 #(32) fwd_mem_ae_mux (.d0(ForwardDataM1), .d1(ForwardDataM2),  .s(ForwardAE[2]),   .y(FwdMEM_AE));
  mux3 #(32) forwarda_mux   (.d0(RD1E),          .d1(FwdWB_AE),       .d2(FwdMEM_AE),     .s(ForwardAE[1:0]), .y(SrcAE));

  mux2 #(32) fwd_wb_be_mux  (.d0(ResultW),       .d1(ResultW2),       .s(ForwardBE[2]),   .y(FwdWB_BE));
  mux2 #(32) fwd_mem_be_mux (.d0(ForwardDataM1), .d1(ForwardDataM2),  .s(ForwardBE[2]),   .y(FwdMEM_BE));
  mux3 #(32) forwardb_mux   (.d0(RD2E),          .d1(FwdWB_BE),       .d2(FwdMEM_BE),     .s(ForwardBE[1:0]), .y(WriteDataE));

  mux2 #(32) srcbmux        (.d0(WriteDataE),    .d1(ImmExtE),        .s(ALUSrcE),        .y(SrcBE));
  alu        alu_unit       (.a(SrcAE),          .b(SrcBE),           .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE));

  // Cross-Forwarding via 2
  mux2 #(32) fwd_wb_ae2_mux  (.d0(ResultW),       .d1(ResultW2),      .s(ForwardAE2[2]),  .y(FwdWB_AE2));
  mux2 #(32) fwd_mem_ae2_mux (.d0(ForwardDataM1), .d1(ForwardDataM2), .s(ForwardAE2[2]),  .y(FwdMEM_AE2));
  mux3 #(32) forwarda2_mux   (.d0(RD1E2),         .d1(FwdWB_AE2),     .d2(FwdMEM_AE2),    .s(ForwardAE2[1:0]), .y(SrcAE2));

  mux2 #(32) fwd_wb_be2_mux  (.d0(ResultW),       .d1(ResultW2),      .s(ForwardBE2[2]),  .y(FwdWB_BE2));
  mux2 #(32) fwd_mem_be2_mux (.d0(ForwardDataM1), .d1(ForwardDataM2), .s(ForwardBE2[2]),  .y(FwdMEM_BE2));
  mux3 #(32) forwardb2_mux   (.d0(RD2E2),         .d1(FwdWB_BE2),     .d2(FwdMEM_BE2),    .s(ForwardBE2[1:0]), .y(WriteDataE2));

  mux2 #(32) srcbmux2        (.d0(WriteDataE2),   .d1(ImmExtE2),      .s(ALUSrcE2),       .y(SrcBE2));
  alu        alu_unit2       (.a(SrcAE2),         .b(SrcBE2),         .alucontrol(ALUControlE2), .result(ALUResultE2), .zero(ZeroE2));

  // Unico recurso compartido de resolucion y calculo de destino de saltos (beq / jal)
  assign CtrlE2 = BranchE2 | JumpE2;
  mux2 #(32) branch_base_mux (.d0(PCE),     .d1(PCE2),     .s(CtrlE2), .y(BranchBaseE));
  mux2 #(32) branch_imm_mux  (.d0(ImmExtE), .d1(ImmExtE2), .s(CtrlE2), .y(BranchImmE));
  adder      pcaddbranch     (.a(BranchBaseE), .b(BranchImmE), .y(PCTargetE));

  assign PCSrcE1        = (BranchE  & ZeroE)  | JumpE;    // salto tomado en via 1 (mas antigua)
  assign PCSrcE2        = (BranchE2 & ZeroE2) | JumpE2;   // salto tomado en via 2 (mas joven)
  assign PCSrcE         = PCSrcE1 | PCSrcE2;
  assign ResultSrcEb0   = ResultSrcE[0];
  assign ResultSrcE2b0  = ResultSrcE2[0];

  // Registro EX/MEM via 1 (se conserva incluso si la via 2 toma un salto, por ser mas antigua)
  flopenr #(1)  regwrite_m_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(RegWriteE),  .q(RegWriteM));
  flopenr #(2)  resultsrc_m_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ResultSrcE), .q(ResultSrcM));
  flopenr #(1)  memwrite_m_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(MemWriteE),  .q(MemWriteM));
  flopenr #(32) aluresult_m_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ALUResultE), .q(ALUResultM));
  flopenr #(32) writedata_m_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(WriteDataE), .q(WriteDataM));
  flopenr #(5)  rdm_reg         (.clk(clk), .reset(reset), .en(~MemStall), .d(RdE),        .q(RdM));
  flopenr #(32) pcplus4m_reg    (.clk(clk), .reset(reset), .en(~MemStall), .d(PCPlus4E),   .q(PCPlus4M));

  // Registro EX/MEM via 2 (se limpia con FlushM2 = PCSrcE1 si la via 1 toma un salto)
  flopenrc #(1)  regwrite_m2_reg  (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(RegWriteE2),  .q(RegWriteM2));
  flopenrc #(2)  resultsrc_m2_reg (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(ResultSrcE2), .q(ResultSrcM2));
  flopenrc #(1)  memwrite_m2_reg  (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(MemWriteE2),  .q(MemWriteM2));
  flopenrc #(32) aluresult_m2_reg (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(ALUResultE2), .q(ALUResultM2));
  flopenrc #(32) writedata_m2_reg (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(WriteDataE2), .q(WriteDataM2));
  flopenrc #(5)  rdm2_reg         (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(RdE2),        .q(RdE2));
  flopenrc #(32) pcplus4m2_reg    (.clk(clk), .reset(reset), .clear(FlushM2), .en(~MemStall), .d(PCPlus4E2),   .q(PCPlus4M2));


  // MEMORY (MEM) - Señales hacia dcache y puerto de memoria de datos (dmem)

  assign MemReadM        = ResultSrcM[0];
  assign MemReadM2       = ResultSrcM2[0];
  assign MemAccessM2     = MemWriteM2 | ResultSrcM2[0];
  assign MemWriteM_port  = MemWriteM  | MemWriteM2;
  assign DataAdrM_port   = MemAccessM2 ? ALUResultM2 : ALUResultM;
  assign WriteDataM_port = MemWriteM2  ? WriteDataM2 : WriteDataM;

  // Registro MEM/WB via 1
  flopenr #(1)  regwrite_w_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(RegWriteM),  .q(RegWriteW));
  flopenr #(2)  resultsrc_w_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ResultSrcM), .q(ResultSrcW));
  flopenr #(32) aluresult_w_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ALUResultM), .q(ALUResultW));
  flopenr #(32) readdata_w_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(ReadDataM),  .q(ReadDataW));
  flopenr #(5)  rdw_reg         (.clk(clk), .reset(reset), .en(~MemStall), .d(RdM),        .q(RdW));
  flopenr #(32) pcplus4w_reg    (.clk(clk), .reset(reset), .en(~MemStall), .d(PCPlus4M),   .q(PCPlus4W));

  // Registro MEM/WB via 2
  flopenr #(1)  regwrite_w2_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(RegWriteM2),  .q(RegWriteW2));
  flopenr #(2)  resultsrc_w2_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ResultSrcM2), .q(ResultSrcW2));
  flopenr #(32) aluresult_w2_reg (.clk(clk), .reset(reset), .en(~MemStall), .d(ALUResultM2), .q(ALUResultW2));
  flopenr #(32) readdata_w2_reg  (.clk(clk), .reset(reset), .en(~MemStall), .d(ReadDataM2),  .q(ReadDataW2));
  flopenr #(5)  rdw2_reg         (.clk(clk), .reset(reset), .en(~MemStall), .d(RdM2),        .q(RdW2));
  flopenr #(32) pcplus4w2_reg    (.clk(clk), .reset(reset), .en(~MemStall), .d(PCPlus4M2),   .q(PCPlus4W2));


  // WRITEBACK (WB)

  mux3 #(32) resultmux  (.d0(ALUResultW),  .d1(ReadDataW),  .d2(PCPlus4W),  .s(ResultSrcW),  .y(ResultW));
  mux3 #(32) resultmux2 (.d0(ALUResultW2), .d1(ReadDataW2), .d2(PCPlus4W2), .s(ResultSrcW2), .y(ResultW2));

endmodule