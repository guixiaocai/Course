`timescale 1ns / 1ps
module decoder(
	input  [31:0] Instruction,
// output for next pc
	output  [ 3:0] PCDst,
//output for alu,mutiplier,divider
	output [11:0] ALUop,
	output [ 2:0] ALUSrc,
	output [ 1:0] ALUsa,
	output [ 1:0] mult_signal,
	output [ 1:0] div_signal,
//output for load and store
	output Memread,
	output Memwrite,
//output for registers
	output [ 1:0] RegWrite,
	output [ 2:0] RegDst,
	output [ 5:0] RegData,
	output [ 2:0] hi_en,
	output [ 2:0] lo_en,

//output for cp0 regs
	output rsv_cmt,

// output for forward 
	output [ 1:0] id_src_csdr,
	output [ 1:0] ex_src_csdr,
	output [ 1:0] mem_dst_csdr

);

	wire [5:0] opcode;
	wire [4:0] rs;
	wire [4:0] rt;
	wire [4:0] rd;
	wire [4:0] sa;
	wire [5:0] funcode;
	wire [2:0] sel; // for cp0

	assign opcode  = Instruction[31:26];
	assign rs      = Instruction[25:21];
	assign rt      = Instruction[20:16];
	assign rd      = Instruction[15:11];
	assign sa      = Instruction[10:6];
	assign funcode = Instruction[5:0];
	assign sel     = Instruction[2:0];

	wire inst_lui;
	wire inst_add,inst_addi;
	wire inst_addiu,inst_addu;
	wire inst_sub; 
	wire inst_subu;
	wire inst_and,inst_andi;
	wire inst_or,inst_ori;
	wire inst_xor,inst_xori;
	wire inst_nor;
	wire inst_slt,inst_slti;
	wire inst_sltu,inst_sltiu;
	wire inst_sll,inst_sllv;
	wire inst_srl,inst_srlv;
	wire inst_sra,inst_srav;
	wire inst_div,inst_divu;
	wire inst_mult,inst_multu;
	wire inst_mfhi,inst_mflo;
	wire inst_mthi,inst_mtlo;
	wire inst_lb,inst_lbu;
	wire inst_lh,inst_lhu;
	wire inst_lwl,inst_lw,inst_lwr;
	wire inst_sb;
	wire inst_sh;
	wire inst_swl,inst_sw,inst_swr;
	wire inst_beq,inst_bne;
	wire inst_bgez,inst_bltz;
	wire inst_bgezal,inst_bltzal;
	wire inst_bgtz,inst_blez;
	wire inst_j,inst_jal;
	wire inst_jr,inst_jalr;

	//exception instructions
	wire inst_mfc0,inst_mtc0;
	wire inst_eret;
	wire inst_syscall;
	wire inst_break;

	assign inst_lui   = (opcode == 6'd15) && (rs == 5'd0);
	assign inst_add   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd32);
	assign inst_addi  = (opcode == 6'd8);
	assign inst_addiu = (opcode == 6'd9);
	assign inst_addu  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd33);
	assign inst_sub   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd34);
	assign inst_subu  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd35);
	assign inst_and   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd36);
	assign inst_andi  = (opcode == 6'd12);
	assign inst_or    = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd37);
	assign inst_ori   = (opcode == 6'd13);
	assign inst_xor   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd38);
	assign inst_xori  = (opcode == 6'd14);
	assign inst_nor   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd39);
	assign inst_slt   = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd42);
	assign inst_sltu  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd43);
	assign inst_slti  = (opcode == 6'd10);
	assign inst_sltiu = (opcode == 6'd11);
	assign inst_sll   = (opcode == 6'd0) && (rs == 5'd0) && (funcode == 6'd0);
	assign inst_srl   = (opcode == 6'd0) && (rs == 5'd0) && (funcode == 6'd2);
	assign inst_sra   = (opcode == 6'd0) && (rs == 5'd0) && (funcode == 6'd3);
	assign inst_sllv  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd4);
	assign inst_srav  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd7);
	assign inst_srlv  = (opcode == 6'd0) && (sa == 5'd0) && (funcode == 6'd6);

	assign inst_div   = (opcode == 6'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd26);
	assign inst_divu  = (opcode == 6'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd27);
	assign inst_mult  = (opcode == 6'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd24);
	assign inst_multu = (opcode == 6'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd25);
	assign inst_mfhi  = (opcode == 6'd0) && (rs == 5'd0) && (rt == 5'd0) && (sa == 5'd0) && (funcode == 6'd16);
	assign inst_mflo  = (opcode == 6'd0) && (rs == 5'd0) && (rt == 5'd0) && (sa == 5'd0) && (funcode == 6'd18);
	assign inst_mthi  = (opcode == 6'd0) && (rt == 5'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd17);
	assign inst_mtlo  = (opcode == 6'd0) && (rt == 5'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd19);

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

	assign inst_beq    = (opcode == 6'd4);
	assign inst_bne    = (opcode == 6'd5);
	assign inst_bgtz   = (opcode == 6'd7) && (rt == 5'd0);
	assign inst_blez   = (opcode == 6'd6) && (rt == 5'd0);
	assign inst_bgez   = (opcode == 6'd1) && (rt == 5'd1);
	assign inst_bltz   = (opcode == 6'd1) && (rt == 5'd0);
	assign inst_bgezal = (opcode == 6'd1) && (rt == 5'd17);
	assign inst_bltzal = (opcode == 6'd1) && (rt == 5'd16);
	assign inst_j      = (opcode == 6'd2);
	assign inst_jal    = (opcode == 6'd3);
	assign inst_jr     = (opcode == 6'd0) && (rt == 5'd0) && (rd == 5'd0) && (funcode == 6'd8);
	assign inst_jalr   = (opcode == 6'd0) && (rt == 5'd0) && (funcode == 6'd9);

	assign inst_mfc0    = (opcode == 6'd16) && (rs == 5'd0) && (sa == 5'd0) && (funcode[4:3] == 2'd0);
	assign inst_mtc0    = (opcode == 6'd16) && (rs == 5'd4) && (sa == 5'd0) && (funcode[4:3] == 2'd0);
	assign inst_eret    = (opcode == 6'd16) && (rs == 5'd16) && (rt == 5'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd24);
	assign inst_syscall = (opcode == 6'd0) && (funcode == 6'd12);
	assign inst_break   = (opcode == 6'd0) && (funcode == 6'd13);

	wire inst_i_oprt;
	wire inst_r_oprt;
	wire inst_ld;
	wire inst_st;
	wire inst_mul_div;
	wire inst_jump_branch;
	wire inst_other_reg;
	wire inst_excep;

	assign inst_i_oprt = inst_addi|inst_addiu|inst_slti|inst_sltiu|inst_andi|inst_ori|inst_xori|inst_lui;
	assign inst_r_oprt = inst_sll|inst_srl|inst_sra|inst_sllv|inst_srlv|inst_srav
						|inst_add|inst_addu|inst_sub|inst_subu|inst_and|inst_or|inst_xor|inst_nor
						|inst_slt|inst_sltu;
	assign inst_ld    = inst_lb|inst_lbu|inst_lh|inst_lhu|inst_lwl|inst_lw|inst_lwr;
	assign inst_st    = inst_sb|inst_sh|inst_swl|inst_sw|inst_swr;
	assign inst_mul_div = inst_mult|inst_multu|inst_div|inst_divu;
	assign inst_other_reg = inst_mfhi|inst_mthi|inst_mflo|inst_mtlo|inst_mfc0|inst_mtc0;
	assign inst_jump_branch = jump_inst|jump_reg|normal_branch|regimm_branch;
	assign inst_excep = inst_eret|inst_syscall|inst_break;

	wire valid_inst;
	assign valid_inst = inst_i_oprt|inst_r_oprt|inst_ld|inst_st|inst_mul_div
						|inst_other_reg|inst_jump_branch|inst_excep;
	assign rsv_cmt    = !valid_inst;

	/*PCDst part */
	wire jump_inst;
	wire jump_reg;
	wire normal_branch;
	wire regimm_branch;

	assign jump_inst     = inst_j|inst_jal ;
	assign jump_reg      = inst_jr|inst_jalr;
	assign normal_branch = inst_beq | inst_bne | inst_bgtz | inst_blez;
	assign regimm_branch = inst_bgez|inst_bltz|inst_bgezal|inst_bltzal;
	assign PCDst         = {regimm_branch,normal_branch,jump_reg,jump_inst};

	/*ALUop part*/
	wire op_add,op_sub; 
	wire op_slt,op_sltu; 
	wire op_and,op_or,op_xor,op_nor; 
	wire op_sll,op_srl,op_sra; 
	wire op_lui; 

	assign op_add  = inst_addiu | inst_addu | inst_add | inst_addi | inst_ld | inst_st;
	assign op_sub  = inst_subu | inst_sub;
	assign op_slt  = inst_slt | inst_slti;
	assign op_sltu = inst_sltu | inst_sltiu;
	assign op_and  = inst_and | inst_andi;
	assign op_or   = inst_or | inst_ori;
	assign op_xor  = inst_xor | inst_xori;
	assign op_nor  = inst_nor;
	assign op_sll  = inst_sll | inst_sllv;
	assign op_srl  = inst_srl | inst_srlv;
	assign op_sra  = inst_sra | inst_srav;
	assign op_lui  = inst_lui;

	assign ALUop = {op_add,op_sub,op_slt,op_sltu,op_and,op_or,op_xor,op_nor,op_sll,op_srl,op_sra,op_lui};

	/*ALUSrc part*/
	wire alusrc_rdata;
	wire alusrc_sign;
	wire alusrc_unsign;

	assign alusrc_rdata  = inst_r_oprt;
	assign alusrc_sign   = inst_ld | inst_st | (inst_i_oprt & (!opcode[2]));
	assign alusrc_unsign = inst_i_oprt & opcode[2];

	assign ALUSrc = {alusrc_rdata,alusrc_sign,alusrc_unsign};

	/*ALUsa part*/
	wire sa_inst;
	wire sa_rs;

	assign sa_inst = inst_sll | inst_srl | inst_sra;
	assign sa_rs   = inst_sllv | inst_srlv | inst_srav;

	assign ALUsa = {sa_inst,sa_rs};

	/*mul_div_signal part*/
	wire mult;
	wire mult_signed;
	wire div;
	wire div_signed;

	assign mult        = inst_mult | inst_multu;
	assign mult_signed = inst_mult;
	assign div         = inst_div | inst_divu;
	assign div_signed  = inst_div;

	assign mult_signal = {mult,mult_signed};
	assign div_signal  = {div,div_signed};

	/*Memread part*/
	assign Memread    = inst_ld | inst_st;
	assign Memwrite   = inst_st;

	/*RegWrite part */
	wire of_csdr;// need to consider Overflow
	wire no_need;// no need to store into registers, such as jump and branch instructions

	assign of_csdr = inst_add | inst_addi | inst_sub;
	assign no_need= inst_j|inst_jr|normal_branch|inst_bgez|inst_bltz
					|inst_st|inst_mul_div
					|inst_mthi|inst_mtlo
					|inst_mtc0|inst_eret|inst_syscall|inst_break;

	assign RegWrite = {of_csdr,no_need};

	/*RegDst part*/
	wire regdst_rt;
	wire regdst_rd;
	wire regdst_ra;

	assign regdst_rt = inst_i_oprt|inst_ld|inst_mfc0;
	assign regdst_rd = inst_r_oprt|inst_jalr|inst_mfhi|inst_mflo;
	assign regdst_ra = inst_jal|inst_bgezal|inst_bltzal;

	assign RegDst = {regdst_rt,regdst_rd,regdst_ra};

	/*RegData part*/
	wire regdata_result;
	wire regdata_mem;
	wire regdata_pc;
	wire regdata_hi;
	wire regdata_lo;
	wire regdata_cp0;

	assign regdata_result = inst_r_oprt | inst_i_oprt;
	assign regdata_mem = inst_ld;
	assign regdata_pc = inst_jal|inst_jalr|inst_bgezal|inst_bltzal;
	assign regdata_hi = inst_mfhi;
	assign regdata_lo = inst_mflo;
	assign regdata_cp0 = inst_mfc0;

	assign RegData = {regdata_result,regdata_mem,regdata_pc,regdata_hi,regdata_lo,regdata_cp0};

	/*hi_lo_en part*/
	assign hi_en = {mult,div,inst_mthi};
	assign lo_en = {mult,div,inst_mtlo};

	/* CP0 signal */
	/*output signal for forward*/
	wire id_rs_src,id_rt_src;
	wire ex_rs_src,ex_rt_src;

	assign id_rs_src = jump_reg | normal_branch | regimm_branch | inst_mthi | inst_mtlo;
	assign id_rt_src = normal_branch | regimm_branch | inst_st | inst_lwl | inst_lwr | inst_mtc0;
	assign ex_rs_src = 1'd1;
	assign ex_rt_src = inst_r_oprt | inst_mul_div;

	assign id_src_csdr  = {id_rs_src,id_rt_src};
	assign ex_src_csdr  = {ex_rs_src,ex_rt_src};
	assign mem_dst_csdr = {inst_ld,inst_mfhi | inst_mflo} ;

endmodule