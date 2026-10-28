module pipe_if_id(
    input             clk,
    input             reset,
    input             clear,
    input             en,
    input      [31:0] PCF,
    input      [31:0] PCPlus4F,
    input      [31:0] InstrF,
    output reg [31:0] PCD,
    output reg [31:0] PCPlus4D,
    output reg [31:0] InstrD
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      PCD      <= 32'b0;
      PCPlus4D <= 32'b0;
      InstrD   <= 32'b0;
    end else if (en) begin
      if (clear) begin
        PCD      <= 32'b0;
        PCPlus4D <= 32'b0;
        InstrD   <= 32'b0;
      end else begin
        PCD      <= PCF;
        PCPlus4D <= PCPlus4F;
        InstrD   <= InstrF;
      end
    end
  end

endmodule
