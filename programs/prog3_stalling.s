# =====================================================================
# Programa 3 - Stalling (Load-Use)
# Objetivo: dependencias que el forwarding NO puede resolver porque el dato
#   de un lw recien existe al final de MEM. La Hazard Unit congela F y D
#   (StallF = StallD = 1) e inserta una burbuja en E (FlushE = 1).
# =====================================================================
        addi x20, x0, 64       # base de memoria
        addi x12, x0, 0        # x12 = 0 (debe seguir en 0 al final)
        addi x1, x0, 25        # x1 = 25
        addi x2, x0, -7        # x2 = -7
        sw   x1, 0(x20)        # M[64] = 25
        sw   x2, 4(x20)        # M[68] = -7
        lw   x3, 0(x20)        # x3 = 25
        add  x4, x3, x1        # LOAD-USE en rs1 -> 1 stall            -> 50
        lw   x5, 4(x20)        # x5 = -7
        sub  x6, x1, x5        # LOAD-USE en rs2 -> 1 stall            -> 32
        lw   x7, 0(x20)        # x7 = 25
        sw   x7, 8(x20)        # LOAD-USE en el dato del sw -> stall   -> M[72] = 25
        lw   x8, 4(x20)        # x8 = -7
        nop
        add  x9, x8, x8        # distancia 2: SIN stall, forwarding WB -> -14
        lw   x0, 0(x20)        # carga a x0 (se descarta)
        add  x10, x0, x1       # SIN stall: x0 no genera dependencia  -> 25
        lw   x11, 0(x20)       # x11 = 25
        beq  x11, x1, eq       # LOAD-USE en un beq -> stall y TOMADO
        addi x12, x0, -1       # anulada por el salto (x12 queda en 0)
eq:     lw   x13, 4(x20)       # x13 = -7
        lw   x14, 0(x20)       # x14 = 25
        add  x15, x13, x14     # stall por x14 (x13 ya esta en el RF) -> 18
        sw   x4, 12(x20)       # M[76]  = 50
        sw   x6, 16(x20)       # M[80]  = 32
        sw   x9, 20(x20)       # M[84]  = -14
        sw   x10, 24(x20)      # M[88]  = 25
        sw   x12, 28(x20)      # M[92]  = 0
        sw   x15, 32(x20)      # M[96]  = 18
done:   beq  x0, x0, done
