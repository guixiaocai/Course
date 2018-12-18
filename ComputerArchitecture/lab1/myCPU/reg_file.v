`timescale 1ns / 1ps

module reg_file(
	input clk,
	input rst,
	input [4:0] waddr,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input wen,
	input [31:0] wdata,
	output [31:0] reg_rdata1,
	output [31:0] reg_rdata2
);

	reg [31:0] reg_files [0:31];
	

	always @(posedge clk or posedge rst)
	begin
		if(!rst)
			begin
				reg_files[0] <= 32'd0;
			end
		else
		begin
			if(wen && waddr != 5'd0)
				reg_files[waddr] <= wdata;
		end
	end

	assign reg_rdata1 = reg_files[raddr1];
	assign reg_rdata2 = reg_files[raddr2];

endmodule