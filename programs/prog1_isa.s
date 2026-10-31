# =====================================================================
# Programa 1 - ISA sin dependencias
# Objetivo: ejecutar todas las instrucciones RV32I soportadas
#   (add, sub, and, or, slt, addi, andi, ori, slti, lw, sw, beq no tomado)
#   sin que la Hazard Unit tenga que intervenir: todo consumidor esta
#   al menos 3 instrucciones despues de su productor (el Register File
#   escribe en el flanco de bajada y se lee en la segunda mitad del ciclo).
# Esperado: ForwardAE = ForwardBE = 00, StallF/StallD = 0 y FlushD/FlushE = 0
#   en todo el programa, salvo el bucle final "done", que es un salto tomado.
# =====================================================================
        addi x1, x0, 12        # x1 = 12
        addi x2, x0, 5         # x2 = 5
        addi x3, x0, -3        # x3 = -3
        addi x4, x0, 240       # x4 = 0xF0
        addi x5, x0, 255       # x5 = 0xFF
        addi x6, x0, 64        # x6 = 64  (base de memoria)
        add  x7, x1, x2        # x7  = 12 + 5      = 17
        sub  x8, x1, x2        # x8  = 12 - 5      = 7
        and  x9, x4, x5        # x9  = 0xF0 & 0xFF = 240
        or   x10, x1, x4       # x10 = 12 | 240    = 252
        slt  x11, x3, x2       # x11 = (-3 < 5)    = 1
        slt  x12, x2, x3       # x12 = (5 < -3)    = 0
        andi x13, x5, 60       # x13 = 255 & 60    = 60
        ori  x14, x1, 768      # x14 = 12 | 768    = 780
        slti x15, x3, 0        # x15 = (-3 < 0)    = 1
        addi x16, x2, -10      # x16 = 5 - 10      = -5
        sw   x1, 0(x6)         # M[64] = 12
        sw   x2, 4(x6)         # M[68] = 5
        beq  x1, x2, fail      # 12 != 5 -> NO tomado
        lw   x17, 0(x6)        # x17 = M[64] = 12
        lw   x18, 4(x6)        # x18 = M[68] = 5
        nop
        nop
        nop
        sw   x7, 8(x6)         # M[72]  = 17
        sw   x8, 12(x6)        # M[76]  = 7
        sw   x9, 16(x6)        # M[80]  = 240
        sw   x10, 20(x6)       # M[84]  = 252
        sw   x11, 24(x6)       # M[88]  = 1
        sw   x12, 28(x6)       # M[92]  = 0
        sw   x13, 32(x6)       # M[96]  = 60
        sw   x14, 36(x6)       # M[100] = 780
        sw   x15, 40(x6)       # M[104] = 1
        sw   x16, 44(x6)       # M[108] = -5 (0xFFFFFFFB)
        sw   x17, 48(x6)       # M[112] = 12
        sw   x18, 52(x6)       # M[116] = 5
done:   beq  x0, x0, done      # fin: bucle infinito
fail:   addi x31, x0, -1       # solo se ejecuta si el beq falla
        beq  x0, x0, fail
