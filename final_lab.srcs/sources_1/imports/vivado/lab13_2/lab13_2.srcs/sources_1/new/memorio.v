`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

// 数据分发: 选择与mem交互 还是和io交互

module memorio(caddress,address,memread,memwrite,ioread,iowrite,mread_data,ioread_data,wdata,rdata,write_data,LEDCtrl,SwitchCtrl);
    input[31:0] caddress;       // from alu_result in executs32
    input memread;				// read memory, from control32
    input memwrite;				// write memory, from control32
    input ioread;				// read IO, from control32
    input iowrite;				// write IO, from control32
    input[31:0] mread_data;		// data from memory
    input[15:0] ioread_data;	// data from io,16 bits
    input[31:0] wdata;			// the data from idecode32,that want to write memory or io
    
    
    output[31:0] rdata;			// data from memory or IO that want to read into register
    output[31:0] write_data;    // data to memory or I/O
    output[31:0] address;       // address to mAddress and I/O
	
    output LEDCtrl;				// LED CS (CS=chip select)
    output SwitchCtrl;          // Switch CS
    
    reg[31:0] write_data;
    wire iorw;
    
    assign  address = caddress;
    assign  rdata = (ioread)?{16'h0000,ioread_data[15:0]}:mread_data; // select data source?
    assign  iorw = (iowrite||ioread);
	
	//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	// set the chip select: when to use LED and Switch?
	assign	LEDCtrl = ((iowrite)&&(32'hFFFFFC60<=caddress&&caddress<=32'hFFFFFC62));
	assign	SwitchCtrl = ((ioread)&&(32'hFFFFFC70<=caddress&&caddress<=32'hFFFFFC72));
							
    always @* begin
        if((memwrite==1)||(iowrite==1)) begin
            write_data = (iowrite)?({16'h0000, wdata[15:0]}):wdata;   // write data accordingly?
        end else begin
            write_data = 32'hZZZZZZZZ;
        end
    end
endmodule