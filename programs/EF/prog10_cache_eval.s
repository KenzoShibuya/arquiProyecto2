# =====================================================================
# Programa 10 (EF) - Evaluacion de Cache de Datos L1 (Fully Associative,
#                    8 lineas, Write-Through + Write-Allocate, FIFO)
#                    y Emision Doble de Memoria (lw+lw, sw+lw, lw+sw)
#
# Fase 1 (Warm-up / Write-Allocate):
#   Inicializa dos vectores de 4 elementos en memoria:
#     A[0..3] en M[64..76] = [10, 20, 30, 40]
#     B[0..3] en M[80..92] = [ 2,  4,  6,  8]
#   Al ejecutar los 8 stores (emparejados con instrucciones ALU), las 8
#   lineas de la cache L1 quedan alojadas y validas.
#
# Fase 2 (Kernel vectorial iterativo - 3 iteraciones):
#   Calcula A[i] = A[i] + B[i] durante 3 iteraciones usando:
#   - Pares lw + lw (Doble Hit simultaneo en Cache L1, MemStall = 0)
#   - Pares sw + lw (Write-Through a dmem en Via 1 + Hit en L1 en Via 2)
#   - Pares add + add (Doble ALU)
#   Al finalizar las 3 iteraciones:
#     A[0..3] = [16, 32, 48, 64]
#
# Fase 3 (Casos especiales de la microarquitectura de cache):
#   1. Store-to-Load Bypass interno en el mismo par (sw + lw a M[96]):
#      Via 1 escribe 160 en M[96] y Via 2 lee M[96] en el mismo ciclo.
#   2. Par lw + sw (Hit en Via 1 leyendo M[68]=32 + Store en Via 2 a M[100]=50)
#      con reemplazo FIFO sobre cache llena.
#   3. Par lw + lw mixto (Hit en Via 1 + Cold Miss en Via 2 -> sin MemStall).
#   4. Par lw + lw con doble Cold Miss (M[108] y M[112] -> activa MemStall=1
#      por 1 ciclo para arbitrar el unico puerto de dmem).
# =====================================================================

        # --- Fase 1: Inicializacion y Warm-up (8 lineas en L1) ---
        addi x20, x0, 64       # 0x00: base M[64]
        addi x18, x0, 3        # 0x04: contador de iteraciones = 3
        addi x1,  x0, 10       # 0x08: A[0] = 10
        addi x2,  x0, 20       # 0x0c: A[1] = 20
        sw   x1,  0(x20)       # 0x10: M[64] = 10 (L1 linea 0)
        addi x3,  x0, 30       # 0x14: A[2] = 30
        sw   x2,  4(x20)       # 0x18: M[68] = 20 (L1 linea 1)
        addi x4,  x0, 40       # 0x1c: A[3] = 40
        sw   x3,  8(x20)       # 0x20: M[72] = 30 (L1 linea 2)
        addi x5,  x0, 2        # 0x24: B[0] = 2
        sw   x4,  12(x20)      # 0x28: M[76] = 40 (L1 linea 3)
        addi x6,  x0, 4        # 0x2c: B[1] = 4
        sw   x5,  16(x20)      # 0x30: M[80] = 2  (L1 linea 4)
        addi x7,  x0, 6        # 0x34: B[2] = 6
        sw   x6,  20(x20)      # 0x38: M[84] = 4  (L1 linea 5)
        addi x8,  x0, 8        # 0x3c: B[3] = 8
        sw   x7,  24(x20)      # 0x40: M[88] = 6  (L1 linea 6)
        addi x9,  x0, 0        # 0x44: acumulador = 0
        sw   x8,  28(x20)      # 0x48: M[92] = 8  (L1 linea 7)
        addi x10, x0, 0        # 0x4c: temporal = 0

        # --- Fase 2: Bucle vectorial con localidad temporal (3 iteraciones) ---
loop:
        lw   x1,  0(x20)       # 0x50: par v1 : LOAD A[0] (Hit L1)
        lw   x2,  16(x20)      # 0x54: par v2 : LOAD B[0] (Hit L1) -> DUAL lw+lw
        lw   x3,  4(x20)       # 0x58: par v1 : LOAD A[1] (Hit L1)
        lw   x4,  20(x20)      # 0x5c: par v2 : LOAD B[1] (Hit L1) -> DUAL lw+lw
        add  x1,  x1, x2       # 0x60: par v1 : A[0] += B[0]
        add  x3,  x3, x4       # 0x64: par v2 : A[1] += B[1]       -> DUAL ALU
        sw   x1,  0(x20)       # 0x68: par v1 : STORE A[0] (Write-Through)
        lw   x5,  8(x20)       # 0x6c: par v2 : LOAD A[2] (Hit L1) -> DUAL sw+lw
        sw   x3,  4(x20)       # 0x70: par v1 : STORE A[1] (Write-Through)
        lw   x6,  24(x20)      # 0x74: par v2 : LOAD B[2] (Hit L1) -> DUAL sw+lw
        lw   x7,  12(x20)      # 0x78: par v1 : LOAD A[3] (Hit L1)
        lw   x8,  28(x20)      # 0x7c: par v2 : LOAD B[3] (Hit L1) -> DUAL lw+lw
        add  x5,  x5, x6       # 0x80: par v1 : A[2] += B[2]
        add  x7,  x7, x8       # 0x84: par v2 : A[3] += B[3]       -> DUAL ALU
        sw   x5,  8(x20)       # 0x88: par v1 : STORE A[2]
        addi x18, x18, -1      # 0x8c: par v2 : iter--             -> DUAL sw+ALU
        sw   x7,  12(x20)      # 0x90: par v1 : STORE A[3]
        beq  x18, x0, post     # 0x94: par v2 : si iter == 0, sale -> DUAL sw+beq
        jal  x0,  loop         # 0x98: repite bucle
        addi x0,  x0, 0        # 0x9c: nop (bloqueado por jal en via 1)

        # --- Fase 3: Bypass Store-to-Load, lw+sw, reemplazo FIFO y MemStall ---
post:
        add  x9,  x1, x3       # 0xa0: par v1 : x9  = 16 + 32 = 48
        add  x10, x5, x7       # 0xa4: par v2 : x10 = 48 + 64 = 112
        add  x11, x9, x10      # 0xa8: par v1 : x11 = 48 + 112 = 160
        addi x12, x0, 50       # 0xac: par v2 : x12 = 50
        sw   x11, 32(x20)      # 0xb0: par v1 : M[96] = 160 (reemplazo FIFO linea 0)
        lw   x13, 32(x20)      # 0xb4: par v2 : x13 = M[96] = 160 (Store-to-Load bypass!)
        lw   x14, 4(x20)       # 0xb8: par v1 : x14 = M[68] = 32  (Hit L1 en linea 1)
        sw   x12, 36(x20)      # 0xbc: par v2 : M[100] = 50 (DUAL lw+sw, reemplazo FIFO linea 1)
        lw   x15, 8(x20)       # 0xc0: par v1 : x15 = M[72] = 48  (Hit L1 en linea 2)
        lw   x16, 40(x20)      # 0xc4: par v2 : x16 = M[104] = 0  (Hit + Cold Miss -> sin MemStall)
        lw   x17, 44(x20)      # 0xc8: par v1 : x17 = M[108] = 0  (Cold Miss en Via 1)
        lw   x19, 48(x20)      # 0xcc: par v2 : x19 = M[112] = 0  (Cold Miss en Via 2 -> MemStall = 1!)
        add  x21, x13, x14     # 0xd0: par v1 : x21 = 160 + 32 = 192
        add  x22, x15, x12     # 0xd4: par v2 : x22 = 48  + 50 = 98  (DUAL ALU)
        sw   x21, 40(x20)      # 0xd8: par v1 : M[104] = 192
        addi x23, x22, 2       # 0xdc: par v2 : x23 = 98 + 2 = 100   (DUAL sw+ALU)
        sw   x22, 44(x20)      # 0xe0: par v1 : M[108] = 98  (par sw+sw -> mem_conflict=1,
        sw   x23, 48(x20)      # 0xe4: par v2 : M[112] = 100  separa los dos stores)
done:   beq  x0,  x0, done     # 0xe8: bucle infinito de fin
