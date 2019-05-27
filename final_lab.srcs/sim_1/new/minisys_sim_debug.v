`timescale 1ns / 1ps

// 魔改版 包含了几乎所有调试信息的sim

module minisys_sim_debug();

    // input
    reg clk = 0;
    reg rst = 1;
    reg[23:0] switch2N4 = 8'b10101100; // 这样声明真的没问题？
    
    // output
    wire[23:0] led2N4;
    
    wire clock;
    
    // 真实数据接口 基本按照下方元件顺序
    wire[31:0] Instruction; // 当前指令 单周期下全局统一
    wire[31:0] PC_plus_4_out; // 从取指送执行 PC+4 
    wire[31:0] Add_result; // 执行单元 计算出的跳转地址
    wire[31:0] Read_data_1; // 译码单元 从reg中读取结果1, 取指单元 jr指令用跳转地址
    wire Branch; // 控制单元 beq
    wire nBranch; // 控制单元 bne
    wire Jmp; // 控制单元 j - jump
    wire Jal; // 控制单元 jal - jump and link
    wire Jrn; // 控制单元 jr - jump to reg
    wire Zero; // 执行单元 如果计算结果为0 此位为1
    wire[31:0] opcplus4; // 从取指送译码 JAL 专用 PC+4
    
    wire[31:0] Read_data_2; // 译码单元 从reg中读取结果2, memorio 写入mem/io的数据来源
    wire[31:0] read_data; // 译码单元 从mem/io来的数据 准备被写入reg, memorio 完成mem/io 读取后数据的目的地
    wire[31:0] ALU_result; // 执行单元 ALU 计算结果, 译码单元可能写入reg
    wire[31:0] Sign_extend; // 译码单元, 立即数扩展后的结果
    wire RegWrite; // 从执行送译码 写reg的信号
    wire MemorIOtoReg; // 从执行送译码 决定是把mem(io)读取结果写入reg 还是把alu计算结果写入reg
    wire RegDst; // 从执行送译码 决定reg的目标寄存器是rt还是rd [坑警告？] 我这里似乎没用到
    
    wire[5:0] Function_opcode = Instruction[5:0]; // 执行单元 funct 直接从指令后6位得到
    wire[5:0] Exe_opcode = Instruction[31:26]; // 执行单元 opcode 直接从指令前6位得到
    wire[4:0] Shamt = Instruction[10:6]; // 执行单元 shamt 直接从指令中间5位得到
    wire[1:0] ALUOp; // 从控制送执行 运算指令控制编码
    wire Sftmd; // 从控制送执行 1表明是移位指令
    wire ALUSrc; // 从控制送执行 1表明第2个操作数是立即数扩展 0则使用Read_data_2
    wire I_format; // 从控制送执行 1说明是I类型指令（除去beq,bne,lw,sw）
    
    // 外围 IO 设备和mem
    
    wire[21:0] Alu_resultHigh = ALU_result[31:10]; // 执行单元 用ALU结果判定是IO操作还是mem操作 全1为前者
    wire[31:0] address; // memorio 显示往mem/io写的地址
    wire[31:0] write_data;// memorio 显示往mem/io写的数据
    
    wire MemWrite; // 执行单元送MemorIO mem写
    wire MemRead; // 执行单元送MemorIO mem读
    wire IORead; // 执行单元送MemorIO IO读
    wire IOWrite; // 执行单元送MemorIO IO写
    
    wire[31:0] mread_data; // 从mem送memorio 从 mem 中读取到的数据
    wire[15:0] ioread_data; // 从io送memorio 从 io 中读取到的数据
    
    wire LEDCtrl; // 从memorio送led LED的片选信号
    wire SwitchCtrl; // 从memorio送switch switch的片选信号
    
    wire[15:0] ioread_data_switch; // 从switch送ioread 来自拨码开关的读取
    
    wire[1:0] ledaddr = address[1:0]; // 地址低端 选择后16还是前8
    wire[1:0] switchaddr = address[1:0]; // 地址低端 选择后16还是前8
    
    // debug 接口 基本按照下方元件顺序
    wire[31:0] PC_plus_4; // 取指单元 PC+4
    wire[31:0] PC; // 取值单元 PC寄存器
    wire[31:0] next_PC; // 取值单元 下一个PC
    wire[31:0] register[31:0]; // 译码单元 reg 的内容显示, 此处需要 SystemVerilog 支持
    
    wire[2:0] ALU_ctl;
    wire[31:0] Ainput,Binput;
    
    wire[31:0] Branch_Add;
    
    cpu_debug u(clk, rst, led2N4, switch2N4, clock,
    Instruction, PC_plus_4_out, Add_result, Read_data_1, Branch, nBranch, Jmp, Jal, Jrn, Zero, opcplus4,
    Read_data_2, read_data, ALU_result, Sign_extend, RegWrite, MemorIOtoReg, RegDst,
    Function_opcode, Exe_opcode, Shamt, ALUOp, Sftmd, ALUSrc, I_format,
    Alu_resultHigh, address, write_data, MemWrite, MemRead, IORead, IOWrite,
    mread_data, ioread_data, LEDCtrl, SwitchCtrl, ioread_data_switch, ledaddr, switchaddr,
    PC_plus_4, PC, next_PC, register,
    ALU_ctl, Ainput, Binput,Branch_Add // debug
    
    );
    
    initial begin;
        #7000 rst = 0;
    end
    always #10 clk = ~clk; // 这样仿真真的没问题？

endmodule
