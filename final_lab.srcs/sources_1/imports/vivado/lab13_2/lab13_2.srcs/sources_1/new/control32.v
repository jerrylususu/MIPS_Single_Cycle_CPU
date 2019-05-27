`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
module control32(Opcode,Function_opcode,Alu_resultHigh,Jrn,RegDST,ALUSrc,MemorIOtoReg,RegWrite,MemRead,MemWrite,
IORead,IOWrite,Branch,nBranch,Jmp,Jal,I_format,Sftmd,ALUOp);
    input[5:0]   Opcode;            // ����ȡָ��Ԫinstruction[31..26]
    input[5:0]   Function_opcode;  	// ����ȡָ��Ԫr-���� instructions[5..0]
    output       Jrn;         	    // Ϊ1������ǰָ����jr
    output       RegDST;            // Ϊ1����Ŀ�ļĴ�����rd������Ŀ�ļĴ�����rt
    output       ALUSrc;            // Ϊ1�����ڶ�������������������beq��bne���⣩
//    output       MemtoReg;      	//  Ϊ1������Ҫ�Ӵ洢�������ݵ��Ĵ���  -> �Ѿ�����
    output       RegWrite;   	    //  Ϊ1������ָ����Ҫд�Ĵ���
    output       MemWrite;   	    //  Ϊ1������ָ����Ҫд�洢��
    output       Branch;    	    //  Ϊ1������Beqָ��
    output       nBranch;   	    //  Ϊ1������Bneָ��
    output       Jmp;        	    //  Ϊ1������Jָ��
    output       Jal;        	    //  Ϊ1������Jalָ��
    output       I_format;  	    //  Ϊ1������ָ���ǳ�beq��bne��LW��SW֮�������I-����ָ��
    output       Sftmd;     	    //  Ϊ1��������λָ��
    output[1:0]  ALUOp;	            //  ��R-���ͻ�I_format=1ʱλ1Ϊ1, beq��bneָ����λ0Ϊ1
   
    // lab13�¼��� IO�ӿ�
    input[21:0]  Alu_resultHigh;  // ��Alu_result��ȡ��22λ ���ȫ1��ΪIO����
    output       MemorIOtoReg;    // ��Ҫ�����ݵ�reg
    output       MemRead;         // �洢����
    output       IORead;          // IO��
    output       IOWrite;         // IOд
    
   
    wire Jmp,I_format,Jal,Branch,nBranch;
    wire R_format;        // Ϊ1��ʾ��R-����ָ��
    wire Lw;               // Ϊ1��ʾ��lwָ��
    wire Sw;               // Ϊ1��ʾ��swָ��
   
    assign R_format = (Opcode==6'b000000)? 1'b1:1'b0;    	//--00h 
    assign RegDST = R_format;                               //˵��Ŀ����rd��������rt

    assign I_format = (Opcode[5:3]==3'b001); // ? <- �ƺ�������load/save����һ���� <- û���� ��ע��
    assign Lw = (Opcode==6'b100011);
    assign Jal = (Opcode==6'b000011);
    assign Jrn = (Opcode==6'b000000&&Function_opcode==6'b001000);
    assign RegWrite = (I_format||Lw||Jal||R_format)&&(!Jrn);
    
    // lab13�¼��� IO�ӿ�
    assign MemWrite = ((Sw==1)&(Alu_resultHigh[21:0]!=22'b1111111111111111111111)) ? 1'b1:1'b0;
    assign MemRead = ((Lw==1)&(Alu_resultHigh[21:0]!=22'b1111111111111111111111)) ? 1'b1:1'b0;
    assign IORead = ((Lw==1)&(Alu_resultHigh[21:0]==22'b1111111111111111111111)) ? 1'b1:1'b0;
    assign IOWrite = ((Sw==1)&(Alu_resultHigh[21:0]==22'b1111111111111111111111)) ? 1'b1:1'b0;
    assign MemorIOtoReg = IORead || MemRead;

    assign Sw = (Opcode==6'b101011);
    assign ALUSrc = I_format||(MemWrite||IOWrite||MemorIOtoReg); // �ܲ�ȷ��...
    assign Branch = (Opcode==6'b000100);
    assign nBranch = (Opcode==6'b000101);
    assign Jmp = (Opcode==6'b000010);
    
    //assign MemWrite = (Opcode[5]==1&&Opcode[3]==1); // ��save���֣�
    //assign MemtoReg = (Opcode[5]==1&&Opcode[3]==0); // ��load���֣�
    assign Sftmd = (Opcode==6'b000000&&Function_opcode[5:3]==2'b000); // ����sll,slr?
  
    assign ALUOp = {(R_format || I_format),(Branch || nBranch)};  // ��R��type����Ҫ��������32λ��չ��ָ��1λΪ1,beq��bneָ����0λΪ1
endmodule
