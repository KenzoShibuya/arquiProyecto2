`timescale 1ns/1ps

module tb_e2_core #(
    parameter integer PROG = 5,
    parameter MEM_FILE = "prog5_dual_alu.mem",
    parameter [31:0] DONE_PC = 32'h00000068,
    parameter [31:0] FIRST0 = 32'h00a00093,
    parameter [31:0] FIRST1 = 32'h01400113
);
    reg clk, reset;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;

    top #(.MEM_FILE(MEM_FILE)) dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    wire [31:0] PCF = dut.PC;
    wire [31:0] InstrF = dut.Instr;
    wire [31:0] InstrF2 = dut.Instr2;
    wire [31:0] InstrD = dut.rvpipe.InstrD;
    wire [31:0] InstrD2 = dut.rvpipe.InstrD2;

    wire [31:0] PCD = dut.rvpipe.dp.PCD;
    wire [31:0] PCD2 = dut.rvpipe.dp.PCD2;

    wire [4:0] Rs1D = dut.rvpipe.Rs1D;
    wire [4:0] Rs2D = dut.rvpipe.Rs2D;
    wire [4:0] Rs1D2 = dut.rvpipe.dp.Rs1D2;
    wire [4:0] Rs2D2 = dut.rvpipe.dp.Rs2D2;

    wire [31:0] RD1D = dut.rvpipe.dp.RD1D;
    wire [31:0] RD2D = dut.rvpipe.dp.RD2D;
    wire [31:0] RD1D2 = dut.rvpipe.dp.RD1D2;
    wire [31:0] RD2D2 = dut.rvpipe.dp.RD2D2;

    wire [2:0] ALUControlD = dut.rvpipe.ALUControlD;
    wire [2:0] ALUControlD2 = dut.rvpipe.ALUControlD2;

    wire [31:0] PCE = dut.rvpipe.dp.PCE;
    wire [31:0] PCE2 = dut.rvpipe.dp.PCE2;
    wire [31:0] ALUResultE = dut.rvpipe.dp.ALUResultE;
    wire [31:0] ALUResultE2 = dut.rvpipe.dp.ALUResultE2;

    wire RegWriteE = dut.rvpipe.dp.RegWriteE;
    wire RegWriteE2 = dut.rvpipe.dp.RegWriteE2;
    wire MemWriteE = dut.rvpipe.dp.MemWriteE;
    wire MemWriteE2 = dut.rvpipe.dp.MemWriteE2;

    wire [1:0] ResultSrcE = dut.rvpipe.dp.ResultSrcE;
    wire [1:0] ResultSrcE2 = dut.rvpipe.dp.ResultSrcE2;

    wire [31:0] ALUResultM = dut.rvpipe.dp.ALUResultM;
    wire [31:0] ALUResultM2 = dut.rvpipe.dp.ALUResultM2;

    wire MemWriteM = dut.rvpipe.dp.MemWriteM;
    wire MemWriteM2 = dut.rvpipe.dp.MemWriteM2;
    wire MemAccessM2 = dut.rvpipe.dp.MemAccessM2;

    wire [31:0] ReadDataM = dut.ReadData;

    wire [31:0] ResultW = dut.rvpipe.dp.ResultW;
    wire [31:0] ResultW2 = dut.rvpipe.dp.ResultW2;

    wire [31:0] SrcAE = dut.rvpipe.dp.SrcAE;
    wire [31:0] SrcBE = dut.rvpipe.dp.SrcBE;
    wire [31:0] SrcAE2 = dut.rvpipe.dp.SrcAE2;
    wire [31:0] SrcBE2 = dut.rvpipe.dp.SrcBE2;

    wire [31:0] WriteDataE = dut.rvpipe.dp.WriteDataE;
    wire [31:0] WriteDataE2 = dut.rvpipe.dp.WriteDataE2;

    wire [4:0] RdE = dut.rvpipe.RdE;
    wire [4:0] RdE2 = dut.rvpipe.RdE2;
    wire [4:0] RdM = dut.rvpipe.RdM;
    wire [4:0] RdM2 = dut.rvpipe.RdM2;
    wire [4:0] RdW = dut.rvpipe.RdW;
    wire [4:0] RdW2 = dut.rvpipe.RdW2;

    wire RegWriteW = dut.rvpipe.RegWriteW;
    wire RegWriteW2 = dut.rvpipe.RegWriteW2;

    wire [2:0] ForwardAE = dut.rvpipe.ForwardAE;
    wire [2:0] ForwardBE = dut.rvpipe.ForwardBE;
    wire [2:0] ForwardAE2 = dut.rvpipe.ForwardAE2;
    wire [2:0] ForwardBE2 = dut.rvpipe.ForwardBE2;

    wire StallF = dut.rvpipe.StallF;
    wire StallD = dut.rvpipe.StallD;
    wire FlushD = dut.rvpipe.FlushD;
    wire FlushE = dut.rvpipe.FlushE;
    wire FlushM2 = dut.rvpipe.FlushM2;

    wire IssueSlot2D = dut.rvpipe.IssueSlot2D;
    wire PCInc8F = dut.rvpipe.PCInc8F;

    wire raw_conflict = dut.rvpipe.iu.raw_hazard;
    wire mem_conflict = dut.rvpipe.iu.mem_conflict;
    wire ctrl_conflict = dut.rvpipe.iu.ctrl_conflict;
    wire lw_hazard_slot2 = dut.rvpipe.iu.lw_hazard_slot2;

    wire ResultSrcEb0 = dut.rvpipe.ResultSrcEb0;
    wire ResultSrcE2b0 = dut.rvpipe.ResultSrcE2b0;

    wire PCSrcE = dut.rvpipe.PCSrcE;
    wire PCSrcE1 = dut.rvpipe.PCSrcE1;
    wire PCSrcE2 = dut.rvpipe.dp.PCSrcE2;

    wire BranchE = dut.rvpipe.dp.BranchE;
    wire BranchE2 = dut.rvpipe.dp.BranchE2;
    wire JumpE = dut.rvpipe.dp.JumpE;
    wire JumpE2 = dut.rvpipe.dp.JumpE2;
    wire ZeroE = dut.rvpipe.dp.ZeroE;
    wire ZeroE2 = dut.rvpipe.dp.ZeroE2;

    wire [31:0] PCTargetE = dut.rvpipe.dp.PCTargetE;

    wire [31:0] mem64 = dut.dmem.RAM[16];
    wire [31:0] mem68 = dut.dmem.RAM[17];
    wire [31:0] mem72 = dut.dmem.RAM[18];
    wire [31:0] mem76 = dut.dmem.RAM[19];
    wire [31:0] mem80 = dut.dmem.RAM[20];
    wire [31:0] mem84 = dut.dmem.RAM[21];
    wire [31:0] mem88 = dut.dmem.RAM[22];
    wire [31:0] mem92 = dut.dmem.RAM[23];
    wire [31:0] mem96 = dut.dmem.RAM[24];
    wire [31:0] mem100 = dut.dmem.RAM[25];
    wire [31:0] mem104 = dut.dmem.RAM[26];
    wire [31:0] mem108 = dut.dmem.RAM[27];
    wire [31:0] mem112 = dut.dmem.RAM[28];
    wire [31:0] mem116 = dut.dmem.RAM[29];
    wire [31:0] mem120 = dut.dmem.RAM[30];
    wire [31:0] mem124 = dut.dmem.RAM[31];

    wire [31:0] x1 = dut.rvpipe.dp.rf.rf[1];
    wire [31:0] x2 = dut.rvpipe.dp.rf.rf[2];
    wire [31:0] x3 = dut.rvpipe.dp.rf.rf[3];
    wire [31:0] x5 = dut.rvpipe.dp.rf.rf[5];
    wire [31:0] x6 = dut.rvpipe.dp.rf.rf[6];
    wire [31:0] x7 = dut.rvpipe.dp.rf.rf[7];
    wire [31:0] x8 = dut.rvpipe.dp.rf.rf[8];
    wire [31:0] x9 = dut.rvpipe.dp.rf.rf[9];
    wire [31:0] x10 = dut.rvpipe.dp.rf.rf[10];
    wire [31:0] x11 = dut.rvpipe.dp.rf.rf[11];
    wire [31:0] x12 = dut.rvpipe.dp.rf.rf[12];
    wire [31:0] x13 = dut.rvpipe.dp.rf.rf[13];
    wire [31:0] x16 = dut.rvpipe.dp.rf.rf[16];
    wire [31:0] x18 = dut.rvpipe.dp.rf.rf[18];
    wire [31:0] x20 = dut.rvpipe.dp.rf.rf[20];

    reg [31:0] InstrE, InstrE2;
    reg [31:0] InstrM, InstrM2;
    reg [31:0] InstrW, InstrW2;

    reg [31:0] PCM, PCM2, PCW, PCW2;
    reg validE, validE2, validM, validM2, validW, validW2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            InstrE <= 0;
            InstrE2 <= 0;
            InstrM <= 0;
            InstrM2 <= 0;
            InstrW <= 0;
            InstrW2 <= 0;

            PCM <= 0;
            PCM2 <= 0;
            PCW <= 0;
            PCW2 <= 0;

            validE <= 0;
            validE2 <= 0;
            validM <= 0;
            validM2 <= 0;
            validW <= 0;
            validW2 <= 0;
        end else begin
            InstrE <= FlushE ? 32'b0 : InstrD;
            InstrE2 <= (FlushE || !IssueSlot2D) ? 32'b0 : InstrD2;

            InstrM <= InstrE;
            InstrM2 <= FlushM2 ? 32'b0 : InstrE2;

            InstrW <= InstrM;
            InstrW2 <= InstrM2;

            PCM <= PCE;
            PCM2 <= FlushM2 ? 32'b0 : PCE2;

            PCW <= PCM;
            PCW2 <= PCM2;

            validE <= !FlushE && (InstrD != 0);
            validE2 <= !FlushE && IssueSlot2D && (InstrD2 != 0);
            validM <= validE;
            validM2 <= validE2 && !FlushM2;
            validW <= validM;
            validW2 <= validM2;
        end
    end

    integer ciclos, dual_issue, single_issue;
    integer raw_conflicts, mem_conflicts;
    integer ctrl_conflicts, stalls, flushes;
    integer flush_m2_count;
    integer branch_via1, branch_via2;
    integer loads_slot2_conflict;

    integer fwd_mem1, fwd_mem2;
    integer fwd_wb1, fwd_wb2;

    integer escrituras_dobles;
    integer escrituras_mismo_registro;

    integer emitidas1, emitidas2;
    integer retiradas1, retiradas2;

    integer done_seen, errores, timeout;
    integer finalizado, memoria_cargada;
    integer duplicados, perdidos;
    integer escrituras_inesperadas;

    integer emitidas_pc[0:255];
    integer escrituras_pc[0:63];
    integer k;

    wire [31:0] ipc_x1000 = (ciclos > 0) ?
        ((retiradas1 + retiradas2) * 1000) / ciclos : 32'b0;

    initial begin
        reset = 1;

        ciclos = 0;
        dual_issue = 0;
        single_issue = 0;

        raw_conflicts = 0;
        mem_conflicts = 0;
        ctrl_conflicts = 0;

        stalls = 0;
        flushes = 0;
        flush_m2_count = 0;

        branch_via1 = 0;
        branch_via2 = 0;
        loads_slot2_conflict = 0;

        fwd_mem1 = 0;
        fwd_mem2 = 0;
        fwd_wb1 = 0;
        fwd_wb2 = 0;

        escrituras_dobles = 0;
        escrituras_mismo_registro = 0;

        emitidas1 = 0;
        emitidas2 = 0;
        retiradas1 = 0;
        retiradas2 = 0;

        done_seen = 0;
        errores = 0;
        timeout = 0;
        finalizado = 0;
        memoria_cargada = 0;

        duplicados = 0;
        perdidos = 0;
        escrituras_inesperadas = 0;

        for (k = 0; k < 256; k = k + 1)
            emitidas_pc[k] = 0;

        for (k = 0; k < 64; k = k + 1)
            escrituras_pc[k] = 0;

        #1;

        if ((dut.imem.RAM[0] !== FIRST0) ||
            (dut.imem.RAM[1] !== FIRST1)) begin
            errores = errores + 1;
            finalizado = 1;
        end else begin
            memoria_cargada = 1;
        end

        #21;
        reset = 0;
    end

    always @(posedge clk) begin
        if (!reset && !finalizado) begin
            ciclos = ciclos + 1;

            if (IssueSlot2D &&
                (InstrD != 0) &&
                (InstrD2 != 0) &&
                !FlushE && !StallD)
                dual_issue = dual_issue + 1;

            if (!IssueSlot2D &&
                (InstrD != 0) &&
                !FlushE && !StallD)
                single_issue = single_issue + 1;

            if (raw_conflict)
                raw_conflicts = raw_conflicts + 1;

            if (mem_conflict)
                mem_conflicts = mem_conflicts + 1;

            if (ctrl_conflict)
                ctrl_conflicts = ctrl_conflicts + 1;

            if (lw_hazard_slot2)
                loads_slot2_conflict = loads_slot2_conflict + 1;

            if (StallF)
                stalls = stalls + 1;

            if (FlushD)
                flushes = flushes + 1;

            if (FlushM2)
                flush_m2_count = flush_m2_count + 1;

            if (PCSrcE1)
                branch_via1 = branch_via1 + 1;

            if (PCSrcE2)
                branch_via2 = branch_via2 + 1;

            if (validW)
                retiradas1 = retiradas1 + 1;

            if (validW2)
                retiradas2 = retiradas2 + 1;

            if (ForwardAE == 3'b010 ||
                ForwardBE == 3'b010 ||
                ForwardAE2 == 3'b010 ||
                ForwardBE2 == 3'b010)
                fwd_mem1 = fwd_mem1 + 1;

            if (ForwardAE == 3'b110 ||
                ForwardBE == 3'b110 ||
                ForwardAE2 == 3'b110 ||
                ForwardBE2 == 3'b110)
                fwd_mem2 = fwd_mem2 + 1;

            if (ForwardAE == 3'b001 ||
                ForwardBE == 3'b001 ||
                ForwardAE2 == 3'b001 ||
                ForwardBE2 == 3'b001)
                fwd_wb1 = fwd_wb1 + 1;

            if (ForwardAE == 3'b101 ||
                ForwardBE == 3'b101 ||
                ForwardAE2 == 3'b101 ||
                ForwardBE2 == 3'b101)
                fwd_wb2 = fwd_wb2 + 1;

            if (!FlushE && !StallD && (InstrD != 0)) begin
                emitidas1 = emitidas1 + 1;

                if (PROG == 9 && PCD < DONE_PC) begin
                    if (PCD[31:2] < 256) begin
                        emitidas_pc[PCD[31:2]] =
                            emitidas_pc[PCD[31:2]] + 1;

                        if (emitidas_pc[PCD[31:2]] > 1)
                            duplicados = duplicados + 1;
                    end else begin
                        errores = errores + 1;
                    end
                end
            end

            if (!FlushE && !StallD &&
                IssueSlot2D && (InstrD2 != 0)) begin
                emitidas2 = emitidas2 + 1;

                if (PROG == 9 && PCD2 < DONE_PC) begin
                    if (PCD2[31:2] < 256) begin
                        emitidas_pc[PCD2[31:2]] =
                            emitidas_pc[PCD2[31:2]] + 1;

                        if (emitidas_pc[PCD2[31:2]] > 1)
                            duplicados = duplicados + 1;
                    end else begin
                        errores = errores + 1;
                    end
                end
            end

            if (MemWrite === 1'b1) begin
                if ((^DataAdr === 1'bx) ||
                    (DataAdr >= 256) ||
                    (DataAdr[1:0] != 0)) begin
                    escrituras_inesperadas =
                        escrituras_inesperadas + 1;
                end else begin
                    escrituras_pc[DataAdr[7:2]] =
                        escrituras_pc[DataAdr[7:2]] + 1;
                end
            end

            if ((PCSrcE1 && PCE == DONE_PC) ||
                (PCSrcE2 && PCE2 == DONE_PC))
                done_seen = done_seen + 1;
        end
    end

    always @(negedge clk) begin
        if (!reset && !finalizado) begin
            if (RegWriteW && RegWriteW2 &&
                RdW != 0 && RdW2 != 0) begin
                escrituras_dobles =
                    escrituras_dobles + 1;

                if (RdW == RdW2)
                    escrituras_mismo_registro =
                        escrituras_mismo_registro + 1;
            end

            if (done_seen >= 3) begin
                verificar();
                finalizado = 1;
            end else if (ciclos > 400) begin
                timeout = 1;
                errores = errores + 1;
                finalizado = 1;
            end
        end
    end

    task check_mem;
        input integer addr;
        input [31:0] esperado;
        begin
            if (dut.dmem.RAM[addr/4] !== esperado)
                errores = errores + 1;

            if (escrituras_pc[addr/4] != 1)
                errores = errores + 1;
        end
    endtask

    task check_reg;
        input integer numero;
        input [31:0] esperado;
        begin
            if (dut.rvpipe.dp.rf.rf[numero] !== esperado)
                errores = errores + 1;
        end
    endtask

    task check_event;
        input condicion;
        begin
            if (condicion !== 1'b1)
                errores = errores + 1;
        end
    endtask

    task verificar;
        integer j;
        integer hasta;
        begin
            case (PROG)
                5: begin
                    check_mem(64,30);
                    check_mem(68,35);
                    check_mem(72,10);
                    check_mem(76,32'hffffffff);
                    check_mem(80,1);
                    check_mem(84,1);
                    check_mem(88,4);
                    check_mem(92,15);
                    check_mem(96,65);
                    check_mem(100,32'hfffffff8);

                    check_reg(6,30);
                    check_reg(7,35);
                    check_reg(14,65);

                    check_event(dual_issue >= 8);
                    check_event(stalls == 0);
                end

                6: begin
                    check_mem(64,12);
                    check_mem(68,15);
                    check_mem(72,32'hfffffff7);
                    check_mem(76,2);
                    check_mem(80,4);
                    check_mem(84,17);
                    check_mem(88,6);
                    check_mem(92,32'hfffffff5);
                    check_mem(96,8);

                    check_reg(7,2);
                    check_reg(8,4);
                    check_reg(12,32'hfffffff5);

                    check_event(raw_conflicts > 0);
                    check_event(single_issue > 0 &&
                                dual_issue > 0);
                    check_event(fwd_mem1 > 0 &&
                                fwd_mem2 > 0);
                    check_event(fwd_wb1 > 0 &&
                                fwd_wb2 > 0);
                    check_event(escrituras_mismo_registro > 0);
                end

                7: begin
                    check_mem(64,11);
                    check_mem(68,22);
                    check_mem(72,33);
                    check_mem(76,44);
                    check_mem(80,11);
                    check_mem(84,22);
                    check_mem(88,33);
                    check_mem(92,33);
                    check_mem(96,66);
                    check_mem(100,44);
                    check_mem(104,55);
                    check_mem(108,11);
                    check_mem(112,22);
                    check_mem(116,55);
                    check_mem(120,66);
                    check_mem(124,77);

                    check_reg(11,33);
                    check_reg(16,66);
                    check_reg(18,55);

                    check_event(mem_conflicts > 0);
                    check_event(stalls > 0);
                    check_event(single_issue > 0 &&
                                dual_issue > 0);
                end

                8: begin
                    check_mem(64,15);
                    check_mem(68,76);
                    check_mem(72,92);
                    check_mem(76,6);
                    check_mem(80,0);

                    check_reg(3,15);
                    check_reg(5,76);
                    check_reg(6,92);
                    check_reg(8,6);

                    check_event(branch_via1 > 0 &&
                                branch_via2 > 0);
                    check_event(flush_m2_count > 0 &&
                                flushes > 0);
                    check_event(ctrl_conflicts > 0);
                end

                9: begin
                    check_mem(64,135);
                    check_mem(68,6);
                    check_mem(72,12);
                    check_mem(76,2);

                    check_reg(1,135);
                    check_reg(9,6);
                    check_reg(10,2);

                    check_event(raw_conflicts > 0);
                    check_event(single_issue > 0 &&
                                dual_issue > 0);
                    check_event(escrituras_mismo_registro > 0);

                    hasta = DONE_PC / 4;

                    for (j=0; j<hasta; j=j+1) begin
                        if (emitidas_pc[j] == 0)
                            perdidos = perdidos + 1;

                        if (emitidas_pc[j] != 1)
                            errores = errores + 1;
                    end

                    check_event(duplicados == 0 &&
                                perdidos == 0);
                end
            endcase

            if (escrituras_inesperadas > 0)
                errores = errores + 1;

            for (j=0; j<64; j=j+1) begin
                if (j < 16 || j > 31) begin
                    if (escrituras_pc[j] != 0)
                        errores = errores + 1;
                end else begin
                    case (PROG)
                        5: if (j > 25 &&
                               escrituras_pc[j] != 0)
                               errores = errores + 1;

                        6: if (j > 24 &&
                               escrituras_pc[j] != 0)
                               errores = errores + 1;

                        7: if (j > 31 &&
                               escrituras_pc[j] != 0)
                               errores = errores + 1;

                        8: if (j > 20 &&
                               escrituras_pc[j] != 0)
                               errores = errores + 1;

                        9: if (j > 19 &&
                               escrituras_pc[j] != 0)
                               errores = errores + 1;
                    endcase
                end
            end

            check_event(done_seen >= 3);
        end
    endtask
endmodule

module tb_prog5;
    tb_e2_core #(
        .PROG(5),
        .MEM_FILE("prog5_dual_alu.mem"),
        .DONE_PC(32'h00000068),
        .FIRST0(32'h00a00093),
        .FIRST1(32'h01400113)
    ) u();
endmodule

module tb_prog6;
    tb_e2_core #(
        .PROG(6),
        .MEM_FILE("prog6_dual_raw.mem"),
        .DONE_PC(32'h00000060),
        .FIRST0(32'h04000a13),
        .FIRST1(32'h00500093)
    ) u();
endmodule

module tb_prog7;
    tb_e2_core #(
        .PROG(7),
        .MEM_FILE("prog7_dual_mem.mem"),
        .DONE_PC(32'h00000098),
        .FIRST0(32'h04000a13),
        .FIRST1(32'h00b00093)
    ) u();
endmodule

module tb_prog8;
    tb_e2_core #(
        .PROG(8),
        .MEM_FILE("prog8_dual_branch.mem"),
        .DONE_PC(32'h00000094),
        .FIRST0(32'h04000a13),
        .FIRST1(32'h00400093)
    ) u();
endmodule

module tb_prog9;
    tb_e2_core #(
        .PROG(9),
        .MEM_FILE("prog9_dual_regroup.mem"),
        .DONE_PC(32'h00000078),
        .FIRST0(32'h04000a13),
        .FIRST1(32'h00100093)
    ) u();
endmodule