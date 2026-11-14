`timescale 1ns/1ps

// ============================================================================
// Testbench Oficial para Entrega Final (EF) - Programa-proyecto.pdf
//   Archivo de programa: prog_ef_oficial.mem
//   Direccion base     : x1 = 1536 (0x600 -> dmem.RAM[384..397])
//   Etapas verificadas :
//     - Etapa A (fin en PC = 0x034: sw x10, 8(x1))  -> pulso check_etapa_A
//     - Etapa B (fin en PC = 0x060: sw x18, 20(x1)) -> pulso check_etapa_B
//     - Etapa C (fin en PC = 0x0e0: sw x24, 32(x1)) -> pulso check_etapa_C
//     - Etapa D (fin en PC = 0x160: sw x31, 52(x1)) -> pulso check_etapa_D
//     - Loop fin (PC = 0x164: jal x0, fin)          -> detiene conteo util
//
//   Top-levels disponibles para simulacion:
//     1. tb_ef_oficial_compare    : Corre las 3 versiones en paralelo
//                                   (Pipeline E1, Dual-Issue E2, Optimizado EF),
//                                   verifica las 4 etapas y la tabla final.
//     2. tb_ef_oficial_optimizado : Corre solo la version Optimizada (EF)
//     3. tb_ef_oficial_dual       : Corre solo la version Dual-Issue (E2)
//     4. tb_ef_oficial_pipeline   : Corre solo la version Pipeline (E1)
// ============================================================================

module tb_ef_oficial_core #(
    parameter MEM_FILE      = "prog_ef_oficial.mem",
    parameter ENABLE_DCACHE = 1,
    parameter SINGLE_ISSUE  = 0,
    parameter [31:0] PC_ETAPA_A = 32'h00000034,
    parameter [31:0] PC_ETAPA_B = 32'h00000060,
    parameter [31:0] PC_ETAPA_C = 32'h000000e0,
    parameter [31:0] PC_ETAPA_D = 32'h00000160,
    parameter [31:0] DONE_PC    = 32'h00000164,
    parameter [31:0] FIRST0     = 32'h60000093, // addi x1, x0, 1536
    parameter [31:0] FIRST1     = 32'h00100113  // addi x2, x0, 1
);
    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    top #(
        .MEM_FILE(MEM_FILE),
        .ENABLE_DCACHE(ENABLE_DCACHE),
        .SINGLE_ISSUE(SINGLE_ISSUE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // ------------------------------------------------------------------------
    // Senales de Pipeline (IF, ID, EX, MEM, WB) y Cache L1
    // ------------------------------------------------------------------------
    wire [31:0] PCF     = dut.PC;
    wire [31:0] InstrF  = dut.Instr;
    wire [31:0] InstrF2 = dut.Instr2;
    wire [31:0] InstrD  = dut.rvpipe.InstrD;
    wire [31:0] InstrD2 = dut.rvpipe.InstrD2;
    wire [31:0] PCD     = dut.rvpipe.dp.PCD;
    wire [31:0] PCD2    = dut.rvpipe.dp.PCD2;

    wire IssueSlot2D     = dut.rvpipe.IssueSlot2D;
    wire PCInc8F         = dut.rvpipe.PCInc8F;
    wire raw_conflict    = dut.rvpipe.iu.raw_hazard;
    wire mem_conflict    = dut.rvpipe.iu.mem_conflict;
    wire ctrl_conflict   = dut.rvpipe.iu.ctrl_conflict;
    wire lw_hazard_slot2 = dut.rvpipe.iu.lw_hazard_slot2;

    wire StallF   = dut.rvpipe.StallF;
    wire StallD   = dut.rvpipe.StallD;
    wire FlushD   = dut.rvpipe.FlushD;
    wire FlushE   = dut.rvpipe.FlushE;
    wire FlushM2  = dut.rvpipe.FlushM2;
    wire MemStall = dut.rvpipe.MemStall;

    wire [31:0] PCE        = dut.rvpipe.dp.PCE;
    wire [31:0] PCE2       = dut.rvpipe.dp.PCE2;
    wire [31:0] ALUResultE = dut.rvpipe.dp.ALUResultE;
    wire [31:0] ALUResultE2= dut.rvpipe.dp.ALUResultE2;
    wire PCSrcE            = dut.rvpipe.PCSrcE;
    wire PCSrcE1           = dut.rvpipe.PCSrcE1;
    wire PCSrcE2           = dut.rvpipe.dp.PCSrcE2;

    wire        MemReadM         = dut.rvpipe.MemReadM;
    wire        MemWriteM        = dut.rvpipe.MemWriteM;
    wire [31:0] ALUResultM       = dut.rvpipe.ALUResultM;
    wire [31:0] WriteDataM       = dut.rvpipe.WriteDataM;
    wire [31:0] ReadDataM_cache  = dut.rvpipe.ReadDataM_cache;
    wire        MemReadM2        = dut.rvpipe.MemReadM2;
    wire        MemWriteM2       = dut.rvpipe.MemWriteM2;
    wire [31:0] ALUResultM2      = dut.rvpipe.ALUResultM2;
    wire [31:0] WriteDataM2      = dut.rvpipe.WriteDataM2;
    wire [31:0] ReadDataM2_cache = dut.rvpipe.ReadDataM2_cache;

    wire        hit1            = dut.rvpipe.dc.hit1;
    wire        hit2            = dut.rvpipe.dc.hit2;
    wire        st_to_ld_bypass = dut.rvpipe.dc.st_to_ld_bypass;
    wire [31:0] cache_accesses  = dut.rvpipe.dc.cache_accesses;
    wire [31:0] cache_hits      = dut.rvpipe.dc.cache_hits;
    wire [31:0] cache_misses    = dut.rvpipe.dc.cache_misses;
    wire [31:0] dual_mem_pairs  = dut.rvpipe.dc.dual_mem_pairs;

    // ------------------------------------------------------------------------
    // Registros x1..x31 (para inspeccion directa en el waveform viewer)
    // ------------------------------------------------------------------------
    wire [31:0] x1  = dut.rvpipe.dp.rf.rf[1];
    wire [31:0] x2  = dut.rvpipe.dp.rf.rf[2];
    wire [31:0] x3  = dut.rvpipe.dp.rf.rf[3];
    wire [31:0] x4  = dut.rvpipe.dp.rf.rf[4];
    wire [31:0] x5  = dut.rvpipe.dp.rf.rf[5];
    wire [31:0] x6  = dut.rvpipe.dp.rf.rf[6];
    wire [31:0] x7  = dut.rvpipe.dp.rf.rf[7];
    wire [31:0] x8  = dut.rvpipe.dp.rf.rf[8];
    wire [31:0] x9  = dut.rvpipe.dp.rf.rf[9];
    wire [31:0] x10 = dut.rvpipe.dp.rf.rf[10];
    wire [31:0] x11 = dut.rvpipe.dp.rf.rf[11];
    wire [31:0] x12 = dut.rvpipe.dp.rf.rf[12];
    wire [31:0] x13 = dut.rvpipe.dp.rf.rf[13];
    wire [31:0] x14 = dut.rvpipe.dp.rf.rf[14];
    wire [31:0] x15 = dut.rvpipe.dp.rf.rf[15];
    wire [31:0] x16 = dut.rvpipe.dp.rf.rf[16];
    wire [31:0] x17 = dut.rvpipe.dp.rf.rf[17];
    wire [31:0] x18 = dut.rvpipe.dp.rf.rf[18];
    wire [31:0] x19 = dut.rvpipe.dp.rf.rf[19];
    wire [31:0] x20 = dut.rvpipe.dp.rf.rf[20];
    wire [31:0] x21 = dut.rvpipe.dp.rf.rf[21];
    wire [31:0] x22 = dut.rvpipe.dp.rf.rf[22];
    wire [31:0] x23 = dut.rvpipe.dp.rf.rf[23];
    wire [31:0] x24 = dut.rvpipe.dp.rf.rf[24];
    wire [31:0] x25 = dut.rvpipe.dp.rf.rf[25];
    wire [31:0] x26 = dut.rvpipe.dp.rf.rf[26];
    wire [31:0] x27 = dut.rvpipe.dp.rf.rf[27];
    wire [31:0] x28 = dut.rvpipe.dp.rf.rf[28];
    wire [31:0] x29 = dut.rvpipe.dp.rf.rf[29];
    wire [31:0] x30 = dut.rvpipe.dp.rf.rf[30];
    wire [31:0] x31 = dut.rvpipe.dp.rf.rf[31];

    // ------------------------------------------------------------------------
    // Memoria de datos M[x1+0] .. M[x1+52] (x1 = 1536 -> word index 384..397)
    // ------------------------------------------------------------------------
    wire [31:0] M_x1_0  = dut.dmem.RAM[384]; // 0(x1)  = M[1536]
    wire [31:0] M_x1_4  = dut.dmem.RAM[385]; // 4(x1)  = M[1540]
    wire [31:0] M_x1_8  = dut.dmem.RAM[386]; // 8(x1)  = M[1544]
    wire [31:0] M_x1_12 = dut.dmem.RAM[387]; // 12(x1) = M[1548]
    wire [31:0] M_x1_16 = dut.dmem.RAM[388]; // 16(x1) = M[1552]
    wire [31:0] M_x1_20 = dut.dmem.RAM[389]; // 20(x1) = M[1556]
    wire [31:0] M_x1_24 = dut.dmem.RAM[390]; // 24(x1) = M[1560]
    wire [31:0] M_x1_28 = dut.dmem.RAM[391]; // 28(x1) = M[1564]
    wire [31:0] M_x1_32 = dut.dmem.RAM[392]; // 32(x1) = M[1568]
    wire [31:0] M_x1_36 = dut.dmem.RAM[393]; // 36(x1) = M[1572]
    wire [31:0] M_x1_40 = dut.dmem.RAM[394]; // 40(x1) = M[1576]
    wire [31:0] M_x1_44 = dut.dmem.RAM[395]; // 44(x1) = M[1580]
    wire [31:0] M_x1_48 = dut.dmem.RAM[396]; // 48(x1) = M[1584]
    wire [31:0] M_x1_52 = dut.dmem.RAM[397]; // 52(x1) = M[1588]

    // ------------------------------------------------------------------------
    // Seguimiento de instrucciones retiradas en WB (sin modificar el RTL)
    // ------------------------------------------------------------------------
    reg        validE1, validE2, validM1, validM2, validW1, validW2;
    reg [31:0] PCM1, PCM2, PCW1, PCW2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            validE1 <= 1'b0;
            validE2 <= 1'b0;
            validM1 <= 1'b0;
            validM2 <= 1'b0;
            validW1 <= 1'b0;
            validW2 <= 1'b0;
            PCM1    <= 32'b0;
            PCM2    <= 32'b0;
            PCW1    <= 32'b0;
            PCW2    <= 32'b0;
        end else if (!MemStall) begin
            validE1 <= FlushE  ? 1'b0 : (InstrD != 32'b0);
            validE2 <= FlushE  ? 1'b0 : (IssueSlot2D && (InstrD2 != 32'b0));
            validM1 <= validE1;
            validM2 <= FlushM2 ? 1'b0 : validE2;
            PCM1    <= PCE;
            PCM2    <= PCE2;
            validW1 <= validM1;
            validW2 <= validM2;
            PCW1    <= PCM1;
            PCW2    <= PCM2;
        end
    end

    // Pulsos de finalizacion de cada etapa (activos exactamente en el ciclo
    // donde el ultimo 'sw' de la etapa se retira en WB).
    // Colocar el cursor del waveform en el flanco de subida de cualquiera de
    // estas 4 senales permite verificar directamente la tabla del PDF.
    wire check_etapa_A = !reset && !MemStall && ((validW1 && PCW1 == PC_ETAPA_A) || (validW2 && PCW2 == PC_ETAPA_A));
    wire check_etapa_B = !reset && !MemStall && ((validW1 && PCW1 == PC_ETAPA_B) || (validW2 && PCW2 == PC_ETAPA_B));
    wire check_etapa_C = !reset && !MemStall && ((validW1 && PCW1 == PC_ETAPA_C) || (validW2 && PCW2 == PC_ETAPA_C));
    wire check_etapa_D = !reset && !MemStall && ((validW1 && PCW1 == PC_ETAPA_D) || (validW2 && PCW2 == PC_ETAPA_D));

    reg ok_etapa_A, ok_etapa_B, ok_etapa_C, ok_etapa_D;
    integer ciclo_etapa_A, ciclo_etapa_B, ciclo_etapa_C, ciclo_etapa_D;
    integer err_etapa_A, err_etapa_B, err_etapa_C, err_etapa_D;

    integer ciclos, ciclos_totales, instr_retiradas;
    integer dual_issue, single_issue;
    integer raw_conflicts, mem_conflicts, ctrl_conflicts;
    integer stalls, mem_stalls, flushes;
    integer done_seen, fin_wb_seen, errores, finalizado;

    initial begin
        reset = 1;
        ok_etapa_A = 0; ok_etapa_B = 0; ok_etapa_C = 0; ok_etapa_D = 0;
        ciclo_etapa_A = 0; ciclo_etapa_B = 0; ciclo_etapa_C = 0; ciclo_etapa_D = 0;
        err_etapa_A = 0; err_etapa_B = 0; err_etapa_C = 0; err_etapa_D = 0;
        ciclos = 0;
        ciclos_totales = 0;
        instr_retiradas = 0;
        dual_issue = 0;
        single_issue = 0;
        raw_conflicts = 0;
        mem_conflicts = 0;
        ctrl_conflicts = 0;
        stalls = 0;
        mem_stalls = 0;
        flushes = 0;
        done_seen = 0;
        fin_wb_seen = 0;
        errores = 0;
        finalizado = 0;

        #1;
        if ((dut.imem.RAM[0] !== FIRST0) || (dut.imem.RAM[1] !== FIRST1)) begin
            errores = errores + 1;
            finalizado = 1;
        end
        #21;
        reset = 0;
    end

    always @(posedge clk) begin
        if (!reset && !finalizado) begin
            ciclos = ciclos + 1;

            if (!fin_wb_seen) begin
                if (StallF)   stalls     = stalls     + 1;
                if (MemStall) mem_stalls = mem_stalls + 1;
            end

            // Conteo de instrucciones retiradas y ciclos utiles (sin contar 'fin' en 0x164)
            if (!MemStall && !fin_wb_seen) begin
                if (validM1 && (PCM1 != DONE_PC))
                    instr_retiradas = instr_retiradas + 1;
                if (validM2 && (PCM2 != DONE_PC))
                    instr_retiradas = instr_retiradas + 1;
                if ((validM1 && PCM1 == PC_ETAPA_D) || (validM2 && PCM2 == PC_ETAPA_D)) begin
                    // En este flanco la ultima instruccion antes de 'fin' (0x160: sw x31, 52(x1))
                    // pasa de MEM a WB (su escritura en memoria queda completada).
                    ciclos_totales = ciclos;
                    fin_wb_seen    = 1;
                end
            end

            if (!MemStall && (done_seen == 0)) begin
                if (!FlushE && !StallD && IssueSlot2D && (InstrD != 0) && (InstrD2 != 0))
                    dual_issue = dual_issue + 1;
                if (!FlushE && !StallD && !IssueSlot2D && (InstrD != 0))
                    single_issue = single_issue + 1;
                if (!StallD && (InstrD != 0) && (InstrD2 != 0)) begin
                    if (raw_conflict)  raw_conflicts  = raw_conflicts  + 1;
                    if (mem_conflict)  mem_conflicts  = mem_conflicts  + 1;
                    if (ctrl_conflict) ctrl_conflicts = ctrl_conflicts + 1;
                end
                if (FlushD)   flushes    = flushes    + 1;
            end

            if (!MemStall && ((PCSrcE1 && PCE == DONE_PC) || (PCSrcE2 && PCE2 == DONE_PC)))
                done_seen = done_seen + 1;
        end
    end

    // Verificacion automatica de los estados de referencia de las 4 etapas
    // definidos en Programa-proyecto.pdf (Seccion 3)
    always @(negedge clk) begin
        if (!reset && !finalizado) begin
            // ----------------------------------------------------------------
            // 3.1 Fin de Etapa A
            // x1=1536, x2=1, x3=8, x4=3, x5=11, x6=5, x7=16, x8=2, x9=7, x10=12
            // M[x1+0]=11, M[x1+4]=5, M[x1+8]=12
            // ----------------------------------------------------------------
            if (check_etapa_A) begin
                ciclo_etapa_A = ciclos;
                if (x1  !== 32'd1536) err_etapa_A = err_etapa_A + 1;
                if (x2  !== 32'd1)    err_etapa_A = err_etapa_A + 1;
                if (x3  !== 32'd8)    err_etapa_A = err_etapa_A + 1;
                if (x4  !== 32'd3)    err_etapa_A = err_etapa_A + 1;
                if (x5  !== 32'd11)   err_etapa_A = err_etapa_A + 1;
                if (x6  !== 32'd5)    err_etapa_A = err_etapa_A + 1;
                if (x7  !== 32'd16)   err_etapa_A = err_etapa_A + 1;
                if (x8  !== 32'd2)    err_etapa_A = err_etapa_A + 1;
                if (x9  !== 32'd7)    err_etapa_A = err_etapa_A + 1;
                if (x10 !== 32'd12)   err_etapa_A = err_etapa_A + 1;
                if (M_x1_0 !== 32'd11) err_etapa_A = err_etapa_A + 1;
                if (M_x1_4 !== 32'd5)  err_etapa_A = err_etapa_A + 1;
                if (M_x1_8 !== 32'd12) err_etapa_A = err_etapa_A + 1;
                if (err_etapa_A == 0) ok_etapa_A = 1'b1;
                errores = errores + err_etapa_A;
            end

            // ----------------------------------------------------------------
            // 3.2 Fin de Etapa B (incluye preservacion de Etapa A)
            // x11=11, x12=16, x13=5, x14=12, x15=7, x16=7, x17=16, x18=23
            // M[x1+0]=11, M[x1+4]=5, M[x1+8]=12, M[x1+12]=7, M[x1+16]=16, M[x1+20]=23
            // ----------------------------------------------------------------
            if (check_etapa_B) begin
                ciclo_etapa_B = ciclos;
                if (x1  !== 32'd1536) err_etapa_B = err_etapa_B + 1;
                if (x2  !== 32'd1)    err_etapa_B = err_etapa_B + 1;
                if (x3  !== 32'd8)    err_etapa_B = err_etapa_B + 1;
                if (x4  !== 32'd3)    err_etapa_B = err_etapa_B + 1;
                if (x5  !== 32'd11)   err_etapa_B = err_etapa_B + 1;
                if (x6  !== 32'd5)    err_etapa_B = err_etapa_B + 1;
                if (x7  !== 32'd16)   err_etapa_B = err_etapa_B + 1;
                if (x8  !== 32'd2)    err_etapa_B = err_etapa_B + 1;
                if (x9  !== 32'd7)    err_etapa_B = err_etapa_B + 1;
                if (x10 !== 32'd12)   err_etapa_B = err_etapa_B + 1;
                if (x11 !== 32'd11)   err_etapa_B = err_etapa_B + 1;
                if (x12 !== 32'd16)   err_etapa_B = err_etapa_B + 1;
                if (x13 !== 32'd5)    err_etapa_B = err_etapa_B + 1;
                if (x14 !== 32'd12)   err_etapa_B = err_etapa_B + 1;
                if (x15 !== 32'd7)    err_etapa_B = err_etapa_B + 1;
                if (x16 !== 32'd7)    err_etapa_B = err_etapa_B + 1;
                if (x17 !== 32'd16)   err_etapa_B = err_etapa_B + 1;
                if (x18 !== 32'd23)   err_etapa_B = err_etapa_B + 1;
                if (M_x1_0  !== 32'd11) err_etapa_B = err_etapa_B + 1;
                if (M_x1_4  !== 32'd5)  err_etapa_B = err_etapa_B + 1;
                if (M_x1_8  !== 32'd12) err_etapa_B = err_etapa_B + 1;
                if (M_x1_12 !== 32'd7)  err_etapa_B = err_etapa_B + 1;
                if (M_x1_16 !== 32'd16) err_etapa_B = err_etapa_B + 1;
                if (M_x1_20 !== 32'd23) err_etapa_B = err_etapa_B + 1;
                if (err_etapa_B == 0) ok_etapa_B = 1'b1;
                errores = errores + err_etapa_B;
            end

            // ----------------------------------------------------------------
            // 3.3 Fin de Etapa C
            // x19=12, x20=12, x21=24, x22=18, x23=0, x24=24, x25=0, x26=6
            // M[x1+24]=24, M[x1+28]=18, M[x1+32]=24
            // ----------------------------------------------------------------
            if (check_etapa_C) begin
                ciclo_etapa_C = ciclos;
                if (x19 !== 32'd12) err_etapa_C = err_etapa_C + 1;
                if (x20 !== 32'd12) err_etapa_C = err_etapa_C + 1;
                if (x21 !== 32'd24) err_etapa_C = err_etapa_C + 1;
                if (x22 !== 32'd18) err_etapa_C = err_etapa_C + 1;
                if (x23 !== 32'd0)  err_etapa_C = err_etapa_C + 1;
                if (x24 !== 32'd24) err_etapa_C = err_etapa_C + 1;
                if (x25 !== 32'd0)  err_etapa_C = err_etapa_C + 1;
                if (x26 !== 32'd6)  err_etapa_C = err_etapa_C + 1;
                if (M_x1_0  !== 32'd11) err_etapa_C = err_etapa_C + 1;
                if (M_x1_4  !== 32'd5)  err_etapa_C = err_etapa_C + 1;
                if (M_x1_8  !== 32'd12) err_etapa_C = err_etapa_C + 1;
                if (M_x1_12 !== 32'd7)  err_etapa_C = err_etapa_C + 1;
                if (M_x1_16 !== 32'd16) err_etapa_C = err_etapa_C + 1;
                if (M_x1_20 !== 32'd23) err_etapa_C = err_etapa_C + 1;
                if (M_x1_24 !== 32'd24) err_etapa_C = err_etapa_C + 1;
                if (M_x1_28 !== 32'd18) err_etapa_C = err_etapa_C + 1;
                if (M_x1_32 !== 32'd24) err_etapa_C = err_etapa_C + 1;
                if (err_etapa_C == 0) ok_etapa_C = 1'b1;
                errores = errores + err_etapa_C;
            end

            // ----------------------------------------------------------------
            // 3.4 Fin de Etapa D (Estado final completo de registros y memoria)
            // x19=6, x20=6, x21=24, x22=18, x24=24, x25=4, x26=4, x27=1560,
            // x28=74, x29=4, x30=23, x31=1
            // M[x1+36]=74, M[x1+40]=4, M[x1+44]=0, M[x1+48]=1, M[x1+52]=1
            // ----------------------------------------------------------------
            if (check_etapa_D) begin
                ciclo_etapa_D = ciclos;
                if (x1  !== 32'd1536) err_etapa_D = err_etapa_D + 1;
                if (x2  !== 32'd1)    err_etapa_D = err_etapa_D + 1;
                if (x3  !== 32'd8)    err_etapa_D = err_etapa_D + 1;
                if (x4  !== 32'd3)    err_etapa_D = err_etapa_D + 1;
                if (x5  !== 32'd11)   err_etapa_D = err_etapa_D + 1;
                if (x6  !== 32'd5)    err_etapa_D = err_etapa_D + 1;
                if (x7  !== 32'd16)   err_etapa_D = err_etapa_D + 1;
                if (x8  !== 32'd2)    err_etapa_D = err_etapa_D + 1;
                if (x9  !== 32'd7)    err_etapa_D = err_etapa_D + 1;
                if (x10 !== 32'd12)   err_etapa_D = err_etapa_D + 1;
                if (x11 !== 32'd11)   err_etapa_D = err_etapa_D + 1;
                if (x12 !== 32'd16)   err_etapa_D = err_etapa_D + 1;
                if (x13 !== 32'd5)    err_etapa_D = err_etapa_D + 1;
                if (x14 !== 32'd12)   err_etapa_D = err_etapa_D + 1;
                if (x15 !== 32'd7)    err_etapa_D = err_etapa_D + 1;
                if (x16 !== 32'd7)    err_etapa_D = err_etapa_D + 1;
                if (x17 !== 32'd16)   err_etapa_D = err_etapa_D + 1;
                if (x18 !== 32'd23)   err_etapa_D = err_etapa_D + 1;
                if (x19 !== 32'd6)    err_etapa_D = err_etapa_D + 1;
                if (x20 !== 32'd6)    err_etapa_D = err_etapa_D + 1;
                if (x21 !== 32'd24)   err_etapa_D = err_etapa_D + 1;
                if (x22 !== 32'd18)   err_etapa_D = err_etapa_D + 1;
                if (x23 !== 32'd0)    err_etapa_D = err_etapa_D + 1;
                if (x24 !== 32'd24)   err_etapa_D = err_etapa_D + 1;
                if (x25 !== 32'd4)    err_etapa_D = err_etapa_D + 1;
                if (x26 !== 32'd4)    err_etapa_D = err_etapa_D + 1;
                if (x27 !== 32'd1560) err_etapa_D = err_etapa_D + 1;
                if (x28 !== 32'd74)   err_etapa_D = err_etapa_D + 1;
                if (x29 !== 32'd4)    err_etapa_D = err_etapa_D + 1;
                if (x30 !== 32'd23)   err_etapa_D = err_etapa_D + 1;
                if (x31 !== 32'd1)    err_etapa_D = err_etapa_D + 1;
                if (M_x1_0  !== 32'd11) err_etapa_D = err_etapa_D + 1;
                if (M_x1_4  !== 32'd5)  err_etapa_D = err_etapa_D + 1;
                if (M_x1_8  !== 32'd12) err_etapa_D = err_etapa_D + 1;
                if (M_x1_12 !== 32'd7)  err_etapa_D = err_etapa_D + 1;
                if (M_x1_16 !== 32'd16) err_etapa_D = err_etapa_D + 1;
                if (M_x1_20 !== 32'd23) err_etapa_D = err_etapa_D + 1;
                if (M_x1_24 !== 32'd24) err_etapa_D = err_etapa_D + 1;
                if (M_x1_28 !== 32'd18) err_etapa_D = err_etapa_D + 1;
                if (M_x1_32 !== 32'd24) err_etapa_D = err_etapa_D + 1;
                if (M_x1_36 !== 32'd74) err_etapa_D = err_etapa_D + 1;
                if (M_x1_40 !== 32'd4)  err_etapa_D = err_etapa_D + 1;
                if (M_x1_44 !== 32'd0)  err_etapa_D = err_etapa_D + 1;
                if (M_x1_48 !== 32'd1)  err_etapa_D = err_etapa_D + 1;
                if (M_x1_52 !== 32'd1)  err_etapa_D = err_etapa_D + 1;
                if (err_etapa_D == 0) ok_etapa_D = 1'b1;
                errores = errores + err_etapa_D;
            end

            if (done_seen >= 3) begin
                if (!ok_etapa_A || !ok_etapa_B || !ok_etapa_C || !ok_etapa_D)
                    errores = errores + 1;
                finalizado = 1;
            end else if (ciclos > 2000) begin
                errores = errores + 1;
                finalizado = 1;
            end
        end
    end
endmodule

// ============================================================================
// Top-levels individuales para inspeccion de cada arquitectura por separado
// ============================================================================
module tb_ef_oficial_optimizado;
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(1), .SINGLE_ISSUE(0)) u();
endmodule

module tb_ef_oficial_dual;
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(0)) u();
endmodule

module tb_ef_oficial_pipeline;
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(1)) u();
endmodule

// ============================================================================
// Top-level comparativo oficial: ejecuta las 3 arquitecturas en paralelo,
// verifica equivalencia funcional en las 4 etapas y genera la tabla del PDF
// ============================================================================
module tb_ef_oficial_compare;
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(1)) cfg_pipeline();
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(0), .SINGLE_ISSUE(0)) cfg_dual_issue();
    tb_ef_oficial_core #(.MEM_FILE("prog_ef_oficial.mem"), .ENABLE_DCACHE(1), .SINGLE_ISSUE(0)) cfg_optimizado();

    // Senales de resumen en el top-level para el waveform viewer
    wire [31:0] ciclos_pipeline   = cfg_pipeline.ciclos_totales;
    wire [31:0] ciclos_dual_issue = cfg_dual_issue.ciclos_totales;
    wire [31:0] ciclos_optimizado = cfg_optimizado.ciclos_totales;

    wire [31:0] instr_pipeline    = cfg_pipeline.instr_retiradas;
    wire [31:0] instr_dual_issue  = cfg_dual_issue.instr_retiradas;
    wire [31:0] instr_optimizado  = cfg_optimizado.instr_retiradas;

    wire [31:0] mem_conf_dual     = cfg_dual_issue.mem_conflicts;
    wire [31:0] mem_conf_opt      = cfg_optimizado.mem_conflicts;
    wire [31:0] mem_stalls_opt    = cfg_optimizado.mem_stalls;
    wire [31:0] cache_hits_opt    = cfg_optimizado.cache_hits;
    wire [31:0] cache_acc_opt     = cfg_optimizado.cache_accesses;
    wire [31:0] dual_mem_opt      = cfg_optimizado.dual_mem_pairs;

    integer idx, diff_errors;
    wire all_ok = cfg_pipeline.finalizado && cfg_dual_issue.finalizado && cfg_optimizado.finalizado &&
                  (cfg_pipeline.errores == 0) && (cfg_dual_issue.errores == 0) && (cfg_optimizado.errores == 0) &&
                  (diff_errors == 0);

    initial begin
        diff_errors = 0;
        wait(cfg_pipeline.finalizado && cfg_dual_issue.finalizado && cfg_optimizado.finalizado);
        #1;
        for (idx = 0; idx < 512; idx = idx + 1) begin
            if (cfg_pipeline.dut.dmem.RAM[idx] !== cfg_dual_issue.dut.dmem.RAM[idx] ||
                cfg_dual_issue.dut.dmem.RAM[idx] !== cfg_optimizado.dut.dmem.RAM[idx])
                diff_errors = diff_errors + 1;
        end
        for (idx = 1; idx < 32; idx = idx + 1) begin
            if (cfg_pipeline.dut.rvpipe.dp.rf.rf[idx] !== cfg_dual_issue.dut.rvpipe.dp.rf.rf[idx] ||
                cfg_dual_issue.dut.rvpipe.dp.rf.rf[idx] !== cfg_optimizado.dut.rvpipe.dp.rf.rf[idx])
                diff_errors = diff_errors + 1;
        end

        $display("================================================================================");
        $display(" RESULTADOS OFICIALES ENTREGA FINAL (EF) - Programa-proyecto.pdf");
        $display("================================================================================");
        $display(" Verificacion por Etapas (A, B, C, D):");
        $display("   Pipeline (E1)   : A=%0d(ok=%0b) B=%0d(ok=%0b) C=%0d(ok=%0b) D=%0d(ok=%0b)",
                 cfg_pipeline.ciclo_etapa_A, cfg_pipeline.ok_etapa_A,
                 cfg_pipeline.ciclo_etapa_B, cfg_pipeline.ok_etapa_B,
                 cfg_pipeline.ciclo_etapa_C, cfg_pipeline.ok_etapa_C,
                 cfg_pipeline.ciclo_etapa_D, cfg_pipeline.ok_etapa_D);
        $display("   Dual-Issue (E2) : A=%0d(ok=%0b) B=%0d(ok=%0b) C=%0d(ok=%0b) D=%0d(ok=%0b)",
                 cfg_dual_issue.ciclo_etapa_A, cfg_dual_issue.ok_etapa_A,
                 cfg_dual_issue.ciclo_etapa_B, cfg_dual_issue.ok_etapa_B,
                 cfg_dual_issue.ciclo_etapa_C, cfg_dual_issue.ok_etapa_C,
                 cfg_dual_issue.ciclo_etapa_D, cfg_dual_issue.ok_etapa_D);
        $display("   Optimizado (EF) : A=%0d(ok=%0b) B=%0d(ok=%0b) C=%0d(ok=%0b) D=%0d(ok=%0b)",
                 cfg_optimizado.ciclo_etapa_A, cfg_optimizado.ok_etapa_A,
                 cfg_optimizado.ciclo_etapa_B, cfg_optimizado.ok_etapa_B,
                 cfg_optimizado.ciclo_etapa_C, cfg_optimizado.ok_etapa_C,
                 cfg_optimizado.ciclo_etapa_D, cfg_optimizado.ok_etapa_D);
        $display("--------------------------------------------------------------------------------");
        $display(" Metrica                  | Pipeline (E1) | Dual-Issue (E2) | Optimizado (EF)");
        $display("--------------------------+---------------+-----------------+----------------");
        $display(" Ciclos totales (sin fin) | %13d | %15d | %15d",
                 cfg_pipeline.ciclos_totales, cfg_dual_issue.ciclos_totales, cfg_optimizado.ciclos_totales);
        $display(" Instrucciones retiradas  | %13d | %15d | %15d",
                 cfg_pipeline.instr_retiradas, cfg_dual_issue.instr_retiradas, cfg_optimizado.instr_retiradas);
        $display(" Conflictos de memoria    |             - | %15d | %15d",
                 cfg_dual_issue.mem_conflicts, cfg_optimizado.mem_conflicts);
        $display(" Ciclos de MemStall (L1)  |             0 |               0 | %15d",
                 cfg_optimizado.mem_stalls);
        $display(" Pares dual-mem (Cache L1)|             - |               0 | %15d",
                 cfg_optimizado.dual_mem_pairs);
        $display(" Cache L1 Hits / Accesos  |             - |               - | %7d / %5d",
                 cfg_optimizado.cache_hits, cfg_optimizado.cache_accesses);
        $display(" Errores / Diff A==B==C   | %13d | %15d | %7d (diff=%0d)",
                 cfg_pipeline.errores, cfg_dual_issue.errores, cfg_optimizado.errores, diff_errors);
        $display("================================================================================");
        $finish;
    end
endmodule
