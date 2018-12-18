`timescale 1ns / 1ps

module datain_dealer(
	input  [ 5:0] opcode ,
	input  [ 1:0] ea     ,
	input  [31:0] regdata,
	input  [31:0] loadin ,
	output [31:0] datain
);

	wire inst_lb,inst_lbu;
	wire inst_lh,inst_lhu;
	wire inst_lwl,inst_lw,inst_lwr;

	assign inst_lb  = (opcode == 6'd32);
	assign inst_lbu = (opcode == 6'd36);
	assign inst_lh  = (opcode == 6'd33);
	assign inst_lhu = (opcode == 6'd37);
	assign inst_lw  = (opcode == 6'd35);
	assign inst_lwl = (opcode == 6'd34);
	assign inst_lwr = (opcode == 6'd38);

	wire ea0,ea1,ea2,ea3;
	assign ea0 = (ea == 2'd0);
	assign ea1 = (ea == 2'd1);
	assign ea2 = (ea == 2'd2);
	assign ea3 = (ea == 2'd3);

	wire [31:0] lb_data;
	wire [31:0] lbu_data;
	wire [31:0] lh_data;
	wire [31:0] lhu_data;
	wire [31:0] lw_data;
	wire [31:0] lwl_data;
	wire [31:0] lwr_data;

	assign lb_data = ({32{ea0}} & {{(24){loadin[7]}},loadin[7:0]})
					|({32{ea1}} & {{(24){loadin[15]}},loadin[15:8]})
					|({32{ea2}} & {{(24){loadin[23]}},loadin[23:16]})
					|({32{ea3}} & {{(24){loadin[31]}},loadin[31:24]});
	assign lbu_data = ({32{ea0}} & {24'd0,loadin[7:0]})
					|({32{ea1}} & {24'd0,loadin[15:8]})
					|({32{ea2}} & {24'd0,loadin[23:16]})
					|({32{ea3}} & {24'd0,loadin[31:24]});
	assign lh_data = ({32{ea0}} & {{(16){loadin[15]}},loadin[15:0]})
					|({32{ea2}} & {{(16){loadin[31]}},loadin[31:16]});
	assign lhu_data = ({32{ea0}} & {16'd0,loadin[15:0]})
					|({32{ea2}} & {16'd0,loadin[31:16]});
	assign lw_data = loadin;
	assign lwl_data = ({32{ea0}} & {loadin[7:0],regdata[23:0]})
					|({32{ea1}} & {loadin[15:0],regdata[15:0]})
					|({32{ea2}} & {loadin[23:0],regdata[7:0]})
					|({32{ea3}} & loadin);
	assign lwr_data = ({32{ea0}} & loadin)
					|({32{ea1}} & {regdata[31:24],loadin[31:8]})
					|({32{ea2}} & {regdata[31:16],loadin[31:16]})
					|({32{ea3}} & {regdata[31:8],loadin[31:24]});

	assign datain = ({32{inst_lb }} & lb_data)
					|({32{inst_lbu}} & lbu_data)
					|({32{inst_lh }} & lh_data)
					|({32{inst_lhu}} & lhu_data)
					|({32{inst_lw }} & lw_data)
					|({32{inst_lwl}} & lwl_data)
					|({32{inst_lwr}} & lwr_data);
endmodule 