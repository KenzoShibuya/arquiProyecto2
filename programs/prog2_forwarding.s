# =====================================================================
# Programa 2 - Forwarding
# Objetivo: dependencias RAW resueltas SIN stalls, solo con forwarding:
#   MEM->EX y WB->EX, en el operando A (rs1) y en el B (rs2),
#   prioridad MEM sobre WB, no forwarding de x0,
#   forwarding al dato de un sw (WriteDataE) y a los operandos de un beq.
# =====================================================================
        addi x20, x0, 64       # base de memoria
        addi x15, x0, 0        # x15 = 0 (debe seguir en 0 al final)
        addi x1, x0, 10        # x1 = 10
        addi x2, x0, 3         # x2 = 3
        add  x3, x1, x2        # B desde MEM (x2), A desde WB (x1)    -> 13
        sub  x4, x3, x1        # A desde MEM (x3)                      -> 3
        or   x5, x2, x3        # B desde WB (x3)                       -> 15
        and  x6, x4, x3        # A desde WB (x4)                       -> 1
        addi x7, x6, 5         # A desde MEM (x6)                      -> 6
        addi x8, x0, 1         # x8 = 1 (valor viejo, queda en WB)
        addi x8, x0, 2         # x8 = 2 (valor nuevo, queda en MEM)
        add  x9, x8, x8        # A y B desde MEM: gana el mas reciente -> 4
        addi x0, x0, 7         # intenta escribir x0 (RegWrite=1, Rd=0)
        add  x10, x0, x2       # x0 NO se reenvia                      -> 3
        addi x11, x0, 77       # x11 = 77
        sw   x11, 0(x20)       # dato del sw desde MEM (ForwardBE=10)  -> M[64] = 77
        add  x12, x9, x7       # 4 + 6                                 -> 10
        nop
        sw   x12, 4(x20)       # dato del sw desde WB (ForwardBE=01)   -> M[68] = 10
        addi x13, x0, 5
        addi x14, x0, 5
        beq  x13, x14, ok      # A desde WB, B desde MEM -> TOMADO
        addi x15, x0, -1       # anulada por el salto (x15 queda en 0)
ok:     sw   x3, 8(x20)        # M[72]  = 13
        sw   x4, 12(x20)       # M[76]  = 3
        sw   x5, 16(x20)       # M[80]  = 15
        sw   x6, 20(x20)       # M[84]  = 1
        sw   x7, 24(x20)       # M[88]  = 6
        sw   x9, 28(x20)       # M[92]  = 4
        sw   x10, 32(x20)      # M[96]  = 3
        sw   x15, 36(x20)      # M[100] = 0
done:   beq  x0, x0, done
