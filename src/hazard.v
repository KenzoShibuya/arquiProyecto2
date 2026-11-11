module hazard(
    // Decode (D) - via 1
    input      [4:0] Rs1D,
    input      [4:0] Rs2D,
    input            UsesRs1D,
    input            UsesRs2D,
    // Execute (E) - via 1 y via 2
    input      [4:0] Rs1E,
    input      [4:0] Rs2E,
    input      [4:0] RdE,
    input            ResultSrcEb0,
    input      [4:0] Rs1E2,
    input      [4:0] Rs2E2,
    input      [4:0] RdE2,
    input            ResultSrcE2b0,
    input            PCSrcE,
    input            PCSrcE1,
    // Memory (M) - via 1 y via 2
    input      [4:0] RdM,
    input            RegWriteM,
    input      [4:0] RdM2,
    input            RegWriteM2,
    input            MemStall,
    // Writeback (W) - via 1 y via 2
    input      [4:0] RdW,
    input            RegWriteW,
    input      [4:0] RdW2,
    input            RegWriteW2,
    // Salidas de control de Forwarding (3 bits: [2]=via productora, [1:0]=etapa)
    //   3'b000: RegFile (sin forwarding)
    //   3'b001: WB1  (ResultW)
    //   3'b010: MEM1 (ForwardDataM1)
    //   3'b101: WB2  (ResultW2)
    //   3'b110: MEM2 (ForwardDataM2)
    output reg [2:0] ForwardAE,
    output reg [2:0] ForwardBE,
    output reg [2:0] ForwardAE2,
    output reg [2:0] ForwardBE2,
    // Salidas de Stall y Flush
    output           StallF,
    output           StallD,
    output           FlushD,
    output           FlushE,
    output           FlushM2
);

  wire lw_in_E1, lw_in_E2, lwStall;

  // Prioridad de forwarding (del productor mas reciente al mas antiguo):
  //   1. MEM2 (instruccion mas joven en MEM)
  //   2. MEM1 (instruccion mas antigua en MEM)
  //   3. WB2  (instruccion mas joven en WB)
  //   4. WB1  (instruccion mas antigua en WB)

  // Forwarding via 1 - operando A (Rs1E)
  always @* begin
    if      ((Rs1E == RdM2) & RegWriteM2 & (Rs1E != 5'b0)) ForwardAE = 3'b110; // MEM2
    else if ((Rs1E == RdM)  & RegWriteM  & (Rs1E != 5'b0)) ForwardAE = 3'b010; // MEM1
    else if ((Rs1E == RdW2) & RegWriteW2 & (Rs1E != 5'b0)) ForwardAE = 3'b101; // WB2
    else if ((Rs1E == RdW)  & RegWriteW  & (Rs1E != 5'b0)) ForwardAE = 3'b001; // WB1
    else                                                   ForwardAE = 3'b000; // RD1E
  end

  // Forwarding via 1 - operando B (Rs2E)
  always @* begin
    if      ((Rs2E == RdM2) & RegWriteM2 & (Rs2E != 5'b0)) ForwardBE = 3'b110; // MEM2
    else if ((Rs2E == RdM)  & RegWriteM  & (Rs2E != 5'b0)) ForwardBE = 3'b010; // MEM1
    else if ((Rs2E == RdW2) & RegWriteW2 & (Rs2E != 5'b0)) ForwardBE = 3'b101; // WB2
    else if ((Rs2E == RdW)  & RegWriteW  & (Rs2E != 5'b0)) ForwardBE = 3'b001; // WB1
    else                                                   ForwardBE = 3'b000; // RD2E
  end

  // Forwarding via 2 - operando A (Rs1E2)
  always @* begin
    if      ((Rs1E2 == RdM2) & RegWriteM2 & (Rs1E2 != 5'b0)) ForwardAE2 = 3'b110; // MEM2
    else if ((Rs1E2 == RdM)  & RegWriteM  & (Rs1E2 != 5'b0)) ForwardAE2 = 3'b010; // MEM1
    else if ((Rs1E2 == RdW2) & RegWriteW2 & (Rs1E2 != 5'b0)) ForwardAE2 = 3'b101; // WB2
    else if ((Rs1E2 == RdW)  & RegWriteW  & (Rs1E2 != 5'b0)) ForwardAE2 = 3'b001; // WB1
    else                                                     ForwardAE2 = 3'b000; // RD1E2
  end

  // Forwarding via 2 - operando B (Rs2E2)
  always @* begin
    if      ((Rs2E2 == RdM2) & RegWriteM2 & (Rs2E2 != 5'b0)) ForwardBE2 = 3'b110; // MEM2
    else if ((Rs2E2 == RdM)  & RegWriteM  & (Rs2E2 != 5'b0)) ForwardBE2 = 3'b010; // MEM1
    else if ((Rs2E2 == RdW2) & RegWriteW2 & (Rs2E2 != 5'b0)) ForwardBE2 = 3'b101; // WB2
    else if ((Rs2E2 == RdW)  & RegWriteW  & (Rs2E2 != 5'b0)) ForwardBE2 = 3'b001; // WB1
    else                                                     ForwardBE2 = 3'b000; // RD2E2
  end

  // Stall por dependencia Load-Use sobre la via 1 (mas antigua en ID)
  // Si el salto en via 1 es tomado (PCSrcE1), un lw en via 2 (EX2) queda anulado y no causa stall
  assign lw_in_E1 = ResultSrcEb0  & (RdE  != 5'b0);
  assign lw_in_E2 = ResultSrcE2b0 & (RdE2 != 5'b0) & ~PCSrcE1;

  assign lwStall = (lw_in_E1 & ((UsesRs1D & (Rs1D == RdE))  | (UsesRs2D & (Rs2D == RdE)))) |
                   (lw_in_E2 & ((UsesRs1D & (Rs1D == RdE2)) | (UsesRs2D & (Rs2D == RdE2))));

  // Un salto tomado en EX (PCSrcE) tiene prioridad sobre lwStall; MemStall congela todo el pipeline
  assign StallF  = (lwStall & ~PCSrcE) | MemStall;
  assign StallD  = (lwStall & ~PCSrcE) | MemStall;

  // Flush de etapas mas jovenes (inhibido mientras el pipeline esta congelado por MemStall)
  assign FlushD  = PCSrcE & ~MemStall;
  assign FlushE  = (lwStall | PCSrcE) & ~MemStall;
  assign FlushM2 = PCSrcE1 & ~MemStall; // Si salta la via 1, se anula la instruccion mas joven en EX2

endmodule