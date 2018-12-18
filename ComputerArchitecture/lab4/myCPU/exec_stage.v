module exec_stage(
    input         clk,
    input         resetn,

    input  [31:0] de_pc,
    input  [31:0] de_inst,
    output [31:0] ex_pc,
    output [31:0] ex_inst, 
    input  [ 3:0] op_alu,
    input  [31:0] de_alu_src1,
    input  [31:0] de_alu_src2,
    input  [31:0] de_rf_rdata1,
    input  [31:0] de_rf_rdata2,
    output [31:0] ex_rf_rdata1,
    output [31:0] ex_rf_rdata2,
    input  [ 4:0] de_rf_waddr, 
    output [ 4:0] ex_rf_waddr,
    output [31:0] ex_rf_res,
    output [31:0] ex_hi_res,
    output [31:0] ex_lo_res,
    output [31:0] ex_hi_out,
    output [31:0] ex_lo_out,
    output [31:0] div_res_q,
    output [31:0] div_res_r,
    output [63:0] ex_mul_res,

    input  [ 2:0] op_RegDst, 
    input  [ 1:0] op_mul,
    input  [ 1:0] op_div,
    input  [ 5:0] op_RegWrite,
    input  [ 2:0] op_StByt,
    input  [ 2:0] op_LdByt,
    input  [ 1:0] op_HIWen,
    input  [ 1:0] op_LOWen,
    input  [ 3:0] op_RegWen,
    input         op_mf,
    output [ 1:0] ex_op_mul,
    output [ 1:0] ex_op_div,
    output [ 2:0] ex_op_RegDst,
    output [ 5:0] ex_op_RegWrite,
    output [ 2:0] ex_op_StByt,
    output [ 2:0] ex_op_LdByt,
    output        ex_op_mf,
    output [ 1:0] ex_op_HIWen,
    output [ 1:0] ex_op_LOWen,
    output [ 3:0] ex_op_RegWen,
    input  [31:0] mem_div_res_q,
	input  [31:0] mem_div_res_r,
	input  [63:0] mem_mul_res,
    input  [31:0] wb_div_res_q,
	input  [31:0] wb_div_res_r,
	input  [63:0] wb_mul_res,
    input  [31:0] mem_hi_res,
    input  [31:0] mem_lo_res,
    input  [ 1:0] mem_op_mul,
    input  [ 1:0] mem_op_div,
    input  [ 1:0] mem_inst_mt,
    input  [ 1:0] wb_op_mul,
    input  [ 1:0] wb_op_div,
    input  [31:0] wb_hi_res,
    input  [31:0] wb_lo_res,
    input  [31:0] hi_in,
    input  [31:0] hi_out,
    input  [31:0] lo_in,
    input  [31:0] lo_out,

    input         de_to_ex_valid,
    input         mem_allowin,
    input         wb_valid,
    output        ex_valid,
    output        ex_allowin,
    output        ex_to_mem_valid
);

    reg        reg_ex_valid;
    reg [31:0] reg_ex_pc;
    reg [31:0] reg_ex_inst;
    reg [ 4:0] reg_ex_op_alu;
    reg [31:0] reg_alu_src1;
    reg [31:0] reg_alu_src2;
    reg [ 4:0] reg_ex_rf_waddr;
    reg [31:0] reg_ex_rf_rdata1;
    reg [31:0] reg_ex_rf_rdata2;
    reg [ 2:0] reg_ex_op_RegDst;
    reg [ 5:0] reg_ex_op_RegWrite;
    reg [ 2:0] reg_ex_op_StByt;
    reg [ 2:0] reg_ex_op_LdByt;
    reg [ 1:0] reg_ex_op_HIWen;
    reg [ 1:0] reg_ex_op_LOWen;
    reg [ 3:0] reg_ex_op_RegWen;
    reg [ 1:0] reg_ex_op_mul;
    reg [ 1:0] reg_ex_op_div;
    reg        reg_ex_op_mf;

    wire        ex_ready_go;
    wire [ 3:0] ex_op_alu;
    wire [31:0] alu_src1;
    wire [31:0] alu_src2;
    wire        div_complete;
    wire        do_div;
    wire [31:0] ex_alu_result;
    wire [31:0] div_res_q;
    wire [31:0] div_res_r;
    wire [63:0] ex_mul_res;

    always @ (posedge clk) begin
        if(!resetn) begin
            reg_ex_valid    <= 1'b0;
            reg_ex_pc       <= 32'hbfc00000;
            reg_ex_inst     <= 32'd0;
            reg_alu_src1    <= 32'd0;
            reg_alu_src2    <= 32'd0;
            reg_ex_rf_waddr <= 5'd0;
            reg_ex_rf_rdata1 <= 32'd0;
            reg_ex_rf_rdata2 <= 32'd0;
            reg_ex_op_mul      <= 2'd0;
            reg_ex_op_div   <= 2'd0;
            reg_ex_op_RegDst <= 3'd0;
            reg_ex_op_RegWrite <= 6'd0;
            reg_ex_op_StByt    <= 3'd0;
            reg_ex_op_LdByt    <= 3'd0;
            reg_ex_op_HIWen    <= 2'd0;
            reg_ex_op_LOWen    <= 2'd0;
            reg_ex_op_RegWen   <= 4'd0;            
        end
        else if(ex_allowin) begin
            reg_ex_valid  <= de_to_ex_valid;
        end
        if(de_to_ex_valid & ex_allowin) begin
            reg_ex_pc          <= de_pc;
            reg_ex_inst        <= de_inst;
            reg_ex_op_alu      <= op_alu;
            reg_alu_src1       <= de_alu_src1;
            reg_alu_src2       <= de_alu_src2;
            reg_ex_rf_waddr    <= de_rf_waddr;
            reg_ex_rf_rdata1   <= de_rf_rdata1;
            reg_ex_rf_rdata2   <= de_rf_rdata2;
            reg_ex_op_RegDst   <= op_RegDst;
            reg_ex_op_RegWrite <= op_RegWrite;
            reg_ex_op_StByt    <= op_StByt;
            reg_ex_op_LdByt    <= op_LdByt;
            reg_ex_op_HIWen    <= op_HIWen;
            reg_ex_op_LOWen    <= op_LOWen;
            reg_ex_op_RegWen   <= op_RegWen;
            reg_ex_op_mul      <= op_mul;
            reg_ex_op_div      <= op_div;
            reg_ex_op_mf       <= op_mf;
        end
    end

    assign ex_ready_go     = !do_div;
    assign ex_allowin      = !ex_valid || ex_ready_go && mem_allowin;
    assign ex_to_mem_valid = ex_valid && ex_ready_go;
    assign do_div          = ex_op_div[0] & ~div_complete;

    assign ex_valid       = reg_ex_valid;
    assign ex_pc          = reg_ex_pc;
    assign ex_inst        = reg_ex_inst;
    assign ex_op_alu      = reg_ex_op_alu;
    assign alu_src1       = reg_alu_src1;
    assign alu_src2       = reg_alu_src2;
    assign ex_rf_rdata1   = reg_ex_rf_rdata1;
    assign ex_rf_rdata2   = reg_ex_rf_rdata2;
    assign ex_rf_waddr    = reg_ex_rf_waddr; 
    assign ex_op_RegDst   = reg_ex_op_RegDst;
    assign ex_op_RegWrite = reg_ex_op_RegWrite;
    assign ex_op_RegWen   = reg_ex_op_RegWen;
    assign ex_op_StByt    = reg_ex_op_StByt;
    assign ex_op_LdByt    = reg_ex_op_LdByt;
    assign ex_op_HIWen    = reg_ex_op_HIWen;
    assign ex_op_LOWen    = reg_ex_op_LOWen;
    assign ex_op_mf       = reg_ex_op_mf;
    assign ex_op_mul      = reg_ex_op_mul;
    assign ex_op_div      = reg_ex_op_div;
    assign ex_rf_res      = ex_alu_result;
    //assign ex_hi_res      = 
    
    //assign ex_lo_res      = 

    // dealing with hilo hazard
    assign ex_hi_out = ex_op_RegWrite[2] & (mem_op_mul[0]  ) ? mem_mul_res[63:32] :
                       ex_op_RegWrite[2] & mem_op_div[0]    ? mem_div_res_r:
                       ex_op_RegWrite[2] & ( wb_op_mul[0] )  ? wb_mul_res[63:32]  :
                       ex_op_RegWrite[2] & wb_op_div[0] ? wb_div_res_r :
                       ex_op_RegWrite[2] & mem_inst_mt[1]                  ? hi_in      :
                                                                             hi_out     ;

     assign ex_lo_out = ex_op_RegWrite[1] & (mem_op_mul[0] ) ? mem_mul_res[31:0] :
                        ex_op_RegWrite[1] & mem_op_div[0] ? mem_div_res_q:
                        ex_op_RegWrite[1] & ( wb_op_mul[0]  )  ? wb_mul_res[31:0]  :
                        ex_op_RegWrite[1] & wb_op_div[0] ? wb_div_res_q:
                        ex_op_RegWrite[1] & mem_inst_mt[0]                  ? lo_in      :
                                                                              lo_out     ;

    alu u_alu(
        .alu_src1      ( alu_src1     ),
        .alu_src2      ( alu_src2     ),
        .alu_op        ( ex_op_alu    ),
        .alu_result_ex ( ex_alu_result)
    );

    mul u_mul(
        .mul_clk    (clk           ),
        .resetn     (resetn        ),
        .mul_signed (op_mul[1]     ),
        .x          (de_alu_src1   ),
        .y          (de_alu_src2   ),
        .de_to_ex_valid   (de_to_ex_valid),
        .ex_allowin (ex_allowin    ),
        .result     (ex_mul_res    )
    );

    div u_div(
        .div_clk       (clk         ),
		.resetn        (resetn      ),
		.div_signed    (ex_op_div[1]),
		.div           (do_div      ),
		.x             (alu_src1    ),
		.y             (alu_src2    ),
		.s             (div_res_q   ),
		.r             (div_res_r   ),
		.complete      (div_complete)
    );
endmodule