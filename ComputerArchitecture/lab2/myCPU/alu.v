module alu(
    input  [31:0] alu_src1,
    input  [31:0] alu_src2,
    input  [ 3:0] alu_op,
    output [31:0] alu_result_ex
);

    wire [31:0] result_and;		//0000
	wire [31:0] result_or;		//0001
	wire [31:0] result_add;		//0010
	wire [31:0] result_lui;		//0011
	wire [31:0] result_nor;		//0100
	wire [31:0] result_sltu;	//0101
	wire [31:0] result_sub;		//0110
	wire [31:0] result_slt;		//0111
	wire [31:0] result_xor;		//1000
	wire [31:0] result_sll;		//1001
	wire [31:0] result_sra;		//1010
	wire [31:0] result_srl;		//1011
	wire [32:0] slt;

	assign result_and = alu_src1 & alu_src2;
	assign result_or  = alu_src1 | alu_src2;
	assign result_add = alu_src1 + alu_src2;
	assign result_lui = {alu_src2[15:0], 16'd0};
	assign result_sub = alu_src1 + ~alu_src2 + 32'd1;
	assign result_xor = alu_src1 ^ alu_src2;
	assign result_nor = ~(alu_src1 | alu_src2);
	assign result_sll = alu_src2 << alu_src1[4:0];
	assign result_srl = alu_src2 >> alu_src1[4:0];
	assign result_sra = ~alu_src2[31] ? alu_src2 >> alu_src1[4:0] :
					   (alu_src2 >> alu_src1[4:0]|(~(32'hffffffff >> alu_src1[4:0])));	


	assign slt         = {alu_src1[31],alu_src1} + ~({alu_src2[31], alu_src2} + 33'h1ffffffff);
	assign result_slt  = {31'd0, slt[32]};	
	assign result_sltu = ({1'b0, alu_src1} < {1'b0, alu_src2}) ? 32'd1 : 32'd0;



    assign alu_result_ex = (result_and  & {32{(~alu_op[3] & ~alu_op[2] & ~alu_op[1] & ~alu_op[0])}}) |
	                   	   (result_or   & {32{(~alu_op[3] & ~alu_op[2] & ~alu_op[1] &  alu_op[0])}}) |
                           (result_add  & {32{(~alu_op[3] & ~alu_op[2] &  alu_op[1] & ~alu_op[0])}}) |
                           (result_sub  & {32{(~alu_op[3] &  alu_op[2] &  alu_op[1] & ~alu_op[0])}}) |
                           (result_slt  & {32{(~alu_op[3] &  alu_op[2] &  alu_op[1] &  alu_op[0])}}) | 
                           (result_xor  & {32{( alu_op[3] & ~alu_op[2] & ~alu_op[1] & ~alu_op[0])}}) | 
                           (result_lui  & {32{(~alu_op[3] & ~alu_op[2] &  alu_op[1] &  alu_op[0])}}) | 
                           (result_nor  & {32{(~alu_op[3] &  alu_op[2] & ~alu_op[1] & ~alu_op[0])}}) | 
                           (result_sll  & {32{( alu_op[3] & ~alu_op[2] & ~alu_op[1] &  alu_op[0])}}) | 
                           (result_srl  & {32{( alu_op[3] & ~alu_op[2] &  alu_op[1] &  alu_op[0])}}) | 
                           (result_sra  & {32{( alu_op[3] & ~alu_op[2] &  alu_op[1] & ~alu_op[0])}}) | 
                           (result_sltu & {32{(~alu_op[3] &  alu_op[2] & ~alu_op[1] &  alu_op[0])}}) ;

endmodule