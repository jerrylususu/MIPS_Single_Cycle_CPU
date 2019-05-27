`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module Idecode32(read_data_1,read_data_2,Instruction,read_data,ALU_result,
                 Jal,RegWrite,MemtoReg,RegDst,Sign_extend,clock,reset, opcplus4, register);
    output[31:0] read_data_1;               // 1st op
    output[31:0] read_data_2;               // 2nd op
    input[31:0]  Instruction;               // inst in
    input[31:0]  read_data;   				//  data read, need to write later
    input[31:0]  ALU_result;   				// calc result from ALU, need 32 bit expend
    input        Jal;                       //  from control, specify JAL
    input        RegWrite;                  // from control
    input        MemtoReg;                  // from control
    input        RegDst;                    //  from control
    output reg [31:0] Sign_extend;          // 32 bit after expanding, using a reg?
    input		 clock,reset;               // clk,rst
    input[31:0]  opcplus4;                  // used in JAL
    output reg[31:0] register[0:31];        // 32*32 bit reg

    wire[31:0] read_data_1;
    wire[31:0] read_data_2;
    
    reg[4:0] write_register_address;        // the id of reg to write into 
    reg[31:0] write_data;                   // the data to write into

    wire[4:0] read_register_1_address;    // rs, 1st read
    wire[4:0] read_register_2_address;     // rt, 2nd read
    wire[4:0] write_register_address_1;   // r-form write, rd
    wire[4:0] write_register_address_0;    // i-form write, rt
    wire[15:0] Instruction_immediate_value;  // immedia
    wire[5:0] opcode;                       // opcode
    
    assign opcode = Instruction[31:26];	//OP code
    assign read_register_1_address = Instruction[25:21];//rs 
    assign read_register_2_address = Instruction[20:16];//rt 
    assign write_register_address_1 = Instruction[15:11];// rd(r-form)
    assign write_register_address_0 = Instruction[20:16];//rt(i-form)
    assign Instruction_immediate_value = Instruction[15:0];//data,rladr(i-form)


    wire sign;                                            // the value of sign digit

    // sign-extend
    assign sign = Instruction_immediate_value[15];
//    assign Sign_extend[31:0] = {{16{sign}}, Instruction_immediate_value};
    always @* begin // do expansion
        if(opcode==12||opcode==13) // ZeroExtImm
            Sign_extend[31:0] = {{16{1'b0}}, Instruction_immediate_value};
        else if (opcode==4||opcode==5) // BranchAddr
            Sign_extend[31:0] = {{14{sign}}, Instruction_immediate_value,2'b0};
//            Sign_extend[31:0] = {{14{sign}}, Instruction_immediate_value};
        else // SignExtImm
            Sign_extend[31:0] = {{16{sign}}, Instruction_immediate_value};
    end
    
    assign read_data_1 = register[read_register_1_address];
    assign read_data_2 = register[read_register_2_address];
    
    // determine inst type
    // https://stackoverflow.com/questions/20336508/how-to-know-mips-instruction-format-r-i-or-j
    // 合并警告：此处是否应该使用来自control的RegDst？ 可能暗坑
    always @* begin                                            //set different target reg
        if(Jal) begin // if jal, then must write to 31
            write_register_address = 31;
        end else begin
            if(opcode==0) begin
                // R-type, just use rd
                write_register_address = write_register_address_1;
            end else if (opcode==2||opcode==3) begin
                // J-type, no need to specify?
            end else begin
                // I-type, just use rt
                write_register_address = write_register_address_0;
            end
        end
    end
    
    always @* begin  //prepare MUX, prepare data to write
           write_data = (MemtoReg)?read_data:ALU_result;
           write_data = (Jal)?opcplus4:write_data; 
     end
    
    integer i;
    always @(posedge clock) begin       // write dest reg
        if(reset==1) begin              // init reg
            for(i=0;i<32;i=i+1) register[i] <= 0; // write 0?
//        for(i=0;i<32;i=i+1) register[i] <= i; // write 0?
        end else if(RegWrite==1) begin  // reg 0 always 0
            if(write_register_address!=0)
                register[write_register_address] <= write_data;
        end
    end
endmodule
