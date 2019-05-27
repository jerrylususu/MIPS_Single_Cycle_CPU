`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// 5/23 �������� ALU_ctl, Ainput, Binput, Branch_Add

module Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
                 Shamt,ALUSrc,I_format,Jrn,Zero,Sftmd,ALU_Result,Add_Result,PC_plus_4,
                 ALU_ctl, Ainput, Binput, Branch_Add  // debug����
                 );
    input[31:0]  Read_data_1;		// �����뵥Ԫ��Read_data_1����
    input[31:0]  Read_data_2;		// �����뵥Ԫ��Read_data_2����
    input[31:0]  Sign_extend;		// �����뵥Ԫ������չ���������
    input[5:0]   Function_opcode;  	// ȡָ��Ԫ����r-����ָ�����,r-form instructions[5:0]
    input[5:0]   Exe_opcode;  		// ȡָ��Ԫ���Ĳ����룬instruction[31:26]
    input[1:0]   ALUOp;             // ����ָ����Ʊ��룺 { (R_format || I_format) , (Branch || nBranch) } һ�������ź�
    input[4:0]   Shamt;             // ����ȡָ��Ԫ��instruction[10:6]��ָ����λ����
    input  		 Sftmd;             // ���Կ��Ƶ�Ԫ�ģ�1��������λָ��
    input        ALUSrc;            // ���Կ��Ƶ�Ԫ��1�����ڶ�������������������beq��bne���⣩
    input        I_format;          // ���Կ��Ƶ�Ԫ��1�����ǳ�beq, bne, LW, SW֮���I-����ָ��
    input        Jrn;               // ���Կ��Ƶ�Ԫ��1������JRָ��
    output       Zero;              // output 1 if 0
    output[31:0] ALU_Result;        // ��������ݽ��
    output[31:0] Add_Result;		// ����ĵ�ַ��� 
    input[31:0]  PC_plus_4;         // ����ȡָ��Ԫ��PC+4
    
    reg[31:0] ALU_Result;    //ִ�е�Ԫ�����
    output wire[31:0] Ainput,Binput; //����ALU����λ���������������
    reg[31:0] Sinput; //��λ����Ľ��
    reg[31:0] ALU_output_mux;  //�����������߼���������
    output wire[31:0] Branch_Add;
    output wire[2:0] ALU_ctl; // ����1 2�������ź��γɵ������
    wire[5:0] Exe_code; // ���������ź�
    wire[2:0] Sftm;
    wire Sftmd;
    
    assign Sftm = Function_opcode[2:0];   // only need low 3 bit
    assign Exe_code = (I_format==0) ? Function_opcode : {3'b000,Exe_opcode[2:0]};
    assign Ainput = Read_data_1;
    assign Binput = (ALUSrc == 0) ? Read_data_2 : Sign_extend[31:0]; //R/LW,SW  sft  when else have LW SW
    assign ALU_ctl[0] = (Exe_code[0] | Exe_code[3]) & ALUOp[1];      //24H AND 
    assign ALU_ctl[1] = ((!Exe_code[2]) | (!ALUOp[1]));
    assign ALU_ctl[2] = (Exe_code[1] & ALUOp[1]) | ALUOp[0];
 


always @* begin  // 6 different move inst
       if(Sftmd)
        case(Sftm[2:0]) // ��λ�������û���⣿�����а���
            3'b000:Sinput = Binput << Shamt;			   //Sll rd,rt,shamt  00000
            3'b010:Sinput = Binput >> Shamt; 		       //Srl rd,rt,shamt  00010
            3'b100:Sinput = Binput << Ainput;                   //Sllv rd,rt,rs 000100
            3'b110:Sinput = Binput >> Ainput;                   //Srlv rd,rt,rs 000110
            3'b011:Sinput = $signed(Binput) >>> Shamt;         		//Sra rd,rt,shamt 00011
            3'b111:Sinput = $signed(Binput) >>> Ainput;		        //Srav rd,rt,rs 00111
            default:Sinput = Binput;
        endcase
       else Sinput = Binput;
    end
 
//    always @* begin
//        if(((ALU_ctl==3'b111) && (Exe_code[3]==1))||((ALU_ctl[2:1]==2'b11) && (I_format==1))) //slti(sub)  handle all SLT
//            ALU_Result = (ALU_output_mux<0)? 32'h00000001:32'h00000000 ;  // according to minus result?
//        else if((ALU_ctl==3'b101) && (I_format==1)) ALU_Result[31:0] = {Sign_extend[15:0], 16'b0};   //lui data
//        else if(Sftmd==1) ALU_Result = Sinput;   //  handle digit move, just from Sinput
//        else  ALU_Result = ALU_output_mux[31:0];   //otherwise
//    end
    
    always @* begin // ���Ѿ��������ֶ�������...
        if(Sftmd==1) ALU_Result = Sinput;   //  handle digit move, just from Sinput
        else  ALU_Result = ALU_output_mux[31:0];   //otherwise
    end
 
    assign Branch_Add = PC_plus_4[31:0] + Sign_extend[31:0];
    assign Add_Result = Branch_Add[31:0];   //�������һ��PCֵ�Ѿ����˳�4�������Բ�������16λ
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput&Binput; // ����and ��������
            3'b001:ALU_output_mux = Ainput|Binput; // ����or ��������
            3'b010:ALU_output_mux = $signed(Ainput)+$signed(Binput); // ����add ��������
            3'b011:ALU_output_mux = $unsigned(Ainput)+$unsigned(Binput); // ����addu ��������
            3'b100:ALU_output_mux = Ainput^Binput; // ����xor ��������
            3'b101:begin // ��Ҫ����nor��lui�Ĳ�ͬ����
                if(Exe_opcode==6'b000000&&Function_opcode==6'b100111) // nor
                    ALU_output_mux = ~(Ainput|Binput);
                else // lui
                    ALU_output_mux = {Sign_extend[15:0], 16'b0}; // �˴��������������ʵ��...
            end 
            3'b110:begin // ��Ҫ����sub, beq/bne �� slti
                if(Exe_opcode==6'b000000&&Function_opcode==6'b100010) // sub
                    ALU_output_mux = $signed(Ainput)-$signed(Binput);
                else if (Exe_opcode==6'b000100||Function_opcode==6'b000101) // bne, beq
                    ALU_output_mux = Ainput-Binput;
                else // slti
                    ALU_output_mux = ($signed(Ainput)<$signed(Binput))?1:0;
            end
            3'b111:begin // ��Ҫ���� subu, sltiu, slt, sltu
                if(Exe_opcode==6'b000000&&Function_opcode==6'b100011) // subu
                    ALU_output_mux = $unsigned(Ainput)-$unsigned(Binput);
                else if (Exe_opcode==6'b001011||(Exe_opcode==6'b000000&&Function_opcode==66'b101011)) // sltiu, sltu
                    ALU_output_mux = ($unsigned(Ainput)<$unsigned(Binput))?1:0;
                else // slt
                    ALU_output_mux = ($signed(Ainput)<$signed(Binput))?1:0;
            end
            default:ALU_output_mux = 32'h00000000;
        endcase
    end
endmodule
