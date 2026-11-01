`timescale 1ns/1ps
module tb_e1_core #(
    parameter integer PROG = 1,
    parameter MEM_FILE = "prog1_isa.mem",
    parameter [31:0] DONE_PC = 32'h00000090
);
    reg clk;
    reg reset;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;
    top #(
        .MEM_FILE(MEM_FILE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );
    initial begin
        clk = 0;
    end
    always #5 clk = ~clk;
    reg [31:0] esperada_0;
    reg [31:0] esperada_1;
    initial begin
        case (PROG)
            1: begin
                esperada_0 = 32'h00c00093;
                esperada_1 = 32'h00500113;
            end
            2: begin
                esperada_0 = 32'h04000a13;
                esperada_1 = 32'h00000793;
            end
            3: begin
                esperada_0 = 32'h04000a13;
                esperada_1 = 32'h00000613;
            end
            4: begin
                esperada_0 = 32'h04000a13;
                esperada_1 = 32'h00400093;
            end
            default: begin
                esperada_0 = 32'hxxxxxxxx;
                esperada_1 = 32'hxxxxxxxx;
            end
        endcase
        #1;
        if (
            (dut.imem.RAM[0] !== esperada_0) ||
            (dut.imem.RAM[1] !== esperada_1)
        ) begin
            errores = errores + 1;
            $finish;
        end
    end
    wire [31:0] PCF;
    wire [31:0] InstrF;
    wire [31:0] InstrF2;
    assign PCF     = dut.PC;
    assign InstrF  = dut.Instr;
    assign InstrF2 = dut.Instr2;
    wire [31:0] InstrD;
    wire [31:0] InstrD2;
    wire [31:0] PCD;
    wire [31:0] PCD2;
    wire [4:0] Rs1D2;
    wire [4:0] Rs2D2;
    wire [2:0] ALUControlD2;
    wire IssueSlot2D;
    wire PCInc8F;
    assign InstrD = dut.rvpipe.InstrD;
    assign InstrD2 = dut.rvpipe.InstrD2;
    assign PCD = dut.rvpipe.dp.PCD;
    assign PCD2 = dut.rvpipe.dp.PCD2;
    assign Rs1D2 = dut.rvpipe.dp.Rs1D2;
    assign Rs2D2 = dut.rvpipe.dp.Rs2D2;
    assign ALUControlD2 = dut.rvpipe.ALUControlD2;
    assign IssueSlot2D = dut.rvpipe.IssueSlot2D;
    assign PCInc8F = dut.rvpipe.PCInc8F;
    wire [1:0] ForwardAE;
    wire [1:0] ForwardBE;
    wire StallF;
    wire StallD;
    wire FlushD;
    wire FlushE;
    wire PCSrcE;
    wire ResultSrcEb0;
    wire [31:0] PCTargetE;
    assign ForwardAE = dut.rvpipe.ForwardAE;
    assign ForwardBE = dut.rvpipe.ForwardBE;
    assign StallF = dut.rvpipe.StallF;
    assign StallD = dut.rvpipe.StallD;
    assign FlushD = dut.rvpipe.FlushD;
    assign FlushE = dut.rvpipe.FlushE;
    assign PCSrcE = dut.rvpipe.PCSrcE;
    assign ResultSrcEb0 = dut.rvpipe.ResultSrcEb0;
    assign PCTargetE = dut.rvpipe.dp.PCTargetE;
    wire [31:0] PCE;
    wire [31:0] SrcAE;
    wire [31:0] SrcBE;
    wire [31:0] WriteDataE;
    wire [31:0] ALUResultE;
    wire [4:0] RdE;
    assign PCE = dut.rvpipe.dp.PCE;
    assign SrcAE = dut.rvpipe.dp.SrcAE;
    assign SrcBE = dut.rvpipe.dp.SrcBE;
    assign WriteDataE = dut.rvpipe.dp.WriteDataE;
    assign ALUResultE = dut.rvpipe.dp.ALUResultE;
    assign RdE = dut.rvpipe.RdE;
    wire [31:0] ALUResultM;
    wire [31:0] ReadDataM;
    wire [4:0] RdM;
    assign ALUResultM = dut.rvpipe.dp.ALUResultM;
    assign ReadDataM = dut.ReadData;
    assign RdM = dut.rvpipe.RdM;
    wire [31:0] ResultW;
    wire [4:0] RdW;
    wire RegWriteW;
    assign ResultW = dut.rvpipe.dp.ResultW;
    assign RdW = dut.rvpipe.RdW;
    assign RegWriteW = dut.rvpipe.RegWriteW;
    reg [31:0] InstrE;
    reg [31:0] InstrM;
    reg [31:0] InstrW;
    reg [31:0] PCM;
    reg [31:0] PCW;
    reg validE;
    reg validM;
    reg validW;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            InstrE <= 32'b0;
            InstrM <= 32'b0;
            InstrW <= 32'b0;
            PCM <= 32'b0;
            PCW <= 32'b0;
            validE <= 1'b0;
            validM <= 1'b0;
            validW <= 1'b0;
        end else begin
            if (FlushE)
                InstrE <= 32'b0;
            else
                InstrE <= InstrD;
            InstrM <= InstrE;
            InstrW <= InstrM;
            PCM <= PCE;
            PCW <= PCM;
            validE <= (!FlushE && (InstrD != 32'b0));
            validM <= validE;
            validW <= validM;
        end
    end
    wire [31:0] mem64;
    wire [31:0] mem68;
    wire [31:0] mem72;
    wire [31:0] mem76;
    wire [31:0] mem80;
    wire [31:0] mem84;
    wire [31:0] mem88;
    wire [31:0] mem92;
    wire [31:0] mem96;
    wire [31:0] mem100;
    wire [31:0] mem104;
    wire [31:0] mem108;
    wire [31:0] mem112;
    wire [31:0] mem116;
    assign mem64  = dut.dmem.RAM[16];
    assign mem68  = dut.dmem.RAM[17];
    assign mem72  = dut.dmem.RAM[18];
    assign mem76  = dut.dmem.RAM[19];
    assign mem80  = dut.dmem.RAM[20];
    assign mem84  = dut.dmem.RAM[21];
    assign mem88  = dut.dmem.RAM[22];
    assign mem92  = dut.dmem.RAM[23];
    assign mem96  = dut.dmem.RAM[24];
    assign mem100 = dut.dmem.RAM[25];
    assign mem104 = dut.dmem.RAM[26];
    assign mem108 = dut.dmem.RAM[27];
    assign mem112 = dut.dmem.RAM[28];
    assign mem116 = dut.dmem.RAM[29];
    wire [31:0] x3;
    wire [31:0] x4;
    wire [31:0] x5;
    wire [31:0] x6;
    wire [31:0] x7;
    wire [31:0] x9;
    wire [31:0] x12;
    wire [31:0] x15;
    assign x3  = dut.rvpipe.dp.rf.rf[3];
    assign x4  = dut.rvpipe.dp.rf.rf[4];
    assign x5  = dut.rvpipe.dp.rf.rf[5];
    assign x6  = dut.rvpipe.dp.rf.rf[6];
    assign x7  = dut.rvpipe.dp.rf.rf[7];
    assign x9  = dut.rvpipe.dp.rf.rf[9];
    assign x12 = dut.rvpipe.dp.rf.rf[12];
    assign x15 = dut.rvpipe.dp.rf.rf[15];
    integer ciclos;
    integer stalls;
    integer branches;
    integer flushes;
    integer fwdA_mem;
    integer fwdA_wb;
    integer fwdB_mem;
    integer fwdB_wb;
    integer done_seen;
    integer errores;
    reg finalizado;
    initial begin
        reset = 1;
        ciclos = 0;
        stalls = 0;
        branches = 0;
        flushes = 0;
        fwdA_mem = 0;
        fwdA_wb = 0;
        fwdB_mem = 0;
        fwdB_wb = 0;
        done_seen = 0;
        errores = 0;
        finalizado = 0;
        #22;
        reset = 0;
    end
    always @(posedge clk) begin
        if (!reset && !finalizado) begin
            ciclos = ciclos + 1;
            if (StallF === 1'b1)
                stalls = stalls + 1;
            if (PCSrcE === 1'b1)
                branches = branches + 1;
            if (FlushD === 1'b1)
                flushes = flushes + 1;
            if (ForwardAE === 2'b10)
                fwdA_mem = fwdA_mem + 1;
            if (ForwardAE === 2'b01)
                fwdA_wb = fwdA_wb + 1;
            if (ForwardBE === 2'b10)
                fwdB_mem = fwdB_mem + 1;
            if (ForwardBE === 2'b01)
                fwdB_wb = fwdB_wb + 1;
            if (
                (PCSrcE === 1'b1) &&
                (PCE === DONE_PC)
            )
                done_seen = done_seen + 1;
        end
    end
    task check_mem;
        input integer addr;
        input [31:0] valor_esperado;
        begin
            if (
                dut.dmem.RAM[addr/4] !== valor_esperado
            ) begin
                errores = errores + 1;
            end
        end
    endtask
    task check_reg;
        input integer num;
        input [31:0] valor_esperado;
        begin
            if (
                dut.rvpipe.dp.rf.rf[num] !== valor_esperado
            ) begin
                errores = errores + 1;
            end
        end
    endtask
    task check_true;
        input condicion;
        input [8*100-1:0] mensaje;
        begin
            if (condicion !== 1'b1) begin
                errores = errores + 1;
            end
        end
    endtask
    task verificar;
        begin
            case (PROG)
                1: begin
                    check_mem(64, 12);
                    check_mem(68, 5);
                    check_mem(72, 17);
                    check_mem(76, 7);
                    check_mem(80, 240);
                    check_mem(84, 252);
                    check_mem(88, 1);
                    check_mem(92, 0);
                    check_mem(96, 60);
                    check_mem(100, 780);
                    check_mem(104, 1);
                    check_mem(108, 32'hfffffffb);
                    check_mem(112, 12);
                    check_mem(116, 5);
                    check_reg(7, 17);
                    check_reg(8, 7);
                    check_true(
                        stalls == 0,
                        "Programa ISA con stalls inesperados"
                    );
                end
                2: begin
                    check_mem(64, 77);
                    check_mem(68, 10);
                    check_mem(72, 13);
                    check_mem(76, 3);
                    check_mem(80, 15);
                    check_mem(84, 1);
                    check_mem(88, 6);
                    check_mem(92, 4);
                    check_mem(96, 3);
                    check_mem(100, 0);
                    check_reg(8, 2);
                    check_reg(9, 4);
                    check_reg(15, 0);
                    check_true(
                        stalls == 0,
                        "Forwarding no debe requerir stalls"
                    );
                    check_true(
                        (fwdA_mem > 0) && (fwdA_wb > 0),
                        "No se evidencio forwarding MEM/WB hacia A"
                    );
                    check_true(
                        (fwdB_mem > 0) && (fwdB_wb > 0),
                        "No se evidencio forwarding MEM/WB hacia B"
                    );
                    check_true(
                        branches > 0,
                        "No se detecto branch tomado"
                    );
                end
                3: begin
                    check_mem(64, 25);
                    check_mem(68, 32'hfffffff9);
                    check_mem(72, 25);
                    check_mem(76, 50);
                    check_mem(80, 32);
                    check_mem(84, 32'hfffffff2);
                    check_mem(88, 25);
                    check_mem(92, 0);
                    check_mem(96, 18);
                    check_reg(4, 50);
                    check_reg(6, 32);
                    check_reg(9, 32'hfffffff2);
                    check_reg(12, 0);
                    check_reg(15, 18);
                    check_true(
                        stalls == 5,
                        "Se esperan exactamente 5 stalls"
                    );
                    check_true(
                        branches > 0,
                        "No se detecto BEQ tomado"
                    );
                end
                4: begin
                    check_mem(64, 3);
                    check_mem(68, 44);
                    check_mem(72, 6);
                    check_mem(76, 0);
                    check_reg(3, 3);
                    check_reg(5, 44);
                    check_reg(7, 6);
                    check_reg(6, 0);
                    check_true(
                        branches >= 6,
                        "Saltos tomados insuficientes"
                    );
                    check_true(
                        flushes >= 6,
                        "No se observaron suficientes flushes"
                    );
                end
            endcase
            check_true(
                done_seen >= 3,
                "No se alcanzo el bucle final"
            );
        end
    endtask
    always @(negedge clk) begin
        if (!reset && !finalizado) begin
            if (done_seen >= 3) begin
                finalizado = 1;
                verificar();
                $finish;
            end
            else if (ciclos > 250) begin
                finalizado = 1;
                errores = errores + 1;
                $finish;
            end
        end
    end
endmodule
module tb_e1;
    tb_e1_core #(
        .PROG(1),
        .MEM_FILE("prog1_isa.mem"),
        .DONE_PC(32'h00000090)
    ) u();
endmodule
module tb_prog2;
    tb_e1_core #(
        .PROG(2),
        .MEM_FILE("prog2_forwarding.mem"),
        .DONE_PC(32'h0000007c)
    ) u();
endmodule
module tb_prog3;
    tb_e1_core #(
        .PROG(3),
        .MEM_FILE("prog3_stalling.mem"),
        .DONE_PC(32'h00000074)
    ) u();
endmodule
module tb_prog4;
    tb_e1_core #(
        .PROG(4),
        .MEM_FILE("prog4_flushing.mem"),
        .DONE_PC(32'h00000060)
    ) u();
endmodule
module tb_prog1;
    tb_e1_core #(
        .PROG(1),
        .MEM_FILE("prog1_isa.mem"),
        .DONE_PC(32'h00000090)
    ) u();
endmodule
