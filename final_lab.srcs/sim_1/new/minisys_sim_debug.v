`timescale 1ns / 1ps

// ħ�İ� �����˼������е�����Ϣ��sim

module minisys_sim_debug();

    // input
    reg clk = 0;
    reg rst = 1;
    reg[23:0] switch2N4 = 8'b10101100; // �����������û���⣿
    
    // output
    wire[23:0] led2N4;
    
    wire clock;
    
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
    always #10 clk = ~clk; // �����������û���⣿

endmodule
