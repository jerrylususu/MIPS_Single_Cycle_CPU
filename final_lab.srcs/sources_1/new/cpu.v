`timescale 1ns / 1ps

// CPU 顶层模块包装
// 真实 CPU

module cpu(highclk, rst, led2N4, switch2N4);
input highclk; // 原始输入时钟
input rst; // 原始复位信号
output[23:0] led2N4; // led 输出到硬件
input[23:0] switch2N4; // switch 从硬件读取


// 调试中暂时不开启时钟降低频率
 wire clock; // 降频之后的clk
 cpuclk cpuclk(.clk_in1(highclk), .clk_out1(clock)); // 时钟降频

//wire clock = highclk;

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

// 各个模块的详细组装信息
Ifetc32 Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,rst,opcplus4,
PC, next_PC, PC_plus_4);

Idecode32 Idecode32(Read_data_1,Read_data_2,Instruction,read_data,ALU_result,
Jal,RegWrite,MemorIOtoReg,RegDst,Sign_extend,clock,rst, opcplus4, register);
// 【坑？】译码单元中 目标寄存器没有使用来自Control的RegDst 而是直接在本地做了判定... 这里最后是否需要修改？具体见lab10练习三 P10

Executs32 Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
Shamt,ALUSrc,I_format,Jrn,Zero,Sftmd,ALU_result,Add_result,PC_plus_4_out,
ALU_ctl, Ainput, Binput,Branch_Add);   // 5/23 debug增加

control32 control32(Exe_opcode,Function_opcode,Alu_resultHigh,Jrn,RegDst,ALUSrc,MemorIOtoReg,RegWrite,MemRead,MemWrite,
IORead,IOWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp);
// 【坑？】 控制单元中 Jrn被注释掉了 因为在sim文件中没有 但是可能实际是需要的？ 具体见lab11 P13

memorio memorio(ALU_result,address,MemRead,MemWrite,IORead,IOWrite,mread_data,ioread_data,
Read_data_2,read_data,write_data,LEDCtrl,SwitchCtrl);
// 写入地址caddress来自ALU_result
// 根据CPU通路图 wdata似乎来自于译码单元read_data_2, rdata则送译码单元中read_data 

dmemory32 dmemory32(mread_data,address,write_data,MemWrite,clock);
// read_data给memorio中mread_data
// 写入地址address来自ALU_result

ioread ioread1(rst,IORead,SwitchCtrl,ioread_data,ioread_data_switch);

leds leds(clock, rst, LEDCtrl, LEDCtrl, ledaddr,write_data[15:0], led2N4);
// 基于lab13的sim
// 一次最多写入16bit
switchs switchs(clock, rst, SwitchCtrl, SwitchCtrl,switchaddr, ioread_data_switch, switch2N4);
// 基于lab13的sim

endmodule















