`timescale 1ns / 1ps

module alu(
	input [31:0] A,
	input [31:0] B,
	input [3:0] ALUop,
	output Zero,
	output [31:0] ALU_Result
);	

	wire [31:0] result_and;//0000
	wire [31:0] result_or;//0001
	wire [31:0] result_add;//0010
	wire [31:0] result_lui;//0011
	wire [31:0] result_nor;//0100
	wire [31:0] result_sltu;//0101
	wire [31:0] result_sub;//0110
	wire [31:0] result_slt;//0111
	wire [31:0] result_xor;//1000
	wire [31:0] result_sll;//1001
	wire [31:0] result_sra;//1010
	wire [31:0] result_srl;//1011	

	wire [32:0] u_A, u_B;
	wire [32:0] slt;	

	assign result_and = A & B;
	assign result_or = A | B;
	assign result_add = A + B;
	assign result_lui = {B[15:0], 16'd0};
	assign result_sub = A + ~(B + 32'hffffffff);
	assign result_xor = A ^ B;
	assign result_nor = ~(A | B);
	assign result_sll = B << A[4:0];
	assign result_srl = B >> A[4:0];
	assign result_sra = ~B[31] ? B >> A[4:0] : (B >> A[4:0]|(~(32'hffffffff >> A[4:0])));	

	assign slt = {A[31],A} + ~({B[31], B} + 33'h1ffffffff);
	assign result_slt = {31'd0, slt[32]};	
	assign result_sltu = (u_A < u_B) ? 32'd1 : 32'd0;

	assign u_A = {1'b0, A};
	assign u_B = {1'b0, B};

    assign ALU_Result = (result_and  & {32{(~ALUop[3] & ~ALUop[0] & ~ALUop[1] & ~ALUop[2])}}) |
	                    (result_or   & {32{(~ALUop[3] &  ALUop[0] & ~ALUop[1] & ~ALUop[2])}}) |
                        (result_add  & {32{(~ALUop[3] & ~ALUop[0] &  ALUop[1] & ~ALUop[2])}}) |
                        (result_sub  & {32{(~ALUop[3] & ~ALUop[0] &  ALUop[1] &  ALUop[2])}}) |
                        (result_slt  & {32{(~ALUop[3] &  ALUop[0] &  ALUop[1] &  ALUop[2])}}) | 
                        (result_xor  & {32{( ALUop[3] & ~ALUop[0] & ~ALUop[1] & ~ALUop[2])}}) | 
                        (result_lui  & {32{(~ALUop[3] & ~ALUop[2] &  ALUop[1] &  ALUop[0])}}) | 
                        (result_nor  & {32{(~ALUop[3] &  ALUop[2] & ~ALUop[1] & ~ALUop[0])}}) | 
                        (result_sll  & {32{( ALUop[3] & ~ALUop[2] & ~ALUop[1] &  ALUop[0])}}) | 
                        (result_srl  & {32{( ALUop[3] & ~ALUop[2] &  ALUop[1] &  ALUop[0])}}) | 
                        (result_sra  & {32{( ALUop[3] & ~ALUop[2] &  ALUop[1] & ~ALUop[0])}}) | 
                        (result_sltu & {32{(~ALUop[3] &  ALUop[2] & ~ALUop[1] &  ALUop[0])}});

	assign Zero = !ALU_Result ? 32'd1 : 32'd0;

endmodule