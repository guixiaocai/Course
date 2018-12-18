module decode_stage(
    input         clk,
    input         resetn,

    input  [31:0] if_pc,
    input  [31:0] if_inst,
    output [31:0] de_pc,
    output [31:0] de_inst,
    output [31:0] de_alu_src1,
    output [31:0] de_alu_src2,

    input  [31:0] rf_rdata1,
    input  [31:0] rf_rdata2,
    output [31:0] de_rf_rdata1,
    output [31:0] de_rf_rdata2,
    output [ 4:0] rf_raddr1,
    output [ 4:0] rf_raddr2,
    output [ 4:0] de_rf_waddr,
    input  [ 4:0] ex_rf_waddr,
    input  [ 4:0] mem_rf_waddr,
    input  [ 4:0] wb_rf_waddr,
    input  [ 3:0] ex_op_RegWen,
    input  [ 3:0] mem_rf_wen,
    input  [ 3:0] wb_rf_wen,
    input  [31:0] mem_rf_wdata,
    input  [31:0] ex_rf_res,
    input  [ 5:0] ex_op_RegWrite,
    input  [31:0] wb_rf_wdata,
    input         ex_op_mf,
    // control signals
    output [ 3:0] op_alu,
    output [ 2:0] op_npc,
    output [ 2:0] op_RegDst, 
    output [ 1:0] op_mul,
    output [ 1:0] op_div,
    output [ 5:0] op_RegWrite,
    output [ 2:0] op_StByt,
    output [ 2:0] op_LdByt,
    output [ 1:0] op_HIWen,
    output [ 1:0] op_LOWen,
    output [ 3:0] op_RegWen,
    output        op_mf,

    input         if_to_de_valid,
    input         ex_allowin,
    input         mem_valid,
    output        de_valid,
    output        de_allowin,
    output        de_to_ex_valid
);

    // pipeline data
    reg        reg_de_valid;
    reg [31:0] reg_de_pc;
    reg [31:0] reg_de_inst;
    //reg []
 
    wire        de_ready_go;
    wire [31:0] de_imm;
    wire        lw_hazard;

    always @ (posedge clk) begin
        if(!resetn) begin
            reg_de_pc    <= 32'hbfc00000;
            reg_de_inst  <= 32'd0;
            reg_de_valid <= 1'b0;
        end
        else if(de_allowin) begin
            reg_de_valid <= if_to_de_valid;
        end
        if(if_to_de_valid & de_allowin & resetn) begin
            reg_de_pc    <= if_pc;
            reg_de_inst  <= if_inst;
        end
    end

    assign de_ready_go    = !(lw_hazard & mem_valid);
    assign de_allowin     = !de_valid || de_ready_go && ex_allowin;
    assign de_to_ex_valid = de_valid && de_ready_go;
    assign de_valid       = reg_de_valid;

    // control signals
    wire [5:0] op   = de_inst[31:26];
    wire [5:0] func = de_inst[ 5: 0];
    wire [4:0] rs   = de_inst[25:21];
    wire [4:0] rt   = de_inst[20:16];

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
    wire inst_mfc0   = op==6'b010000 && rs==5'd0;
    wire inst_mtc0   = op==6'b010000 && rs==5'b00100;
    wire inst_nop    = de_inst==32'd0;
    wire inst_eret   = de_inst==32'b01000010000000000000000000011000;
    wire inst_syscall= op == 6'd0 && de_inst[5:0] == 6'b001100;
    wire inst_break  = op == 6'd0 && de_inst[5:0] == 6'b001101; 

    assign op_alu[0] = inst_lui | inst_slt | inst_slti | inst_sltiu | inst_sltu | inst_or | inst_ori | inst_sllv | inst_srlv | inst_sll | inst_srl;       
    assign op_alu[1] = ~(inst_sltu | inst_sltiu | inst_and | inst_andi | inst_or | inst_ori | inst_xor | inst_xori | inst_nor | inst_sllv | inst_sll);    
    assign op_alu[2] = inst_sub | inst_subu | inst_slt | inst_slti | inst_sltiu | inst_sltu | inst_nor;                               
    assign op_alu[3] = inst_xor | inst_xori | inst_sra | inst_srav | inst_sllv | inst_srlv | inst_sll | inst_srl;  
    
    wire is_equal = (de_alu_src1 + ~de_alu_src2 + 32'd1 == 32'd0);
    wire is_r1_zero = de_alu_src1==32'd0;

    assign op_npc[0] = inst_jr | inst_jalr; // npc = rf_rdata1
    assign op_npc[1] = inst_j | inst_jal;          //npc = {pc[31:28], inst[25:0], 2'd0}
    assign op_npc[2] = (inst_bne & ~is_equal) | 
                       (inst_beq & is_equal) | 
                       ((inst_bgez | inst_bgezal) & ~de_alu_src1[31]) | 
                       ((inst_bltz | inst_bltzal) & de_alu_src1[31]) | 
                       (inst_blez & (de_alu_src1[31] | is_r1_zero)) | 
                       (inst_bgtz & ~de_alu_src1[31] & ~is_r1_zero); //npc = pc + offset

    wire inst_i_oprt = op[5:3]==3'd1;
    wire inst_r_oprt = op==6'd0 && (func[5:3]==3'd0 || func[5:3]==3'd4 || func[5:1]==5'd21);
    wire inst_ld = op[5:3]==3'd4 && op[2:0]!=3'd7;
    wire inst_st = op[5:3]==3'd5 && op[2:0]!=3'd7;

    //wire regdst_rt = inst_i_oprt | inst_ld | inst_mfc0;
    wire regdst_rd = inst_r_oprt | inst_jalr | inst_mfhi | inst_mflo;
    wire regdst_ra = inst_jal | inst_bgezal | inst_bltzal;
    assign op_RegDst = {regdst_rd, regdst_ra};

    wire alu_src2_sel = inst_ld | inst_st | inst_addiu | inst_lui | inst_jal | inst_addi | inst_slti | inst_sltiu | inst_ori | inst_xori | inst_andi;
    wire alu_src1_sel = inst_sll | inst_srl | inst_sra; // alu_src1 = sa;
    wire sign_ext     =  inst_ld | inst_st | inst_i_oprt & ~op[2];
    wire [2:0] op_ALUSrc  = {alu_src1_sel, alu_src2_sel, sign_ext};

    assign op_mul = {inst_mult, inst_mult | inst_multu};
    assign op_div = {inst_div, inst_div | inst_divu};

    wire RegWen = ~(inst_st | inst_beq | inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_bne | inst_mthi | op_mul | op_div | inst_j | inst_jr);
    assign op_RegWen =  {4{RegWen}};

    wire reg_w_alu = inst_r_oprt | inst_i_oprt;
    wire reg_w_mem = inst_ld;
    wire reg_w_pc  = inst_jal | inst_jalr | inst_bltzal | inst_bgezal;
    wire reg_w_hi  = inst_mfhi;
    wire reg_w_lo  = inst_mflo;
    wire reg_w_cp0 = inst_mfc0;
    assign op_RegWrite = { reg_w_alu, 
                           reg_w_mem, 
                           reg_w_pc, 
                           reg_w_hi, 
                           reg_w_lo, 
                           reg_w_cp0 };
    // swl 001
    // swr 010
    // sb  011
    // sh  100
    // sw  101
    assign op_StByt[0] = inst_swl | inst_sb | inst_sw;
    assign op_StByt[1] = inst_swr | inst_sb;
    assign op_StByt[2] = inst_sh  | inst_sw;

    // lwl 001
    // lwr 010
    // lb  011
    // lbu 100
    // lh  101
    // lhu 110
    assign op_LdByt[0] = inst_lwl | inst_lb | inst_lh;
    assign op_LdByt[1] = inst_lwr | inst_lb  | inst_lhu;
    assign op_LdByt[2] = inst_lbu | inst_lh  | inst_lhu;

    // mult 01
    // div  10
    // mthi 11
    assign op_HIWen[0] = op_mul | inst_mthi;
    assign op_HIWen[1] = op_div | inst_mthi;

    // mult 01
    // div  10
    // mtlo 11
    assign op_LOWen[0] = op_mul | inst_mtlo;
    assign op_LOWen[1] = op_div | inst_mtlo;

    wire op_mt = inst_mthi | inst_mtlo;
    assign op_mf = inst_mfhi | inst_mflo;

    assign de_pc       = reg_de_pc;
    assign de_inst     = reg_de_inst;
    assign rf_raddr1   = de_inst[25:21];
    assign rf_raddr2   = de_inst[20:16];
    assign de_rf_waddr = op_RegDst[0] ? 5'd31 :
                         op_RegDst[1] ? de_inst[15:11] :
                                        de_inst[20:16] ;
    assign de_imm      = op_ALUSrc[0] ? {{16{de_inst[15]}}, de_inst[15:0]} :
                                        {16'd0, de_inst[15:0]};
    
    // dealing hazard
    assign de_alu_src1 = op_ALUSrc[2] ? {27'd0, de_inst[10:6]} :
                         (de_inst[25:21]==ex_rf_waddr  && ex_rf_waddr  && ~ex_op_RegWrite[4] && ~ex_op_mf && ex_op_RegWen) ? ex_rf_res   :
                         (de_inst[25:21]==mem_rf_waddr && mem_rf_waddr && mem_rf_wen              ) ? mem_rf_wdata  :
                         (de_inst[25:21]==wb_rf_waddr  && wb_rf_waddr  && wb_rf_wen               ) ? wb_rf_wdata :
                                                                                                      rf_rdata1   ;
    //dealing hazard
    assign de_alu_src2 = op_ALUSrc[1] ? de_imm :
                         (de_inst[20:16]==ex_rf_waddr  && ex_rf_waddr  && ~ex_op_RegWrite[4] && ~ex_op_mf && ex_op_RegWen) ? ex_rf_res   :
                         (de_inst[20:16]==mem_rf_waddr && mem_rf_waddr && mem_rf_wen              ) ? mem_rf_wdata :
                         (de_inst[20:16]==wb_rf_waddr  && wb_rf_waddr  && wb_rf_wen               ) ? wb_rf_wdata :
                                                                                                      rf_rdata2   ;

    assign de_rf_rdata1 = (de_inst[25:21]==ex_rf_waddr  && ex_rf_waddr  && op_mt && ex_op_RegWen ) ? ex_rf_res   :
                          (de_inst[25:21]==mem_rf_waddr && mem_rf_waddr && op_mt && mem_rf_wen   ) ? mem_rf_wdata  :
                          (de_inst[25:21]==wb_rf_waddr  && wb_rf_waddr  && op_mt && wb_rf_wen    ) ? wb_rf_wdata :
                                                                                                     rf_rdata1  ;

    assign de_rf_rdata2 = (de_inst[20:16]==ex_rf_waddr  && ex_rf_waddr  && inst_st && ex_op_RegWen ) ? ex_rf_res   :
                          (de_inst[20:16]==mem_rf_waddr && mem_rf_waddr && inst_st && mem_rf_wen) ? mem_rf_wdata  :
                          (de_inst[20:16]==wb_rf_waddr  && wb_rf_waddr  && inst_st && wb_rf_wen    ) ? wb_rf_wdata :
                                                                                                       rf_rdata2  ;

    assign lw_hazard = (de_inst[25:21]==ex_rf_waddr  && ex_rf_waddr  && (ex_op_RegWrite[4] || ex_op_mf)) || 
                     (de_inst[20:16]==ex_rf_waddr  && ex_rf_waddr  && (ex_op_RegWrite[4] || ex_op_mf)) ||
                     (de_inst[25:21]==ex_rf_waddr  && ex_rf_waddr  && op_mt             ) ||
                     (de_inst[25:21]==mem_rf_waddr && mem_rf_waddr && op_mt             ) ||
                     (de_inst[25:21]==wb_rf_waddr  && wb_rf_waddr  && op_mt             ) ;
                     
endmodule