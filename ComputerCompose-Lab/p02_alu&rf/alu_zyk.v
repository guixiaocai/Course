module alu
# (
	parameter DATA_WIDTH = 32,
	parameter ALU_WIDTH = 12,
	parameter GREG_WIDTH = 5,
	parameter alu_ADD =	11,
	parameter alu_SLT = 10,
	parameter alu_AND = 9 ,
	parameter alu_SRL = 8 ,
	parameter alu_SRA = 7 ,
	parameter alu_XOR = 6 ,
	parameter alu_LUI = 5 ,
	parameter alu_SUB = 4 ,
	parameter alu_SLTU= 3 ,
	parameter alu_OR  = 2 ,
	parameter alu_SLL = 1 ,
	parameter alu_NOR = 0 
)
(
	input [ALU_WIDTH - 1  : 0]	alu_op,     // alu operation code
	input [DATA_WIDTH - 1 : 0]  operandA,	//from rs, already forwarding
	input [DATA_WIDTH - 1 : 0]  operandB,	//from rt, already forwarding
	input [GREG_WIDTH - 1 : 0]	sa,	
	input [15 : 0]				imm,
	output 						Overflow,
	output 						CarryOut,
	output 						Zero,
	
	output [DATA_WIDTH - 1 : 0]	alu_result
);
	
	wire [DATA_WIDTH : 0] add_result;
	wire [DATA_WIDTH + 1 : 0] add_opA = {1'b0,operandA[DATA_WIDTH - 1],operandA};
	wire [DATA_WIDTH + 1 : 0] add_opB = {1'b0,operandB[DATA_WIDTH - 1],operandB};
	assign Overflow = add_result[DATA_WIDTH] ^ add_result[DATA_WIDTH - 1];
	assign Zero = (operandA == operandB)? 1 : 0;
	assign {CarryOut,add_result} = alu_op[alu_ADD] ? add_opA + add_opB : 
								   add_opA - add_opB ;
			
	wire [DATA_WIDTH - 1 : 0] result_add = add_result[DATA_WIDTH - 1 : 0];
	wire [DATA_WIDTH - 1 : 0] result_slt = {31'b0,Overflow ^ add_result[DATA_WIDTH - 1]};	
	wire [DATA_WIDTH - 1 : 0] result_and = (operandA & operandB);	
	wire [DATA_WIDTH - 1 : 0] result_xor = (operandA ^ operandB);	
	wire [DATA_WIDTH - 1 : 0] result_lui = {imm,16'b0};	
	wire [DATA_WIDTH - 1 : 0] result_sub = add_result[DATA_WIDTH - 1 : 0];	
	wire [DATA_WIDTH - 1 : 0] result_sltu = {31'b0,CarryOut};
	wire [DATA_WIDTH - 1 : 0] result_or = (operandA | operandB);	
	wire [DATA_WIDTH - 1 : 0] result_nor = ~(operandA | operandB);
	wire [DATA_WIDTH - 1 : 0] result_sll = operandB << sa;	
	wire [DATA_WIDTH - 1 : 0] result_srl = operandB >> sa;	
	wire [DATA_WIDTH - 1 : 0] result_sra_tmp = {32{operandB[31]}} << (~sa);
	wire [DATA_WIDTH - 1 : 0] result_sra = (result_sra_tmp << 1) | (operandB >> sa);	
 

	assign alu_result =	{DATA_WIDTH{alu_op[alu_ADD]}} & result_add	|
						{DATA_WIDTH{alu_op[alu_SLT]}} & result_slt	|
						{DATA_WIDTH{alu_op[alu_AND]}} & result_and	|	
						{DATA_WIDTH{alu_op[alu_XOR]}} & result_xor	|
						{DATA_WIDTH{alu_op[alu_LUI]}} & result_lui	|
						{DATA_WIDTH{alu_op[alu_SUB]}} &	result_sub	|		
						{DATA_WIDTH{alu_op[alu_SLTU]}}& result_sltu	|
						{DATA_WIDTH{alu_op[alu_OR]}}  & result_or	|
						{DATA_WIDTH{alu_op[alu_NOR]}} & result_nor	|
						{DATA_WIDTH{alu_op[alu_SRL]}} & result_srl	|					
						{DATA_WIDTH{alu_op[alu_SRA]}} & result_sra	|
						{DATA_WIDTH{alu_op[alu_SLL]}} & result_sll	;							
						
endmodule
