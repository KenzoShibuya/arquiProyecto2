module issue_unit #(
    parameter ENABLE_DCACHE = 1,
    parameter SINGLE_ISSUE  = 0
)(
    input  [31:0] InstrD,        // via 1 (mas antigua)
    input  [31:0] InstrD2,       // via 2 (mas joven)
    // Senales de control via 1 (Decode)
    input         RegWriteD,
    input         MemWriteD,
    input  [1:0]  ResultSrcD,
    input         BranchD,
    input         JumpD,
    // Senales de control via 2 (Decode)
    input         RegWriteD2,
    input         MemWriteD2,
    input  [1:0]  ResultSrcD2,
    input         BranchD2,
    input         JumpD2,
    // Estado en Execute para detectar Load-Use sobre la via 2
    input  [4:0]  RdE,
    input         ResultSrcEb0,
    input  [4:0]  RdE2,
    input         ResultSrcE2b0,
    // Salidas de decision de emision
    output        IssueSlot2D,
    output        PCInc8F
);

  wire [6:0] opD2  = InstrD2[6:0];
  wire [4:0] RdD   = InstrD[11:7];
  wire [4:0] Rs1D2 = InstrD2[19:15];
  wire [4:0] Rs2D2 = InstrD2[24:20];

  // Identificacion de si la via 2 realmente lee Rs1D2 / Rs2D2

  wire UsesRs1D2 = ~JumpD2 & (opD2 != 7'b0000000);
  wire UsesRs2D2 = (opD2 == 7'b0110011) | MemWriteD2 | BranchD2;

  // 1. Dependencia RAW intra-par: la via 1 escribe un registro que la via 2 lee
  
  wire raw_hazard = RegWriteD & (RdD != 5'b0) &
                    ((UsesRs1D2 & (Rs1D2 == RdD)) |
                     (UsesRs2D2 & (Rs2D2 == RdD)));

  // 2. Conflicto estructural del puerto de memoria de datos (lw / sw)
  // Con dcache L1 de doble acceso (ENABLE_DCACHE=1), lw+lw, lw+sw y sw+lw se emiten juntos;
  // solo se bloquea en ID cuando ambas instrucciones son escrituras (sw+sw).

  wire IsMemD       = MemWriteD  | ResultSrcD[0];
  wire IsMemD2      = MemWriteD2 | ResultSrcD2[0];
  wire mem_conflict = ENABLE_DCACHE ? (MemWriteD & MemWriteD2) : (IsMemD & IsMemD2);

  // 3. Conflicto estructural del unico recurso de saltos (beq / jal)

  wire IsCtrlD       = BranchD  | JumpD;
  wire IsCtrlD2      = BranchD2 | JumpD2;
  wire ctrl_conflict = (IsCtrlD & IsCtrlD2) | JumpD;

  // 4. Hazard Load-Use de la via 2 con un lw previo en EX (via 1 o via 2)

  wire lw_e1_slot2 = ResultSrcEb0  & (RdE  != 5'b0) &
                     ((UsesRs1D2 & (Rs1D2 == RdE))  | (UsesRs2D2 & (Rs2D2 == RdE)));
  wire lw_e2_slot2 = ResultSrcE2b0 & (RdE2 != 5'b0) &
                     ((UsesRs1D2 & (Rs1D2 == RdE2)) | (UsesRs2D2 & (Rs2D2 == RdE2)));
  wire lw_hazard_slot2 = lw_e1_slot2 | lw_e2_slot2;

  // Se emite el par completo si no existe ninguna restriccion (y no esta forzado a Single-Issue)
  assign IssueSlot2D = SINGLE_ISSUE ? 1'b0 : ~(raw_hazard | mem_conflict | ctrl_conflict | lw_hazard_slot2);
  assign PCInc8F     = IssueSlot2D;

endmodule