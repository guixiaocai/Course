`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/09/06 22:12:26
// Design Name: 
// Module Name: ctrl_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module control_unit(
	input [5:0] op,
	inout [5:0] func,
	input [4:0] rt,
	input Zero, 
	input [31:0] ALU_Result,
	input [31:0] reg_rdata1,
	output [12:0] Ctrl,
	output [3:0] ALUop,
	output [3:0] Write_strb
);
	parameter ADDIU = 6'b001001, LW = 6'b100011, SW = 6'b101011, BNE = 6'b000101, NOP = 6'b000000, ADDU = 6'b100001, BEQ = 6'b000100, LUI = 6'b001111, SUBU = 6'b100011, SLL = 6'b000000, SLTI = 6'b001010, SLT = 6'b101010, SLTIU = 6'b001011, OR = 6'b100101, ORI = 6'b001101, AND = 6'b100100, MOVE = 6'b100101, J = 6'b000010, JAL = 6'b000011, JR = 6'b001000, ANDI = 6'b001100, BGEZ = 5'b00001, BLEZ = 6'b000110, BLTZ = 5'b00000, JALR = 6'b001001, LB = 6'b100000, LBU = 6'b100100, LH = 6'b100001, LHU = 6'b100101, LWL = 6'b100010, LWR = 6'b100110, MOVN = 6'b001011, MOVZ = 6'b001010, NOR = 6'b100111, SB = 6'b101000, SH = 6'b101001, SLLV = 6'b000100, SLTU = 6'b101011, SRA = 6'b000011, SRAV = 6'b000111, SRL = 6'b000010, SRLV = 6'b000110, SWL = 6'b101010, SWR = 6'b101110, XOR = 6'b100110, XORI = 6'b001110, BGTZ = 6'b000111;
	wire RegDst, Mem2Reg, ALUsrcB, RegWrite, PCsrc, Jump, Jr, Jal, Jalr, ExtSel, Store, op_lb, op_jalr, op_lui, op_addiu, op_subu, op_slt, op_sltu, op_and, op_or, op_xor, op_nor, op_sll, op_srl, op_sra, op_lw, op_sw, op_beq, op_bne, op_jal, op_jr, op_addu, op_sub, op_slti, op_sltiu, op_andi, op_ori, op_xori, op_sllv, op_srav, op_srlv, op_j, op_bgez, op_blez, op_lbu, op_lh, op_lhu, op_lwl, op_lwr, op_sb, op_sh, op_swl, op_swr, op_bltz, op_bgtz, op_movz, op_movn;
	wire [1:0] ALUsrcA;

	assign op_lw = (op == LW) ? 1'b1 : 1'b0;
	assign op_lwl = (op == LWL) ? 1'b1 : 1'b0;
	assign op_lwr = (op == LWR) ? 1'b1 : 1'b0;
	assign op_lb = (op == LB) ? 1'b1 : 1'b0;
	assign op_lbu = (op == LBU) ? 1'b1 : 1'b0;
	assign op_lh = (op == LH) ? 1'b1 : 1'b0;
	assign op_lhu = (op == LHU) ? 1'b1 : 1'b0;
	assign op_sw = (op == SW) ? 1'b1 : 1'b0;
	assign op_swl = (op == SWL) ? 1'b1 : 1'b0;
	assign op_swr = (op == SWR) ? 1'b1 : 1'b0;
	assign op_sb = (op == SB) ? 1'b1 : 1'b0;
	assign op_sh = (op == SH) ? 1'b1 : 1'b0;
	assign op_bne = (op == BNE) ? 1'b1 : 1'b0;
	assign op_addiu = (op == ADDIU) ? 1'b1 : 1'b0;
	assign op_beq = (op == BEQ) ? 1'b1 : 1'b0;
	assign op_lui = (op == LUI) ? 1'b1 : 1'b0;
	assign op_slti = (op == SLTI) ? 1'b1 : 1'b0;
	assign op_sltiu = (op == SLTIU) ? 1'b1 : 1'b0;
	assign op_andi = (op == ANDI) ? 1'b1 : 1'b0;
	assign op_ori = (op == ORI) ? 1'b1 : 1'b0;
	assign op_xori = (op == XORI) ? 1'b1 : 1'b0;
	assign op_j = (op == J) ? 1'b1 : 1'b0;
	assign op_jal = (op == JAL) ? 1'b1 : 1'b0;
	assign op_blez = (op == BLEZ) ? 1'b1 : 1'b0;
	assign op_bgtz = (op == BGTZ) ? 1'b1 : 1'b0;
	assign op_bgez = (op == 6'd1 && rt == BGEZ) ? 1'b1 : 1'b0;
	assign op_bltz = (op == 6'd1 && rt == BLTZ) ? 1'b1 : 1'b0;
	assign op_jr = (op == 6'd0 && func == JR) ? 1'b1 : 1'b0;
	assign op_jalr = (op == 6'd0 && func == JALR) ? 1'b1 : 1'b0;
	assign op_addu = (op == 6'd0 && func == ADDU) ? 1'b1 : 1'b0;
	assign op_subu = (op == 6'd0 && func == SUBU) ? 1'b1 : 1'b0;
	assign op_sll = (op == 6'd0 && func == SLL) ? 1'b1 : 1'b0;
	assign op_slt = (op == 6'd0 && func == SLT) ? 1'b1 : 1'b0;
	assign op_sltu = (op == 6'd0 && func == SLTU) ? 1'b1 : 1'b0;
	assign op_and = (op == 6'd0 && func == AND) ? 1'b1 : 1'b0;
	assign op_or = (op == 6'd0 && func == OR) ? 1'b1 : 1'b0;
	assign op_nor = (op == 6'd0 && func == NOR) ? 1'b1 : 1'b0;
	assign op_xor = (op == 6'd0 && func == XOR) ? 1'b1 : 1'b0;
	assign op_sll = (op == 6'd0 && func == SLL) ? 1'b1 : 1'b0;
	assign op_sllv = (op == 6'd0 && func == SLLV) ? 1'b1 : 1'b0;
	assign op_srl = (op == 6'd0 && func == SRL) ? 1'b1 : 1'b0;
	assign op_sra = (op == 6'd0 && func == SRA) ? 1'b1 : 1'b0;
	assign op_srlv = (op == 6'd0 && func == SRLV) ? 1'b1 : 1'b0;
	assign op_srav = (op == 6'd0 && func == SRAV) ? 1'b1 : 1'b0;
	assign op_movz = (op == 6'd0 && func == MOVZ) ? 1'b1 : 1'b0;
	assign op_movn = (op == 6'd0 && func == MOVN) ? 1'b1 : 1'b0;


	assign Jump = op_j;
	assign Jr = op_jr;
	assign Jal = op_jal;
	assign Jalr = op_jalr;
	assign Mem2Reg = op_lw | op_lwl | op_lwr | op_lb | op_lbu | op_lh | op_lhu;
	assign Store = op_sw | op_swl | op_swr | op_sb | op_sh;
	assign RegDst = (op == 6'd0) ? 1'b1 : 1'b0;
	assign RegWrite = Mem2Reg | op_addiu | op_lui | op_slti | op_sltiu | op_andi | op_ori | op_xori | op_jal | (!op & ~(op_movn & Zero) | ~(op_movz & ~Zero));
	assign PCsrc =  (op_bne & ~Zero) | (op_beq & Zero) | (op_bgez & (reg_rdata1 >= 32'd0)) | (op_bltz & (reg_rdata1 < 32'd0)) | (op_blez & (reg_rdata1 <= 32'd0)) | (op_bgtz & (reg_rdata1 > 32'd0));
	assign ExtSel = Mem2Reg | Store | op_bne | op_addiu | op_beq | op_sltiu | op_slti | op_j | op_jal | op_bgez | op_blez | op_bgtz | op_bltz | (!op & ~op_sltu);
	assign ALUsrcB = Mem2Reg | Store | op_addiu | op_lui | op_slti | op_sltiu | op_andi | op_ori | op_xori | op_jal;

	assign ALUsrcA = (op_movn | op_movz       ) ? 2'd1:
	                 (op_sll | op_srl | op_sra) ? 2'd2:
					                              2'd0;

	assign Ctrl = {Jump, Jr, Jal, Jalr, Mem2Reg, Store, RegDst, RegWrite, PCsrc, ExtSel, ALUsrcB, ALUsrcA};

	assign ALUop = (op_andi | op_and                    ) ? 4'd0:
	               (op_ori | op_or | op_movn | op_movz  ) ? 4'd1:
				   (Mem2Reg | Store | op_addiu | op_addu) ? 4'd2:
				   (op_lui                              ) ? 4'd3:
				   (op_nor                              ) ? 4'd4:
				   (op_sltu                             ) ? 4'd5:
				   (op_bne | op_beq | op_subu           ) ? 4'd6:
				   (op_slti | op_slt | op_sltiu         ) ? 4'd7:
				   (op_xor                              ) ? 4'd8:
				   (op_sll | op_sllv                    ) ? 4'd9:
				   (op_sra | op_srav                    ) ? 4'd10:
				   (op_srl | op_srlv                    ) ? 4'd11:
				   	                                        4'd0;

	assign Write_strb = (~ALU_Result[1]&~ALU_Result[0]&(op_swl|op_sb)                                                 ) ? 4'b0001:
	                    ((~ALU_Result[1] & ALU_Result[0] & op_swl) | (~ALU_Result[1] & op_sh)                         ) ? 4'b0011:
						(ALU_Result[1] & ~ALU_Result[0] & op_swl                                                      ) ? 4'b0111:
						((ALU_Result[1] & ALU_Result[0] & op_swl) | (~ALU_Result[1] & ~ALU_Result[0] & op_swr) | op_sw) ? 4'b1111:
						(ALU_Result[1] & ALU_Result[0] & (op_swl | op_sb)                                             ) ? 4'b1000:
						((ALU_Result[1] & ~ALU_Result[0] & op_swr ) | (ALU_Result[1] & op_sh)                         ) ? 4'b1100:
						(~ALU_Result[1] & ALU_Result[0] & op_swr                                                      ) ? 4'b1110:
						(~ALU_Result[1] & ALU_Result[0] & op_sb                                                       ) ? 4'b0010:
						(ALU_Result[1] & ~ALU_Result[0] & op_sb                                                       ) ? 4'b0100:
						                                                                                                  4'b0000;

endmodule
