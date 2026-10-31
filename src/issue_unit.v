// Issue Unit PRELIMINAR
// todavia no se exige ejecucion simultanea: solo se emite la instruccion
// de la via 1 y el PC avanza de 4 en 4. La instruccion de la via 2 se vuelve a
// buscar en el ciclo siguiente como via 1, asi no se pierde ni se duplica
//mas tarde  este modulo decidira IssueSlot2 y PCInc8 segun dependencias y recursos para asi lograr el dual issue
module issue_unit(
    input  [31:0] InstrD,    // via 1 (mas antigua)
    input  [31:0] InstrD2,   // via 2 (mas joven)
    output        IssueSlot2D,
    output        PCInc8F
);
  assign IssueSlot2D = 1'b0;
  assign PCInc8F     = 1'b0;
endmodule