# =====================================================================
# Programa 9 (E2) - Reagrupamiento tras emision parcial, orden de programa,
#                   ausencia de instrucciones perdidas o duplicadas y dos escrituras en el RF
# Objetivo:
#   - Cadena de instrucciones dependientes (x1): cada par tiene RAW interno, se emite solo la
#     via 1 y la via 2 se reagrupa como via 1 del par siguiente, ciclo tras ciclo.
#   - La cadena alterna "duplicar" y "sumar": el resultado SOLO es correcto si cada instruccion
#     se ejecuta exactamente una vez y en orden (una perdida, repeticion o reordenamiento
#     produce otro valor).
#   - x9 cuenta instrucciones intercaladas: debe valer exactamente 6.
#   - Pares independientes intermedios desplazan la alineacion (pares que empiezan en
#     direcciones multiplo de 8 y en direcciones impares de palabra).
#   - Dos escrituras simultaneas en el RF: a distintos registros (pares DUAL) y al mismo
#     registro (x10, gana la via 2).
# =====================================================================
        addi x20, x0, 64       # base de memoria
        addi x1, x0, 1         # x1 = 1
        addi x9, x0, 0         # contador = 0
        addi x2, x0, 0         # x2 = 0
        add  x1, x1, x1        # x1 = 2     cadena: RAW con la siguiente
        addi x1, x1, 1         # x1 = 3
        add  x1, x1, x1        # x1 = 6
        addi x1, x1, 1         # x1 = 7
        addi x9, x9, 1         # contador = 1 (independiente de x1)
        add  x1, x1, x1        # x1 = 14
        addi x1, x1, 1         # x1 = 15
        addi x2, x2, 5         # x2 = 5   (independiente)
        add  x1, x1, x1        # x1 = 30
        addi x9, x9, 1         # contador = 2
        addi x9, x9, 1         # contador = 3  (RAW con la anterior)
        addi x1, x1, 3         # x1 = 33
        addi x10, x0, 1        # par DUAL: dos escrituras al MISMO registro
        addi x10, x0, 2        #   en el mismo ciclo -> x10 = 2
        add  x1, x1, x1        # x1 = 66
        addi x9, x9, 1         # contador = 4
        add  x1, x1, x10       # x1 = 68   (x10 = 2: prioridad de la via 2)
        addi x2, x2, 7         # x2 = 12
        add  x1, x1, x1        # x1 = 136
        addi x9, x9, 1         # contador = 5
        addi x1, x1, -1        # x1 = 135
        addi x9, x9, 1         # contador = 6
        sw   x1, 0(x20)        # M[64] = 135
        sw   x9, 4(x20)        # M[68] = 6
        sw   x2, 8(x20)        # M[72] = 12
        sw   x10, 12(x20)      # M[76] = 2
done:   beq  x0, x0, done
