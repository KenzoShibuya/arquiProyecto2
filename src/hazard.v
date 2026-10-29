module hazard(
    // Decode (D)
    input      [4:0] Rs1D,
    input      [4:0] Rs2D,
    // Execute (E)
    input      [4:0] Rs1E,
    input      [4:0] Rs2E,
    input      [4:0] RdE,
    input            PCSrcE,
    input            ResultSrcEb0,
    // Memory (M)
    input      [4:0] RdM,
    input            RegWriteM,
    // Writeback (W)
    input      [4:0] RdW,
    input            RegWriteW,
    // Salidas
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output           StallF,
    output           StallD,
    output           FlushD,
    output           FlushE
);

  wire lwStall;

  // Forwarding operando A (prioridad: MEM > WB > banco de registros)
  always @* begin
    if      ((Rs1E == RdM) & RegWriteM & (Rs1E != 5'b0)) ForwardAE = 2'b10; // ALUResultM
    else if ((Rs1E == RdW) & RegWriteW & (Rs1E != 5'b0)) ForwardAE = 2'b01; // ResultW
    else                                                 ForwardAE = 2'b00; // RD1E
  end

  // Forwarding operando B / WriteDataE
  always @* begin
    if      ((Rs2E == RdM) & RegWriteM & (Rs2E != 5'b0)) ForwardBE = 2'b10; // ALUResultM
    else if ((Rs2E == RdW) & RegWriteW & (Rs2E != 5'b0)) ForwardBE = 2'b01; // ResultW
    else                                                 ForwardBE = 2'b00; // RD2E
  end

  // Stall Load-Use: el lw en EX escribe un registro (distinto de x0) que la instruccion en D lee
  assign lwStall = ResultSrcEb0 & (RdE != 5'b0) & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallF  = lwStall;
  assign StallD  = lwStall;

  // Flush: salto tomado anula D y E; el Load-Use inserta una burbuja en E
  assign FlushD  = PCSrcE;
  assign FlushE  = lwStall | PCSrcE;

endmodule