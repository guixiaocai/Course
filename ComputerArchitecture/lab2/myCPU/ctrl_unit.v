module ctrl_unit(
    input  [31:0] inst,
    input  [31:0] alu_src1_id,
    input  [31:0] alu_src2_id,
    output [34:0] ctrl
);    
    wire [5:0] op = inst[31:26];
    wire [5:0] func = inst[5:0];
    wire [4:0] rs = inst[25:21];
    wire [4:0] rt = inst[20:16];

    wire inst_addi   = op==6'b001000;
    wire inst_addiu  = op==6'b001001;
    wire inst_lw     = op==6'b100011;
    wire inst_lb     = op==6'b100000;
    wire inst_lbu    = op==6'b100100;
    wire inst_lh     = op==6'b100001;
    wire inst_lhu    = op==6'b100101;
    wire inst_lwl    = op==6'b100010;
    wire inst_lwr    = op==6'b100110;
    wire inst_sw     = op==6'b101011;
    wire inst_sb     = op==6'b101000;
    wire inst_sh     = op==6'b101001;
    wire inst_swl    = op==6'b101010;
    wire inst_swr    = op==6'b101110;
    wire inst_beq    = op==6'b000100;
    wire inst_bne    = op==6'b000101;
    wire inst_blez   = op==6'b000110;
    wire inst_bgtz   = op==6'b000111;
    wire inst_lui    = op==6'b001111;
    wire inst_jal    = op==6'b000011;
    wire inst_j      = op==6'b000010;
    wire inst_slti   = op==6'b001010;
    wire inst_sltiu  = op==6'b001011;
    wire inst_andi   = op==6'b001100;
    wire inst_ori    = op==6'b001101;
    wire inst_xori   = op==6'b001110;
    wire inst_mult   = op==6'd0 && func==6'b011000;
    wire inst_multu  = op==6'd0 && func==6'b011001;
    wire inst_mfhi   = op==6'd0 && func==6'b010000;
    wire inst_mflo   = op==6'd0 && func==6'b010010;
    wire inst_mthi   = op==6'd0 && func==6'b010001;
    wire inst_mtlo   = op==6'd0 && func==6'b010011;
    wire inst_addu   = op==6'b0 && func==6'b100001;
    wire inst_subu   = op==6'b0 && func==6'b100011;
    wire inst_slt    = op==6'b0 && func==6'b101010;
    wire inst_sltu   = op==6'b0 && func==6'b101011;
    wire inst_and    = op==6'b0 && func==6'b100100;
    wire inst_or     = op==6'b0 && func==6'b100101; 
    wire inst_xor    = op==6'b0 && func==6'b100110; 
    wire inst_nor    = op==6'b0 && func==6'b100111; 
    wire inst_sllv   = op==6'b0 && func==6'b000100;
    wire inst_srlv   = op==6'b0 && func==6'b000110;
    wire inst_srav   = op==6'b0 && func==6'b000111;
    wire inst_sll    = op==6'd0 && func==6'b000000;
    wire inst_srl    = op==6'd0 && func==6'b000010;
    wire inst_sra    = op==6'd0 && func==6'b000011;
    wire inst_jr     = op==6'd0 && func==6'b001000;
    wire inst_jalr   = op==6'd0 && func==6'b001001;
    wire inst_add    = op==6'd0 && func==6'b100000;
    wire inst_sub    = op==6'd0 && func==6'b100010;
    wire inst_div    = op==6'd0 && func==6'b011010;
    wire inst_divu   = op==6'd0 && func==6'b011011;
    wire inst_bltz   = op==6'd1 && rt==5'b00000;
    wire inst_bgez   = op==6'd1 && rt==5'b00001;
    wire inst_bltzal = op==6'd1 && rt==5'b10000;
    wire inst_bgezal = op==6'd1 && rt==5'b10001;

    wire is_equal   = (alu_src1_id + ~alu_src2_id + 32'd1 == 32'd0);
    wire is_r1_zero = alu_src1_id==32'd0;
    
    assign ctrl[ 0] = inst_lui | inst_slt | inst_slti | inst_sltiu | inst_sltu | inst_or | inst_ori | inst_sllv | inst_srlv | inst_sll | inst_srl;        //alu_op[0]
    assign ctrl[ 1] = ~(inst_sltu | inst_sltiu | inst_and | inst_andi | inst_or | inst_ori | inst_xor | inst_xori | inst_nor | inst_sllv | inst_sll);     //alu_op[1]
    assign ctrl[ 2] = inst_sub | inst_subu | inst_slt | inst_slti | inst_sltiu | inst_sltu | inst_nor;                                                    //alu_op[2]
    assign ctrl[ 3] = inst_xor | inst_xori | inst_sra | inst_srav | inst_sllv | inst_srlv | inst_sll | inst_srl;                                          //alu_op[3]
    assign ctrl[ 4] = inst_jr | inst_jalr;            //npc = reg_rdata1
    assign ctrl[ 5] = inst_j | inst_jal;          //npc = {pc[31:28], inst[25:0], 2'd0}
    assign ctrl[ 6] = inst_jal | inst_bltzal | inst_bgezal;             //reg_waddr = 5'd31
    assign ctrl[ 7] = inst_jal | inst_jalr | inst_bltzal | inst_bgezal;           //reg_wdata = pc + 8; regwrite
    assign ctrl[ 8] = (inst_bne & ~is_equal) | (inst_beq & is_equal) | ((inst_bgez | inst_bgezal) & ~alu_src1_id[31]) | ((inst_bltz | inst_bltzal) & alu_src1_id[31]) | (inst_blez & (alu_src1_id[31] | is_r1_zero)) | (inst_bgtz & ~alu_src1_id[31] & ~is_r1_zero); //npc = pc + offset
    assign ctrl[ 9] = ctrl[14] | ctrl[23] | inst_addiu | inst_lui | inst_jal | inst_addi | inst_slti | inst_sltiu | inst_ori | inst_xori | inst_andi;                                                                              //alu_src2 =  imm or reg_rdata2
    assign ctrl[10] = ctrl[14] | inst_addiu;                   //reg_wdata = data_rdata or alu_result
    assign ctrl[11] = op==6'd0 || inst_mfhi || inst_mflo || inst_jalr;     //reg_waddr = rd or rt
    assign ctrl[12] = ctrl[14] | ctrl[23] | inst_bne | inst_addiu | inst_addi | inst_beq | inst_j | inst_jal | inst_bgez | inst_blez | inst_bltz | inst_bgtz | (!op & ~inst_sltu) | inst_slti | inst_sltiu ;                       //imm = signed or unsigned 
    assign ctrl[13] = ~(ctrl[23] | inst_beq | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bne | inst_mthi | inst_mtlo | inst_mult | inst_div | inst_divu | inst_j | inst_jr);//regwrite
    assign ctrl[14] = inst_lw | inst_lwl | inst_lwr | inst_lb | inst_lbu | inst_lh | inst_lhu;
    assign ctrl[15] = inst_sll | inst_srl | inst_sra;   //alu_src1 = sa or reg_rdata1
    assign ctrl[16] = inst_mult;                       //mul_signed
    assign ctrl[17] = inst_div;                        //div_signed
    assign ctrl[18] = inst_mthi;                       //hi register write enable
    assign ctrl[19] = inst_mtlo;                       //lo register write enable
    assign ctrl[20] = inst_mfhi;
    assign ctrl[21] = inst_mflo;
    assign ctrl[22] = inst_divu;
    assign ctrl[23] = inst_sw | inst_sb | inst_sh | inst_swl | inst_swr;
    assign ctrl[24] = inst_multu;
    assign ctrl[25] = inst_swl;
    assign ctrl[26] = inst_swr;
    assign ctrl[27] = inst_sb;
    assign ctrl[28] = inst_sh;
    assign ctrl[29] = inst_lwl;
    assign ctrl[30] = inst_lwr;
    assign ctrl[31] = inst_lb;
    assign ctrl[32] = inst_lbu;
    assign ctrl[33] = inst_lh;
    assign ctrl[34] = inst_lhu;

    endmodule