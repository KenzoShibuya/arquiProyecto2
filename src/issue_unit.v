module issue_unit(
    input  [31:0] InstrD,    // via 1 (mas antigua)
    input  [31:0] InstrD2,   // via 2 (mas joven)
    output        IssueSlot2D,
    output        PCInc8F
);
  assign IssueSlot2D = 1'b0;
  assign PCInc8F     = 1'b0;
endmodule