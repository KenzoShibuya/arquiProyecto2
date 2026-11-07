# =====================================================================
# Programa 7 (E2) - Puerto unico de memoria, asignacion de recursos y Load-Use
# Objetivo:
#   - Load/Store junto con una ALU independiente, en CUALQUIER orden del par -> DUAL.
#   - Dos accesos a memoria en el mismo par -> conflicto estructural (solo se emite la via 1).
#   - Load-Use con el lw en la via 2 de EX y el consumidor en la via 1 de ID -> STALL.
#   - Load-Use con el consumidor en la via 2 de ID -> la Issue Unit no la emite
#     (emision parcial, sin stall); en el ciclo siguiente se reagrupa y recibe el dato por WB.
#   - Load-Use con RAW dentro del par (lw + consumidor juntos) -> se separa y luego STALL.
# =====================================================================
        addi x20, x0, 64       # par v1 : base de memoria
        addi x1, x0, 11        # par v2 : x1 = 11
        addi x2, x0, 22        # par v1
        addi x3, x0, 33        # par v2
        sw   x1, 0(x20)        # par v1 : STORE en via 1 + ALU en via 2 -> DUAL    M[64] = 11
        addi x4, x0, 44        # par v2
        addi x5, x0, 55        # par v1 : ALU en via 1 + STORE en via 2 -> DUAL
        sw   x2, 4(x20)        # par v2 :                                          M[68] = 22
        sw   x3, 8(x20)        # par v1 : dos STORE en el mismo par -> conflicto de memoria,
        sw   x4, 12(x20)       # par v2 :   solo se emite la via 1                 M[72] = 33, M[76] = 44
        addi x6, x0, 66        # (reagrupado con el sw anterior) STORE + ALU -> DUAL
        lw   x7, 0(x20)        # par v1 : LOAD en via 1 + ALU en via 2 -> DUAL     x7 = 11
        addi x8, x0, 77        # par v2
        addi x9, x0, 88        # par v1 : ALU en via 1 + LOAD en via 2 -> DUAL
        lw   x10, 4(x20)       # par v2 :                                          x10 = 22
        add  x11, x10, x1      # par v1 : Load-Use con el lw de la via 2 (en EX2) -> STALL 1 ciclo
        addi x12, x0, 1        # par v2 :                                          x11 = 33
        lw   x13, 8(x20)       # par v1 : LOAD                                     x13 = 33
        addi x14, x0, 2        # par v2
        addi x15, x0, 3        # par v1 :
        add  x16, x13, x13     # par v2 : Load-Use en la via 2 (lw en EX1) -> emision parcial, sin stall
                               #   reagrupado como via 1 del par siguiente: x13 por WB  -> x16 = 66
        addi x22, x0, 5        # (via 2 del par reagrupado) ALU independiente -> DUAL
        lw   x17, 12(x20)      # par v1 : LOAD                                     x17 = 44
        add  x18, x17, x1      # par v2 : RAW con el lw del mismo par -> solo via 1; luego, ya en
                               #   la via 1, Load-Use con el lw en EX1 -> STALL    x18 = 55
        lw   x19, 0(x20)       # (via 2, junto al add tras el stall) ALU + LOAD -> DUAL  x19 = 11
        lw   x21, 4(x20)       # par v1 : LOAD + STORE en el mismo par -> conflicto de memoria
                               #   x21 = 22 ; el sw siguiente se reagrupa
        sw   x7, 16(x20)       # M[80]  = 11
        sw   x10, 20(x20)      # M[84]  = 22
        sw   x11, 24(x20)      # M[88]  = 33
        sw   x13, 28(x20)      # M[92]  = 33
        sw   x16, 32(x20)      # M[96]  = 66
        sw   x17, 36(x20)      # M[100] = 44
        sw   x18, 40(x20)      # M[104] = 55
        sw   x19, 44(x20)      # M[108] = 11
        sw   x21, 48(x20)      # M[112] = 22
        sw   x5, 52(x20)       # M[116] = 55
        sw   x6, 56(x20)       # M[120] = 66
        sw   x8, 60(x20)       # M[124] = 77
done:   beq  x0, x0, done
