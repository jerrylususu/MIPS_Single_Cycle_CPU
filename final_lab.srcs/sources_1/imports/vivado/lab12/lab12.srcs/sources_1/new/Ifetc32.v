`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// ȡָ�PC����

module Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,reset,opcplus4,
PC, next_PC, PC_plus_4);
    output[31:0] Instruction;			// ���ָ�����ģ��
    output[31:0] PC_plus_4_out;         // (pc+4)��ִ�е�Ԫ
    input[31:0]  Add_result;            // ����ִ�е�Ԫ,�������ת��ַ
    input[31:0]  Read_data_1;           // �������뵥Ԫ��jrָ���õĵ�ַ
    input        Branch;                // ���Կ��Ƶ�Ԫ beq
    input        nBranch;               // ���Կ��Ƶ�Ԫ bne
    input        Jmp;                   // ���Կ��Ƶ�Ԫ j - jump
    input        Jal;                   // ���Կ��Ƶ�Ԫ jal - jump and link
    input        Jrn;                   // ���Կ��Ƶ�Ԫ jr - jump to reg
    input        Zero;                  // ����ִ�е�Ԫ �������ֵΪ0��Ϊ1
    input        clock,reset;           // ʱ���븴λ
    output       opcplus4;              // JALָ��ר�õ�PC+4
    
    output wire[31:0]   PC_plus_4;             // PC+4
    output reg[31:0]	  PC=32'b0;            // PC�Ĵ����������������
    output reg[31:0]    next_PC;               // ����ָ���PC����һ����PC+4)
    reg[31:0]    opcplus4;
    
   //����64KB ROM��������ʵ��ֻ�� 64KB ROM
    prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        .douta(Instruction)         // output wire [31 : 0] douta
    );
    

    // ������ľ���PC+4
    assign PC_plus_4[31:2] = PC[31:2]+1;
    assign PC_plus_4[1:0] = 2'b00; 
    assign PC_plus_4_out = PC_plus_4[31:0];
//    assign opcplus4 = PC_plus_4;

    // ���ȼ�����������µ�next_PC
    // �ӣ�next_PC,Read_data_1,Add_result��word_addressed, PC, PC_plus_4_out��byte_addressed
    always @(*) begin  // beq $n ,$m if $n=$m branch   bne if $n =/=$m branch jr
        
        if(Branch) begin // beq
            next_PC = (Zero)?Add_result >> 2:(PC_plus_4_out>>2);
        end else if (nBranch) begin // bne
            next_PC = (!Zero)?Add_result >> 2:(PC_plus_4_out>>2);
        end else  // otherwise
            next_PC = PC_plus_4_out >> 2;
        
        if(Jrn) begin // jr
            next_PC = Read_data_1;
        end
        
//        if(Jal)
//            opcplus4 = PC+8;
        
    end
    
    // Ȼ������������µ�next_PC
    // Jal_Jmp��Ҫ���⴦���� �Լ�ƴ�ӵ�ַ
   always @(negedge clock) begin  //����J��Jalָ���reset�Ĵ���
        
           if(Jal|Jmp) begin
                PC = {PC_plus_4_out[31:28], Instruction[25:0], 2'b0};
                if(Jal)
                    opcplus4 = next_PC;
           end else begin
                PC = next_PC << 2;  
           end
           
           
           if(reset) begin
              PC = 0;
              next_PC = 1;
           end
           
           
   end
endmodule
