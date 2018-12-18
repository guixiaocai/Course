`timescale 1ns / 1ps

module dataout_dealer(
	input  [5:0] opcode,
	input  [1:0] ea,
	input  [31:0] regdata,
	input  [31:0] alu_result,
	output [31:0] address,
	output [31:0] dataout,
	output [3:0] wt_strb,
	output [1:0] datasize,
	output       ld_ade,
	output       st_ade
);
	wire inst_lb,inst_lbu;
	wire inst_lh,inst_lhu;
	wire inst_lwl,inst_lw,inst_lwr;
	wire inst_sb;
	wire inst_sh;
	wire inst_swl,inst_sw,inst_swr;

	assign inst_lb  = (opcode == 6'd32);
	assign inst_lbu = (opcode == 6'd36);
	assign inst_lh  = (opcode == 6'd33);
	assign inst_lhu = (opcode == 6'd37);
	assign inst_lw  = (opcode == 6'd35);
	assign inst_lwl = (opcode == 6'd34);
	assign inst_lwr = (opcode == 6'd38);
	assign inst_sb  = (opcode == 6'd40);
	assign inst_sh  = (opcode == 6'd41);
	assign inst_sw  = (opcode == 6'd43);
	assign inst_swl = (opcode == 6'd42);
	assign inst_swr = (opcode == 6'd46);

	wire ea0,ea1,ea2,ea3;
	assign ea0 = (ea == 2'd0);
	assign ea1 = (ea == 2'd1);
	assign ea2 = (ea == 2'd2);
	assign ea3 = (ea == 2'd3);

	wire [31:0] sb_data;
	wire [31:0] sh_data;
	wire [31:0] sw_data;
	wire [31:0] swl_data;
	wire [31:0] swr_data;

	assign sb_data = ({32{ea0}} & {24'd0,regdata[7:0]})
					|({32{ea1}} & {16'd0,regdata[7:0],8'd0})
					|({32{ea2}} & {8'd0,regdata[7:0],16'd0})
					|({32{ea3}} & {regdata[7:0],24'd0});
	assign sh_data = ({32{ea0}} & {16'd0,regdata[15:0]})
					|({32{ea2}} & {regdata[15:0],16'd0});
	assign sw_data = regdata;
	assign swl_data = ({32{ea0}} & {24'd0,regdata[31:24]})
					|({32{ea1}} & {16'd0,regdata[31:16]})
					|({32{ea2}} & {8'd0,regdata[31:8]})
					|({32{ea3}} & regdata);
	assign swr_data = ({32{ea0}} & regdata)
					|({32{ea1}} & {regdata[23:0],8'd0})
					|({32{ea2}} & {regdata[15:0],16'd0})
					|({32{ea3}} & {regdata[7:0],24'd0});

	assign dataout = ({32{inst_sb }} & sb_data)
					|({32{inst_sh }} & sh_data)
					|({32{inst_sw }} & sw_data)
					|({32{inst_swl}} & swl_data)
					|({32{inst_swr}} & swr_data);

	wire [3:0] sb_wen;
	wire [3:0] sh_wen;
	wire [3:0] sw_wen;
	wire [3:0] swl_wen;
	wire [3:0] swr_wen;

	assign sb_wen  = {ea3,ea2,ea1,ea0};
	assign sh_wen  = {{2{ea2}},{2{ea0}}};
	assign sw_wen  = 4'd15;
	assign swl_wen = {ea3,(ea3|ea2),!ea0,1'd1};
	assign swr_wen = {1'd1,!ea3,(ea1|ea0),ea0};

	assign wt_strb = ({4{inst_sb }} & sb_wen)
					|({4{inst_sh }} & sh_wen)
					|({4{inst_sw }} & sw_wen)
					|({4{inst_swl}} & swl_wen)
					|({4{inst_swr}} & swr_wen);

	wire   sh_ade,sw_ade;
	assign sh_ade = inst_sh && (ea1||ea3);
	assign sw_ade = inst_sw && (ea != 2'd0);
	assign st_ade = sh_ade || sw_ade;

	wire   lh_ade,lhu_ade,lw_ade;
	assign lh_ade = inst_lh && (ea1||ea3);
	assign lhu_ade = inst_lhu && (ea1||ea3);
	assign lw_ade = inst_lw && (ea != 2'd0);
	assign ld_ade = lh_ade || lhu_ade || lw_ade;

	assign datasize = ({2{inst_lb|inst_lbu|inst_sb}} & 2'd0)
					| ({2{inst_lh|inst_lhu|inst_sh}} & 2'd1)
					| ({2{inst_lw|inst_lwl|inst_lwr|inst_sw|inst_swl|inst_swr}} & 2'd2);

	wire   inst_unalign = inst_lwr|inst_lwl|inst_swr|inst_swl;
	assign address = (inst_unalign) ? {alu_result[31:2],2'd0} : alu_result;

endmodule