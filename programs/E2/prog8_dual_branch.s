# =====================================================================
# Programa 8 (E2) - Branches en ambas posiciones del par y flushing selectivo
# Objetivo:
#   - beq en la via 1 TOMADO: se anula la via 2 del mismo par (mas joven, FlushM2)
#     y las instrucciones buscadas detras (FlushD/FlushE).
#   - beq en la via 1 NO tomado: la via 2 del par se ejecuta normalmente.
#   - beq en la via 2 TOMADO: la via 1 (mas antigua) se CONSERVA; se anulan las mas jovenes.
#   - beq en la via 2 NO tomado.
#   - Dos saltos en el mismo par: un solo recurso de saltos -> solo se emite la via 1.
#   - jal en la via 1 (no se emite la via 2) y jal en la via 2 (la via 1 se conserva),
#     con registro de enlace correcto.
#   - Bucle con salto hacia atras desde la via 2.
# Cada instruccion "anulada" suma 100..1000 a x3: si algun flush falla, M[64] != 15.
# =====================================================================
        addi x20, x0, 64       # base de memoria
        addi x1, x0, 4
        addi x2, x0, 4
        addi x3, x0, 0         # acumulador de control
        beq  x1, x2, t1        # par v1 : beq TOMADO en via 1 ...
        addi x3, x3, 100       # par v2 : ... la via 2 (mas joven) se ANULA
        addi x3, x3, 200       # anulada (camino incorrecto)
t1:     addi x3, x3, 1         # par v1 : x3 = 1
        beq  x1, x0, n1        # par v2 : beq NO tomado en via 2
n1:     beq  x1, x0, n2        # par v1 : beq NO tomado en via 1 ...
n2:     addi x3, x3, 2         # par v2 : ... la via 2 se ejecuta -> x3 = 3
        addi x3, x3, 4         # par v1 : la via 1 (mas antigua) se CONSERVA -> x3 = 7
        beq  x1, x2, t2        # par v2 : beq TOMADO en via 2
        addi x3, x3, 400       # anulada
        addi x3, x3, 500       # anulada
t2:     beq  x1, x0, n3        # par v1 : dos saltos en el mismo par -> conflicto de control,
n3:     beq  x1, x2, t3        # par v2 :   solo se emite la via 1; el segundo se reagrupa (TOMADO)
        addi x3, x3, 600       # anulada
t3:     jal  x5, t4            # par v1 : jal en via 1 -> la via 2 no se emite; x5 = PC+4 = 0x4C
        addi x3, x3, 700       # anulada
        addi x3, x3, 800       # anulada
t4:     addi x3, x3, 8         # par v1 : la via 1 se CONSERVA -> x3 = 15
        jal  x6, t5            # par v2 : jal en via 2 ; x6 = PC+4 = 0x5C
        addi x3, x3, 900       # anulada
        addi x3, x3, 1000      # anulada
t5:     addi x7, x0, 3         # contador del bucle
        addi x8, x0, 0         # suma
loop:   beq  x7, x0, end       # par v1 : sale del bucle cuando x7 = 0
        add  x8, x8, x7        # par v2 : suma += contador
        addi x7, x7, -1        # par v1
        jal  x0, loop          # par v2 : salto hacia atras desde la via 2
        addi x8, x8, 1000      # nunca se ejecuta
end:    sw   x3, 0(x20)        # M[64] = 15
        sw   x5, 4(x20)        # M[68] = 0x4C (76)
        sw   x6, 8(x20)        # M[72] = 0x5C (92)
        sw   x8, 12(x20)       # M[76] = 6 (3 + 2 + 1)
        sw   x7, 16(x20)       # M[80] = 0
done:   beq  x0, x0, done
