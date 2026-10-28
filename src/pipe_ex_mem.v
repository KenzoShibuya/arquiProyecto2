module pipe_ex_mem(
    input             clk,
    input             reset,
    input             clear,
    input             en,
    // Control inputs (E)
    input             RegWriteE,
    input      [1:0]  ResultSrcE,
    input             MemWriteE,
    // Data inputs (E)
    input      [31:0] ALUResultE,
    input      [31:0] WriteDataE,
    input      [4:0]  RdE,
    input      [31:0] PCPlus4E,
    // Control outputs (M)
    output reg        RegWriteM,
    output reg [1:0]  ResultSrcM,
    output reg        MemWriteM,
    // Data outputs (M)
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,
    output reg [4:0]  RdM,
    output reg [31:0] PCPlus4M
);

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      RegWriteM  <= 1'b0;
      ResultSrcM <= 2'b00;
      MemWriteM  <= 1'b0;
      ALUResultM <= 32'b0;
      WriteDataM <= 32'b0;
      RdM        <= 5'b0;
      PCPlus4M   <= 32'b0;
    end else if (en) begin
      if (clear) begin
        RegWriteM  <= 1'b0;
        ResultSrcM <= 2'b00;
        MemWriteM  <= 1'b0;
        ALUResultM <= 32'b0;
        WriteDataM <= 32'b0;
        RdM        <= 5'b0;
        PCPlus4M   <= 32'b0;
      end else begin
        RegWriteM  <= RegWriteE;
        ResultSrcM <= ResultSrcE;
        MemWriteM  <= MemWriteE;
        ALUResultM <= ALUResultE;
        WriteDataM <= WriteDataE;
        RdM        <= RdE;
        PCPlus4M   <= PCPlus4E;
      end
    end
  end

endmodule
