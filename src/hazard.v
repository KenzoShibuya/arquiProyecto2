module hazard(
    // Inputs from Decode stage (D)
    input      [4:0] Rs1D,
    input      [4:0] Rs2D,
    // Inputs from Execute stage (E)
    input      [4:0] Rs1E,
    input      [4:0] Rs2E,
    input      [4:0] RdE,
    input            PCSrcE,
    input            ResultSrcEb0,
    // Inputs from Memory stage (M)
    input      [4:0] RdM,
    input            RegWriteM,
    // Inputs from Writeback stage (W)
    input      [4:0] RdW,
    input            RegWriteW,
    // Outputs
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output           StallF,
    output           StallD,
    output           FlushD,
    output           FlushE
);

  wire lwStall;

  // Data Hazard: Forwarding logic for SrcAE
  always @* begin
    if (((Rs1E == RdM) & RegWriteM) & (Rs1E != 5'b0))
      ForwardAE = 2'b10; // Forward from Memory stage (ALUResultM)
    else if (((Rs1E == RdW) & RegWriteW) & (Rs1E != 5'b0))
      ForwardAE = 2'b01; // Forward from Writeback stage (ResultW)
    else
      ForwardAE = 2'b00; // No forwarding (use register file output RD1E)
  end

  // Data Hazard: Forwarding logic for SrcBE / WriteDataE
  always @* begin
    if (((Rs2E == RdM) & RegWriteM) & (Rs2E != 5'b0))
      ForwardBE = 2'b10; // Forward from Memory stage (ALUResultM)
    else if (((Rs2E == RdW) & RegWriteW) & (Rs2E != 5'b0))
      ForwardBE = 2'b01; // Forward from Writeback stage (ResultW)
    else
      ForwardBE = 2'b00; // No forwarding (use register file output RD2E)
  end

  // Data Hazard: Load-Use stall logic
  assign lwStall = ResultSrcEb0 & ((Rs1D == RdE) | (Rs2D == RdE));
  assign StallF  = lwStall;
  assign StallD  = lwStall;

  // Control Hazard: Branch/Jump flush logic + Load-Use bubble in EX
  assign FlushD  = PCSrcE;
  assign FlushE  = lwStall | PCSrcE;

endmodule
