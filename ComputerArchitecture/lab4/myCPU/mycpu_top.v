module mycpu_top(
    input  wire        clk,
    input  wire        resetn,
    output wire        inst_sram_en,
    output wire        data_sram_en,
    input  wire [31:0] inst_sram_rdata,
    input  wire [31:0] data_sram_rdata,
    output wire [ 3:0] inst_sram_wen,
    output wire [31:0] inst_sram_addr,
    output wire [31:0] inst_sram_wdata,
    output wire [ 3:0] data_sram_wen,
    output wire [31:0] data_sram_addr,
    output wire [31:0] data_sram_wdata,
    output wire [31:0] debug_wb_pc,
    output wire [ 3:0] debug_wb_rf_wen,
    output wire [ 4:0] debug_wb_rf_wnum,
    output wire [31:0] debug_wb_rf_wdata
);
    wire        if_valid, de_valid, ex_valid, mem_valid, wb_valid;
    wire        if_allowin, de_allowin, ex_allowin, mem_allowin, wb_allowin;
    wire        if_to_de_valid, de_to_ex_valid, ex_to_mem_valid, mem_to_wb_valid;
    wire [31:0] if_pc, de_pc, ex_pc, mem_pc, wb_pc;
    wire [31:0] if_inst, de_inst, ex_inst, mem_inst, wb_inst;
    wire [31:0] de_alu_src1, de_alu_src2;
    wire [31:0] rf_rdata1, de_rf_rdata1, ex_rf_rdata1;
    wire [31:0] rf_rdata2, de_rf_rdata2, ex_rf_rdata2;
    wire [31:0] ex_rf_res, mem_rf_wdata, wb_rf_wdata;
    wire [31:0] ex_hi_res, hi_out, hi_in, mem_hi_res, wb_hi_res, ex_hi_out, mem_hi_out;
    wire [31:0] ex_lo_res, lo_out, lo_in, mem_lo_res, wb_lo_res, ex_lo_out, mem_lo_out;
    wire [31:0] div_res_q, mem_div_res_q, div_res_r, mem_div_res_r, wb_div_res_q, wb_div_res_r;
    wire [63:0] ex_mul_res, mem_mul_res, wb_mul_res;
    wire [ 4:0] rf_raddr1, rf_raddr2;
    wire [ 4:0] de_rf_waddr, ex_rf_waddr, mem_rf_waddr, wb_rf_waddr;
    wire [ 3:0] op_alu, op_RegWen, ex_op_RegWen, mem_rf_wen, wb_rf_wen;
    //wire [ 3:0] 
    wire [ 2:0] op_npc, op_RegDst, ex_op_RegDst;
    wire [ 2:0] op_StByt, ex_op_StByt, op_LdByt, ex_op_LdByt;
    wire [ 1:0] op_mul, ex_op_mul, mem_op_mul, wb_op_mul;
    wire [ 1:0] op_div, ex_op_div, mem_op_div, wb_op_div;
    wire [ 1:0] mem_inst_mt, op_HIWen, op_LOWen, ex_op_HIWen, ex_op_LOWen, mem_op_HIWen, mem_op_LOWen;
    wire [ 5:0] op_RegWrite, ex_op_RegWrite;
    wire        op_mf, ex_op_mf;
    //wire        hi_wen, lo_wen;
    wire        excep_cmt, int_cmt, eret_cmt;
    wire [31:0] cp0_read;

    assign excep_cmt = 1'b0;
    assign int_cmt   = 1'b0;
    assign eret_cmt  = 1'b0;

    fetch_stage fetch(
        .clk                ( clk             ),
        .resetn             ( resetn          ),
        .if_pc              ( if_pc           ),
        .if_inst            ( if_inst         ),
        .de_pc              ( de_pc           ),
        .de_inst            ( de_inst         ),
        .de_alu_src1        ( de_alu_src1     ),
        .op_npc             ( op_npc          ),
        .if_valid           ( if_valid        ),
        .if_allowin         ( if_allowin      ),
        .if_to_de_valid     ( if_to_de_valid  ),
        .de_allowin         ( de_allowin      ),
        .inst_sram_en       ( inst_sram_en    ),
        .inst_sram_wen      ( inst_sram_wen   ),
        .inst_sram_addr     ( inst_sram_addr  ),
        .inst_sram_wdata    ( inst_sram_wdata ),
        .inst_sram_rdata    ( inst_sram_rdata )
    );

    decode_stage decode(
        .clk                ( clk            ),
        .resetn             ( resetn         ),
        .if_pc              ( if_pc          ),
        .if_inst            ( if_inst        ),
        .de_pc              ( de_pc          ),
        .de_inst            ( de_inst        ),
        .de_alu_src1        ( de_alu_src1    ),
        .de_alu_src2        ( de_alu_src2    ),
        .rf_rdata1          ( rf_rdata1      ),
        .rf_rdata2          ( rf_rdata2      ),
        .de_rf_rdata1       ( de_rf_rdata1   ),
        .de_rf_rdata2       ( de_rf_rdata2   ),
        .rf_raddr1          ( rf_raddr1      ),
        .rf_raddr2          ( rf_raddr2      ),
        .de_rf_waddr        ( de_rf_waddr    ),
        .ex_rf_waddr        ( ex_rf_waddr    ),
        .mem_rf_waddr       ( mem_rf_waddr   ),
        .wb_rf_waddr        ( wb_rf_waddr    ),
        .ex_op_RegWen       ( ex_op_RegWen   ),
        .ex_op_RegWrite     ( ex_op_RegWrite ),
        .ex_op_mf           ( ex_op_mf       ),
        .mem_rf_wen         ( mem_rf_wen     ),
        .wb_rf_wen          ( wb_rf_wen      ),
        .mem_rf_wdata       ( mem_rf_wdata   ),
        .ex_rf_res          ( ex_rf_res      ),
        .wb_rf_wdata        ( wb_rf_wdata    ),
        .op_alu             ( op_alu         ),
        .op_npc             ( op_npc         ),
        .op_RegDst          ( op_RegDst      ),
        .op_mul             ( op_mul         ),
        .op_div             ( op_div         ),
        .op_mf(op_mf),
        .op_RegWrite        ( op_RegWrite    ),
        .op_StByt           ( op_StByt       ),
        .op_LdByt           ( op_LdByt       ),
        .op_HIWen           ( op_HIWen       ),
        .op_LOWen           ( op_LOWen       ),
        .op_RegWen          ( op_RegWen      ),
        .if_to_de_valid     ( if_to_de_valid ),
        .ex_allowin         ( ex_allowin     ),
        .mem_valid          ( mem_valid      ),
        .de_valid           ( de_valid       ),
        .de_allowin         ( de_allowin     ),
        .de_to_ex_valid     ( de_to_ex_valid )
    );


    exec_stage exec(
        .clk                ( clk             ),
        .resetn             ( resetn          ),
        .de_pc              ( de_pc           ),
        .de_inst            ( de_inst         ),
        .ex_pc              ( ex_pc           ),
        .ex_inst            ( ex_inst         ),
        .op_alu             ( op_alu          ),
        .op_mf(op_mf),
        .de_alu_src1        ( de_alu_src1     ),
        .de_alu_src2        ( de_alu_src2     ),
        .de_rf_rdata1       ( de_rf_rdata1    ),
        .de_rf_rdata2       ( de_rf_rdata2    ),
        .ex_rf_rdata1       ( ex_rf_rdata1    ),
        .ex_rf_rdata2       ( ex_rf_rdata2    ),
        .div_res_q          ( div_res_q       ),
        .div_res_r          ( div_res_r       ),
        .ex_mul_res         ( ex_mul_res      ),
        .wb_div_res_q       ( wb_div_res_q    ),
        .wb_div_res_r       ( wb_div_res_r    ),
        .wb_mul_res         ( wb_mul_res      ),
        .de_rf_waddr        ( de_rf_waddr     ),
        .ex_rf_waddr        ( ex_rf_waddr     ),
        .mem_div_res_q      ( mem_div_res_q   ),
        .mem_div_res_r      ( mem_div_res_r   ),
        .mem_mul_res        ( mem_mul_res     ),
        .ex_rf_res          ( ex_rf_res       ),
        .ex_hi_res          ( ex_hi_res       ),
        .ex_lo_res          ( ex_lo_res       ),
        .ex_hi_out          ( ex_hi_out       ),
        .ex_lo_out          ( ex_lo_out       ),
        .op_RegDst          ( op_RegDst       ),
        .op_mul             ( op_mul          ),
        .op_div             ( op_div          ),
        .op_RegWrite        ( op_RegWrite     ),
        .op_StByt           ( op_StByt        ),
        .op_LdByt           ( op_LdByt        ),
        .op_HIWen           ( op_HIWen        ),
        .op_LOWen           ( op_LOWen        ),
        .ex_op_HIWen        ( ex_op_HIWen     ),
        .ex_op_LOWen        ( ex_op_LOWen     ),
        .op_RegWen          ( op_RegWen       ),
        .ex_op_mul          ( ex_op_mul       ),
        .ex_op_div          ( ex_op_div       ),
        .ex_op_mf           ( ex_op_mf        ),
        .ex_op_RegDst       ( ex_op_RegDst    ),
        .ex_op_RegWrite     ( ex_op_RegWrite  ),
        .ex_op_StByt        ( ex_op_StByt     ),
        .ex_op_LdByt        ( ex_op_LdByt     ),
        .mem_inst_mt        ( mem_inst_mt     ),
        .mem_hi_res         ( mem_hi_res      ),
        .mem_lo_res         ( mem_lo_res      ),
        .mem_op_mul         ( mem_op_mul      ),
        .mem_op_div         ( mem_op_div      ),
        .wb_op_mul          ( wb_op_mul       ),
        .wb_op_div          ( wb_op_div       ),
        .wb_hi_res          ( wb_hi_res       ),
        .wb_lo_res          ( wb_lo_res       ),
        .hi_in              ( hi_in           ),
        .hi_out             ( hi_out          ),
        .lo_in              ( lo_in           ),
        .lo_out             ( lo_out          ),
        .ex_op_RegWen       ( ex_op_RegWen    ),
        .de_to_ex_valid     ( de_to_ex_valid  ),
        .wb_valid          ( wb_valid       ),
        .mem_allowin        ( mem_allowin     ),
        .ex_valid           ( ex_valid        ),
        .ex_allowin         ( ex_allowin      ),
        .ex_to_mem_valid    ( ex_to_mem_valid )
    );

    memory_stage mem(
        .clk                ( clk             ),
        .resetn             ( resetn          ),
        .ex_pc              ( ex_pc           ),
        .ex_inst            ( ex_inst         ),
        .ex_rf_rdata1       ( ex_rf_rdata1    ),
        .ex_rf_rdata2       ( ex_rf_rdata2    ),
        .div_res_q          ( div_res_q       ),
        .div_res_r          (div_res_r        ),
        .ex_mul_res         (ex_mul_res       ),
        .mem_div_res_q      (mem_div_res_q    ),
        .mem_div_res_r      (mem_div_res_r    ),
        .mem_mul_res        (mem_mul_res      ),
        .ex_rf_res          ( ex_rf_res       ),
        .ex_hi_res          ( ex_hi_res       ),
        .ex_lo_res          ( ex_lo_res       ),
        .ex_op_StByt        ( ex_op_StByt     ),
        .ex_op_LdByt        ( ex_op_LdByt     ),
        .ex_op_mul          ( ex_op_mul       ),
        .ex_op_div          ( ex_op_div       ),
        .ex_op_HIWen        ( ex_op_HIWen     ),
        .ex_op_LOWen        ( ex_op_LOWen     ),
        .wb_allowin         ( wb_allowin      ),
        .excep_cmt          ( excep_cmt       ),
        .int_cmt            ( int_cmt         ),
        .eret_cmt           ( eret_cmt        ),
        .lo_in              ( lo_in           ),
        .hi_in              ( hi_in           ),
        .ex_hi_out          ( ex_hi_out       ),
        .ex_lo_out          ( ex_lo_out       ),
        //.cp0_read           ( cp0_read        ),
        .ex_to_mem_valid    ( ex_to_mem_valid ),
        .wb_valid           ( wb_valid        ),
        .mem_allowin        ( mem_allowin     ),
        .mem_valid          ( mem_valid       ),
        .mem_to_wb_valid    ( mem_to_wb_valid ),
        .mem_pc             ( mem_pc          ),
        .mem_inst           ( mem_inst        ),
        .ex_op_RegWrite     ( ex_op_RegWrite  ),
        .ex_op_RegWen       ( ex_op_RegWen    ),
        .ex_rf_waddr        ( ex_rf_waddr     ),
        .mem_op_mul         ( mem_op_mul      ),
        .mem_op_div         ( mem_op_div      ),
        .mem_op_HIWen       ( mem_op_HIWen    ),
        .mem_op_LOWen       ( mem_op_LOWen    ),
        .mem_rf_wdata       ( mem_rf_wdata    ),
        .mem_inst_mt        ( mem_inst_mt     ),
        .mem_hi_res         ( mem_hi_res      ),
        .mem_lo_res         ( mem_lo_res      ),
        .mem_rf_wen         ( mem_rf_wen      ),
        .mem_rf_waddr       ( mem_rf_waddr    ),
        .data_sram_en       ( data_sram_en    ),
        .data_sram_wen      ( data_sram_wen   ),
        .data_sram_addr     ( data_sram_addr  ),
        .data_sram_wdata    ( data_sram_wdata ),
        .data_sram_rdata    ( data_sram_rdata )
    );

    writeback_stage wb(
        .clk                ( clk),
        .resetn                 ( resetn),
        .mem_pc                 ( mem_pc),
        .wb_pc                  (wb_pc),
        .mem_inst               ( mem_inst),
        .wb_inst                (wb_inst),
        .mem_to_wb_valid        ( mem_to_wb_valid),
        .mem_hi_res             ( mem_hi_res),
        .mem_lo_res             ( mem_lo_res),
        .mem_div_res_q          (mem_div_res_q),
        .mem_div_res_r          (mem_div_res_r),
        .mem_mul_res            (mem_mul_res),
        .wb_div_res_q           (wb_div_res_q),
        .wb_div_res_r           (wb_div_res_r),
        .wb_mul_res             ( wb_mul_res),
        .mem_rf_wen             ( mem_rf_wen),
        .mem_rf_waddr           ( mem_rf_waddr),
        .mem_rf_wdata           ( mem_rf_wdata),
        .mem_op_mul             ( mem_op_mul),
        .mem_op_div             ( mem_op_div),
        .wb_op_div              ( wb_op_div         ),
        .wb_op_mul              ( wb_op_mul         ),
        .wb_hi_res              ( wb_hi_res         ),
        .wb_lo_res              ( wb_lo_res         ),
        //.excep_cmt            ( excep_cmt         ),
        //.int_cmt              ( int_cmt           ),
        //.eret_cmt             ( eret_cmt          ),
        .wb_allowin             ( wb_allowin        ),
        .wb_valid               ( wb_valid          ),
        .wb_rf_wen              ( wb_rf_wen         ),
        .wb_rf_waddr            ( wb_rf_waddr       ),
        .wb_rf_wdata            ( wb_rf_wdata       ),
        .debug_wb_pc            ( debug_wb_pc       ),
        .debug_wb_rf_wen        ( debug_wb_rf_wen   ),
        .debug_wb_rf_wnum       ( debug_wb_rf_wnum  ),
        .debug_wb_rf_wdata      ( debug_wb_rf_wdata )
    );

    reg_files rf(
        .clk   ( clk),
        .resetn ( resetn),
        .waddr( wb_rf_waddr),
        .raddr1( rf_raddr1),
        .raddr2( rf_raddr2),
        .wen( wb_rf_wen),
        .wdata( wb_rf_wdata),
        .rdata1( rf_rdata1),
        .rdata2( rf_rdata2)
    );

    reg_hilo hilo( 
        .clk        ( clk),
        .resetn     ( resetn),
        .hi_wen     ( mem_op_HIWen),
        .lo_wen     ( mem_op_LOWen),
        .hi_in( hi_in),
        .lo_in( lo_in),
        .hi( hi_out),
        .lo( lo_out)
    );
/*
    regs_cp0 regs_cp0( 
        .clk( clk),
        .resetn( resetn),
        .inst( mem_inst),
        .pc( mem_pc),
        .mtc0_value( ex_rf_rdata2),//??????
    //	.delay_slot( ),
        .cp0_read( cp0_read),
        .excep_cmt( excep_cmt),
        .int_cmt( int_cmt),
        .eret_cmt(eret_cmt)
    );
*/



endmodule