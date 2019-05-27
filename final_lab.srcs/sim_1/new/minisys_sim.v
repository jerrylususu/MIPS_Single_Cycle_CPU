`timescale 1ns / 1ps

// 自带的最基础测试
// 基于testcase1

module minisys_sim();
    // input
    reg clk = 0;
    reg rst = 1;
    reg switch2N4 = 8'b10101100; // 这样声明真的没问题？
    
    // output
    wire led2N4;
    
    cpu u(.highclk(clk),.rst(rst),.led2N4(led2N4),.switch2N4(switch2N4));
    
    initial begin;
        #7000 rst = 0;
    end
    always #10 clk = ~clk; // 这样仿真真的没问题？

endmodule
