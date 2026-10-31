# =====================================================================
# Programa 4 - Flushing (control hazards)
# Objetivo: cuando un beq/jal se resuelve tomado en EX (PCSrcE = 1), las
#   2 instrucciones mas jovenes ya buscadas (en F y D) se anulan:
#   FlushD = FlushE = 1. Un beq NO tomado no anula nada.
#   Incluye: beq tomado hacia adelante, beq no tomado, jal hacia adelante
#   (con registro de enlace) y un bucle con jal hacia atras.
# =====================================================================
        addi x20, x0, 64       # base de memoria
        addi x1, x0, 4
        addi x2, x0, 4
        addi x3, x0, 0         # acumulador
        beq  x1, x2, t1        # TOMADO -> se anulan las 2 siguientes
        addi x3, x3, 100       # anulada
        addi x3, x3, 200       # anulada
t1:     addi x3, x3, 1         # x3 = 1
        beq  x1, x0, nt        # NO tomado (4 != 0): no hay flush
        addi x3, x3, 2         # se ejecuta -> x3 = 3
nt:     jal  x5, fwd           # TOMADO, x5 = PC+4 = 44 (0x2C)
        addi x3, x3, 500       # anulada
        addi x3, x3, 600       # anulada
fwd:    addi x6, x0, 3         # contador
        addi x7, x0, 0         # suma
loop:   beq  x6, x0, end       # sale cuando x6 = 0
        add  x7, x7, x6        # suma += contador
        addi x6, x6, -1        # contador--
        jal  x0, loop          # salto hacia atras (flush en cada vuelta)
        addi x7, x7, 1000      # nunca debe ejecutarse
end:    sw   x3, 0(x20)        # M[64] = 3
        sw   x5, 4(x20)        # M[68] = 44
        sw   x7, 8(x20)        # M[72] = 6  (3 + 2 + 1)
        sw   x6, 12(x20)       # M[76] = 0
done:   beq  x0, x0, done
