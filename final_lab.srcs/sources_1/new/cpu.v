`timescale 1ns / 1ps

// CPU ����ģ���װ
// ��ʵ CPU

module cpu(highclk, rst, led2N4, switch2N4);
input highclk; // ԭʼ����ʱ��
input rst; // ԭʼ��λ�ź�
output[23:0] led2N4; // led �����Ӳ��
input[23:0] switch2N4; // switch ��Ӳ����ȡ


// ��������ʱ������ʱ�ӽ���Ƶ��
 wire clock; // ��Ƶ֮���clk
 cpuclk cpuclk(.clk_in1(highclk), .clk_out1(clock)); // ʱ�ӽ�Ƶ

//wire clock = highclk;

// ��ʵ���ݽӿ� ���������·�Ԫ��˳��
wire[31:0] Instruction; // ��ǰָ�� ��������ȫ��ͳһ
wire[31:0] PC_plus_4_out; // ��ȡָ��ִ�� PC+4 
wire[31:0] Add_result; // ִ�е�Ԫ ���������ת��ַ
wire[31:0] Read_data_1; // ���뵥Ԫ ��reg�ж�ȡ���1, ȡָ��Ԫ jrָ������ת��ַ
wire Branch; // ���Ƶ�Ԫ beq
wire nBranch; // ���Ƶ�Ԫ bne
wire Jmp; // ���Ƶ�Ԫ j - jump
wire Jal; // ���Ƶ�Ԫ jal - jump and link
wire Jrn; // ���Ƶ�Ԫ jr - jump to reg
wire Zero; // ִ�е�Ԫ ���������Ϊ0 ��λΪ1
wire[31:0] opcplus4; // ��ȡָ������ JAL ר�� PC+4

wire[31:0] Read_data_2; // ���뵥Ԫ ��reg�ж�ȡ���2, memorio д��mem/io��������Դ
wire[31:0] read_data; // ���뵥Ԫ ��mem/io�������� ׼����д��reg, memorio ���mem/io ��ȡ�����ݵ�Ŀ�ĵ�
wire[31:0] ALU_result; // ִ�е�Ԫ ALU ������, ���뵥Ԫ����д��reg
wire[31:0] Sign_extend; // ���뵥Ԫ, ��������չ��Ľ��
wire RegWrite; // ��ִ�������� дreg���ź�
wire MemorIOtoReg; // ��ִ�������� �����ǰ�mem(io)��ȡ���д��reg ���ǰ�alu������д��reg
wire RegDst; // ��ִ�������� ����reg��Ŀ��Ĵ�����rt����rd [�Ӿ��棿] �������ƺ�û�õ�

wire[5:0] Function_opcode = Instruction[5:0]; // ִ�е�Ԫ funct ֱ�Ӵ�ָ���6λ�õ�
wire[5:0] Exe_opcode = Instruction[31:26]; // ִ�е�Ԫ opcode ֱ�Ӵ�ָ��ǰ6λ�õ�
wire[4:0] Shamt = Instruction[10:6]; // ִ�е�Ԫ shamt ֱ�Ӵ�ָ���м�5λ�õ�
wire[1:0] ALUOp; // �ӿ�����ִ�� ����ָ����Ʊ���
wire Sftmd; // �ӿ�����ִ�� 1��������λָ��
wire ALUSrc; // �ӿ�����ִ�� 1������2������������������չ 0��ʹ��Read_data_2
wire I_format; // �ӿ�����ִ�� 1˵����I����ָ���ȥbeq,bne,lw,sw��

// ��Χ IO �豸��mem

wire[21:0] Alu_resultHigh = ALU_result[31:10]; // ִ�е�Ԫ ��ALU����ж���IO��������mem���� ȫ1Ϊǰ��
wire[31:0] address; // memorio ��ʾ��mem/ioд�ĵ�ַ
wire[31:0] write_data;// memorio ��ʾ��mem/ioд������

wire MemWrite; // ִ�е�Ԫ��MemorIO memд
wire MemRead; // ִ�е�Ԫ��MemorIO mem��
wire IORead; // ִ�е�Ԫ��MemorIO IO��
wire IOWrite; // ִ�е�Ԫ��MemorIO IOд

wire[31:0] mread_data; // ��mem��memorio �� mem �ж�ȡ��������
wire[15:0] ioread_data; // ��io��memorio �� io �ж�ȡ��������

wire LEDCtrl; // ��memorio��led LED��Ƭѡ�ź�
wire SwitchCtrl; // ��memorio��switch switch��Ƭѡ�ź�

wire[15:0] ioread_data_switch; // ��switch��ioread ���Բ��뿪�صĶ�ȡ

wire[1:0] ledaddr = address[1:0]; // ��ַ�Ͷ� ѡ���16����ǰ8
wire[1:0] switchaddr = address[1:0]; // ��ַ�Ͷ� ѡ���16����ǰ8

// debug �ӿ� ���������·�Ԫ��˳��
wire[31:0] PC_plus_4; // ȡָ��Ԫ PC+4
wire[31:0] PC; // ȡֵ��Ԫ PC�Ĵ���
wire[31:0] next_PC; // ȡֵ��Ԫ ��һ��PC
wire[31:0] register[31:0]; // ���뵥Ԫ reg ��������ʾ, �˴���Ҫ SystemVerilog ֧��

wire[2:0] ALU_ctl;
wire[31:0] Ainput,Binput;
wire[31:0] Branch_Add;

// ����ģ�����ϸ��װ��Ϣ
Ifetc32 Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,rst,opcplus4,
PC, next_PC, PC_plus_4);

Idecode32 Idecode32(Read_data_1,Read_data_2,Instruction,read_data,ALU_result,
Jal,RegWrite,MemorIOtoReg,RegDst,Sign_extend,clock,rst, opcplus4, register);
// ���ӣ������뵥Ԫ�� Ŀ��Ĵ���û��ʹ������Control��RegDst ����ֱ���ڱ��������ж�... ��������Ƿ���Ҫ�޸ģ������lab10��ϰ�� P10

Executs32 Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
Shamt,ALUSrc,I_format,Jrn,Zero,Sftmd,ALU_result,Add_result,PC_plus_4_out,
ALU_ctl, Ainput, Binput,Branch_Add);   // 5/23 debug����

control32 control32(Exe_opcode,Function_opcode,Alu_resultHigh,Jrn,RegDst,ALUSrc,MemorIOtoReg,RegWrite,MemRead,MemWrite,
IORead,IOWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp);
// ���ӣ��� ���Ƶ�Ԫ�� Jrn��ע�͵��� ��Ϊ��sim�ļ���û�� ���ǿ���ʵ������Ҫ�ģ� �����lab11 P13

memorio memorio(ALU_result,address,MemRead,MemWrite,IORead,IOWrite,mread_data,ioread_data,
Read_data_2,read_data,write_data,LEDCtrl,SwitchCtrl);
// д���ַcaddress����ALU_result
// ����CPUͨ·ͼ wdata�ƺ����������뵥Ԫread_data_2, rdata�������뵥Ԫ��read_data 

dmemory32 dmemory32(mread_data,address,write_data,MemWrite,clock);
// read_data��memorio��mread_data
// д���ַaddress����ALU_result

ioread ioread1(rst,IORead,SwitchCtrl,ioread_data,ioread_data_switch);

leds leds(clock, rst, LEDCtrl, LEDCtrl, ledaddr,write_data[15:0], led2N4);
// ����lab13��sim
// һ�����д��16bit
switchs switchs(clock, rst, SwitchCtrl, SwitchCtrl,switchaddr, ioread_data_switch, switch2N4);
// ����lab13��sim

endmodule















