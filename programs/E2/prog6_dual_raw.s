# =====================================================================
# Programa 6 (E2) - RAW entre candidatas, forwarding entre vias y prioridades
# Objetivo:
#   - RAW dentro del par: la via 2 lee el destino de la via 1 -> NO se emiten juntas
#     (IssueSlot2D=0), la mas joven se conserva y se reagrupa en el ciclo siguiente.
#   - Forwarding entre vias: MEM1->EX2, MEM2->EX1, WB1->EX2, WB2->EX1.
#   - Prioridad con dos escrituras al mismo registro en el MISMO par (WAW):
#     MEM2 sobre MEM1 y WB2 sobre WB1 (la via 2 es la mas joven).
#   - Dos escrituras simultaneas en el Register File (mismo registro).
# =====================================================================
        addi x20, x0, 64       # par 0 v1 : base de memoria
        addi x1, x0, 5         # par 0 v2 : x1 = 5
        addi x2, x0, 7         # par 1 v1 : x2 = 7
        add  x3, x1, x2        # par 1 v2 : RAW con x2 (via 1 del par) -> se emite solo la via 1
                               #   reagrupado como via 1 del par siguiente:
                               #   x2 desde MEM1 y x1 desde WB2  -> x3 = 12
        addi x4, x0, 3         # (via 2 del par reagrupado) x4 = 3
        add  x5, x3, x4        # par v1 : x3 desde MEM1, x4 desde MEM2 (MEM2->EX1)  -> x5 = 15
        sub  x6, x4, x3        # par v2 : x4 desde MEM2, x3 desde MEM1 (MEM1->EX2)  -> x6 = -9
        addi x7, x0, 1         # par v1 : WAW en el mismo par:
        addi x7, x0, 2         # par v2 :   ambas escriben x7 en el mismo ciclo -> gana la via 2 (x7 = 2)
        add  x8, x7, x7        # par v1 : x7 en MEM1 (=1) y MEM2 (=2) -> prioridad MEM2 -> x8 = 4
        addi x9, x0, 4         # par v2 : x9 = 4 (independiente)
        add  x10, x7, x5       # par v1 : x7 en WB1 (=1) y WB2 (=2) -> prioridad WB2 ; x5 del RF -> x10 = 17
        add  x11, x8, x7       # par v2 : x8 desde MEM1 (via 1 -> via 2), x7 desde WB2 -> x11 = 6
        sub  x12, x11, x10     # par v1 : x11 desde MEM2 (MEM2->EX1), x10 desde MEM1 -> x12 = -11
        add  x13, x9, x8       # par v2 : x9 y x8 desde WB (WB2->EX2, WB1->EX2) -> x13 = 8
        sw   x3, 0(x20)        # M[64]  = 12
        sw   x5, 4(x20)        # M[68]  = 15
        sw   x6, 8(x20)        # M[72]  = -9
        sw   x7, 12(x20)       # M[76]  = 2
        sw   x8, 16(x20)       # M[80]  = 4
        sw   x10, 20(x20)      # M[84]  = 17
        sw   x11, 24(x20)      # M[88]  = 6
        sw   x12, 28(x20)      # M[92]  = -11
        sw   x13, 32(x20)      # M[96]  = 8
done:   beq  x0, x0, done
