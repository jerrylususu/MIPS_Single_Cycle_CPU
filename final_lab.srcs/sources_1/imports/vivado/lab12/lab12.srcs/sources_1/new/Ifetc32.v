`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// 取指令，PC控制

module Ifetc32(Instruction,PC_plus_4_out,Add_result,Read_data_1,Branch,nBranch,Jmp,Jal,Jrn,Zero,clock,reset,opcplus4,
PC, next_PC, PC_plus_4);
    output[31:0] Instruction;			// 输出指令到其他模块
    output[31:0] PC_plus_4_out;         // (pc+4)送执行单元
    input[31:0]  Add_result;            // 来自执行单元,算出的跳转地址
    input[31:0]  Read_data_1;           // 来自译码单元，jr指令用的地址
    input        Branch;                // 来自控制单元 beq
    input        nBranch;               // 来自控制单元 bne
    input        Jmp;                   // 来自控制单元 j - jump
    input        Jal;                   // 来自控制单元 jal - jump and link
    input        Jrn;                   // 来自控制单元 jr - jump to reg
    input        Zero;                  // 来自执行单元 如果计算值为0则为1
    input        clock,reset;           // 时钟与复位
    output       opcplus4;              // JAL指令专用的PC+4
    
    output wire[31:0]   PC_plus_4;             // PC+4
    output reg[31:0]	  PC=32'b0;            // PC寄存器（程序计数器）
    output reg[31:0]    next_PC;               // 下条指令的PC（不一定是PC+4)
    reg[31:0]    opcplus4;
    
   //分配64KB ROM，编译器实际只用 64KB ROM
    prgrom instmem(
        .clka(clock),         // input wire clka
        .addra(PC[15:2]),     // input wire [13 : 0] addra
        .douta(Instruction)         // output wire [31 : 0] douta
    );
    

    // 这里真的就是PC+4
    assign PC_plus_4[31:2] = PC[31:2]+1;
    assign PC_plus_4[1:0] = 2'b00; 
    assign PC_plus_4_out = PC_plus_4[31:0];
//    assign opcplus4 = PC_plus_4;

    // 首先计算理想情况下的next_PC
    // 坑：next_PC,Read_data_1,Add_result是word_addressed, PC, PC_plus_4_out是byte_addressed
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
    
    // 然后处理特殊情况下的next_PC
    // Jal_Jmp需要特殊处理下 自己拼接地址
   always @(negedge clock) begin  //（含J，Jal指令和reset的处理）
        
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
