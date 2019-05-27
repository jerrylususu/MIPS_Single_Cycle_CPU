`timescale 1ns / 1ps

// �Դ������������
// ����testcase1

module minisys_sim();
    // input
    reg clk = 0;
    reg rst = 1;
    reg switch2N4 = 8'b10101100; // �����������û���⣿
    
    // output
    wire led2N4;
    
    cpu u(.highclk(clk),.rst(rst),.led2N4(led2N4),.switch2N4(switch2N4));
    
    initial begin;
        #7000 rst = 0;
    end
    always #10 clk = ~clk; // �����������û���⣿

endmodule
