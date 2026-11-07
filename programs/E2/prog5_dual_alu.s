# =====================================================================
# Programa 5 (E2) - Emision simultanea de instrucciones ALU independientes
# Objetivo: todos los pares de la fase de computo son independientes entre si
#   (ninguna instruccion de la via 2 lee el destino de la via 1 del mismo par),
#   no hay accesos a memoria ni saltos -> la Issue Unit emite SIEMPRE 2 (IssueSlot2D=1).
#   Las dependencias con pares anteriores se resuelven por forwarding o por el RF.
# Esperado en la fase de computo (0x00-0x34): 8 pares, todos DUAL, sin stalls.
# =====================================================================
        addi x1, x0, 10        # par 0 v1 : x1 = 10
        addi x2, x0, 20        # par 0 v2 : x2 = 20
        addi x3, x0, 30        # par 1 v1 : x3 = 30
        addi x4, x0, -5        # par 1 v2 : x4 = -5
        addi x20, x0, 64       # par 2 v1 : base de memoria
        addi x5, x0, 7         # par 2 v2 : x5 = 7
        add  x6, x1, x2        # par 3 v1 : x6 = 30
        sub  x7, x3, x4        # par 3 v2 : x7 = 35
        and  x8, x1, x3        # par 4 v1 : x8 = 10 & 30 = 10
        or   x9, x2, x4        # par 4 v2 : x9 = 20 | -5 = -1
        slt  x10, x4, x1       # par 5 v1 : x10 = 1
        slti x11, x3, 100      # par 5 v2 : x11 = 1
        andi x12, x2, 12       # par 6 v1 : x12 = 20 & 12 = 4
        ori  x13, x1, 5        # par 6 v2 : x13 = 15
        add  x14, x6, x7       # par 7 v1 : x14 = 65  (x6/x7 producidos por un par anterior)
        sub  x15, x9, x5       # par 7 v2 : x15 = -8
        # ---- almacenamiento de resultados (los sw se emiten de a uno: puerto unico) ----
        sw   x6, 0(x20)        # M[64]  = 30
        sw   x7, 4(x20)        # M[68]  = 35
        sw   x8, 8(x20)        # M[72]  = 10
        sw   x9, 12(x20)       # M[76]  = -1
        sw   x10, 16(x20)      # M[80]  = 1
        sw   x11, 20(x20)      # M[84]  = 1
        sw   x12, 24(x20)      # M[88]  = 4
        sw   x13, 28(x20)      # M[92]  = 15
        sw   x14, 32(x20)      # M[96]  = 65
        sw   x15, 36(x20)      # M[100] = -8
done:   beq  x0, x0, done
