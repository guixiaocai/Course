`timescale 1ns / 1ps

`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_files(
	input clk,
	input resetn,
	input [`ADDR_WIDTH - 1:0] waddr,// write address
	input [`ADDR_WIDTH - 1:0] raddr1,// read address 1
	input [`ADDR_WIDTH - 1:0] raddr2,// read address 2
	input [3:0] wen,//write enable
	input [`DATA_WIDTH - 1:0] wdata,//write data
	output [`DATA_WIDTH - 1:0] rdata1,//read data 1
	output [`DATA_WIDTH - 1:0] rdata2//read data 2
);
 
reg [31:0] mem [31:0];//32 32-bit memory

always@(posedge clk)//writing logic
	begin
		if (!resetn)	begin
			mem[0] <= 32'b0;
		end
		else	begin
            mem[waddr][31:24] <= (wen[3]) ? wdata[31:24]: mem[waddr][31:24];
            mem[waddr][23:16] <= (wen[2]) ? wdata[23:16]: mem[waddr][23:16];
            mem[waddr][15:8 ] <= (wen[1]) ? wdata[15:8 ]: mem[waddr][15:8 ];
            mem[waddr][7 :0 ] <= (wen[0]) ? wdata[7 :0 ]: mem[waddr][7 :0 ];
		end
	end

//reading logic
assign rdata1 = (raddr1 == 5'd0) ?32'd0:mem[raddr1];
assign rdata2 = (raddr2 == 5'd0) ?32'd0:mem[raddr2];
	
endmodule

//输入信号的判断在wb阶段�?
module reg_hilo(
    input clk,
    input resetn,
    input [1:0] hi_wen,
    input [1:0] lo_wen,
    input [31:0] hi_in,
    input [31:0] lo_in,
    output [31:0] hi,
    output [31:0] lo
);
reg [31:0] reg_hi;
reg [31:0] reg_lo;

always@(posedge clk)
begin
    if(!resetn)
    begin
        reg_hi <= 32'd0;
    end
    else if (hi_wen)
    begin
        reg_hi <= hi_in;
    end
end

always@(posedge clk)
begin
    if(!resetn)
    begin
        reg_lo <= 32'd0;
    end
    else if (lo_wen)
    begin
        reg_lo <= lo_in;
    end
end

assign hi = reg_hi;
assign lo = reg_lo;

endmodule



