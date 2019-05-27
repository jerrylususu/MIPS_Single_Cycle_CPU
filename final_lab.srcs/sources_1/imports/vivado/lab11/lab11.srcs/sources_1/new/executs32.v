`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// 5/23 调试增加 ALU_ctl, Ainput, Binput, Branch_Add

module Executs32(Read_data_1,Read_data_2,Sign_extend,Function_opcode,Exe_opcode,ALUOp,
                 Shamt,ALUSrc,I_format,Jrn,Zero,Sftmd,ALU_Result,Add_Result,PC_plus_4,
                 ALU_ctl, Ainput, Binput, Branch_Add  // debug增加
                 );
    input[31:0]  Read_data_1;		// 从译码单元的Read_data_1中来
    input[31:0]  Read_data_2;		// 从译码单元的Read_data_2中来
    input[31:0]  Sign_extend;		// 从译码单元来的扩展后的立即数
    input[5:0]   Function_opcode;  	// 取指单元来的r-类型指令功能码,r-form instructions[5:0]
    input[5:0]   Exe_opcode;  		// 取指单元来的操作码，instruction[31:26]
    input[1:0]   ALUOp;             // 运算指令控制编码： { (R_format || I_format) , (Branch || nBranch) } 一级控制信号
    input[4:0]   Shamt;             // 来自取指单元的instruction[10:6]，指定移位次数
    input  		 Sftmd;             // 来自控制单元的，1表明是移位指令
    input        ALUSrc;            // 来自控制单元，1表明第二个操作数是立即数（beq，bne除外）
    input        I_format;          // 来自控制单元，1表明是除beq, bne, LW, SW之外的I-类型指令
    input        Jrn;               // 来自控制单元，1表明是JR指令
    output       Zero;              // output 1 if 0
    output[31:0] ALU_Result;        // 计算的数据结果
    output[31:0] Add_Result;		// 计算的地址结果 
    input[31:0]  PC_plus_4;         // 来自取指单元的PC+4
    
    reg[31:0] ALU_Result;    //执行单元的输出
    output wire[31:0] Ainput,Binput; //参与ALU及移位运算的两个运算数
    reg[31:0] Sinput; //移位运算的结果
    reg[31:0] ALU_output_mux;  //算术运算与逻辑运算的输出
    output wire[31:0] Branch_Add;
    output wire[2:0] ALU_ctl; // 根据1 2级控制信号形成的组合码
    wire[5:0] Exe_code; // 二级控制信号
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
        case(Sftm[2:0]) // 移位这里真的没问题？可能有暗坑
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
    
    always @* begin // 都已经在下面手动处理了...
        if(Sftmd==1) ALU_Result = Sinput;   //  handle digit move, just from Sinput
        else  ALU_Result = ALU_output_mux[31:0];   //otherwise
    end
 
    assign Branch_Add = PC_plus_4[31:0] + Sign_extend[31:0];
    assign Add_Result = Branch_Add[31:0];   //算出的下一个PC值已经做了除4处理，所以不需左移16位
    assign Zero = (ALU_output_mux[31:0]== 32'h00000000) ? 1'b1 : 1'b0;
    
    always @(ALU_ctl or Ainput or Binput) begin
        case(ALU_ctl)
            3'b000:ALU_output_mux = Ainput&Binput; // 都是and 无需区别
            3'b001:ALU_output_mux = Ainput|Binput; // 都是or 无需区别
            3'b010:ALU_output_mux = $signed(Ainput)+$signed(Binput); // 都是add 无需区别
            3'b011:ALU_output_mux = $unsigned(Ainput)+$unsigned(Binput); // 都是addu 无需区别
            3'b100:ALU_output_mux = Ainput^Binput; // 都是xor 无需区别
            3'b101:begin // 需要区分nor和lui的不同操作
                if(Exe_opcode==6'b000000&&Function_opcode==6'b100111) // nor
                    ALU_output_mux = ~(Ainput|Binput);
                else // lui
                    ALU_output_mux = {Sign_extend[15:0], 16'b0}; // 此处可能是有问题的实现...
            end 
            3'b110:begin // 需要区分sub, beq/bne 和 slti
                if(Exe_opcode==6'b000000&&Function_opcode==6'b100010) // sub
                    ALU_output_mux = $signed(Ainput)-$signed(Binput);
                else if (Exe_opcode==6'b000100||Function_opcode==6'b000101) // bne, beq
                    ALU_output_mux = Ainput-Binput;
                else // slti
                    ALU_output_mux = ($signed(Ainput)<$signed(Binput))?1:0;
            end
            3'b111:begin // 需要区分 subu, sltiu, slt, sltu
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
