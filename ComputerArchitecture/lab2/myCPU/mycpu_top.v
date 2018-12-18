
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
    wire [31:0] inst_if, inst_id, inst_ex;
    wire [31:0] npc, pc_if, pc_id, pc_ex, pc_mem;
    wire [ 3:0] reg_wen, reg_wen_ex, reg_wen_mem;
    wire [31:0] sw_data_wdata_id, sw_data_wdata_ex;
    wire [34:0] ctrl, ctrl_ex, ctrl_id, ctrl_mem, ctrl_wb;
    wire [ 4:0] reg_waddr, reg_waddr_ex, reg_waddr_id, reg_waddr_mem;
    wire [ 4:0] reg_waddr_wb, reg_raddr1, reg_raddr2;
    wire [31:0] alu_src1_id, alu_src2_id, alu_src1, alu_src2;
    wire [31:0] alu_result_ex, alu_result_mem, result_mem, result_wb, reg_wdata;
    wire [31:0] reg_rdata1, reg_rdata1_id, reg_rdata1_ex, reg_rdata1_mem;
    wire [31:0] reg_rdata2, reg_rdata2_id, reg_rdata2_ex, reg_rdata2_mem;
    wire [31:0] hi_o, lo_o, hi_o_ex, lo_o_ex, lo_o_mem, hi_o_mem, hi_in, lo_in;
    wire [31:0] div_result_q, div_result_q_mem, div_result_q_wb;
    wire [31:0] div_result_r, div_result_r_mem, div_result_r_wb;
    wire [63:0] mul_result, mul_result_mem, mul_result_wb;
    wire        id_valid, if_valid, ex_valid, mem_valid, wb_valid, div_complete;
    wire        if_allowin, id_allowin, mem_allowin, wb_allowin, ex_allowin, div;

    pc pc(
        .pc_if          (pc_if       ),
        .pc_id          (pc_id       ),
        .alu_src1_id    (alu_src1_id ),
        .ctrl           (ctrl        ),
        .inst_id        (inst_id     ),
        .npc            (npc         )
    );

    ctrl_unit ctrl_unit(
        .inst           (inst_id      ),
        .alu_src1_id    (alu_src1_id  ),
        .alu_src2_id    (alu_src2_id  ),
        .ctrl           (ctrl         )
    );

    reg_file reg_file(
        .clk            (clk         ),
        .resetn         (resetn      ),
        .reg_wen        (reg_wen     ),
        .reg_raddr1     (reg_raddr1  ),
        .reg_raddr2     (reg_raddr2  ),
        .reg_waddr      (reg_waddr   ),
        .reg_wdata      (reg_wdata   ),
        .reg_rdata1     (reg_rdata1  ),
        .reg_rdata2     (reg_rdata2  )
    );

    inst_fetch inst_fetch(
        .clk                (clk            ),
        .resetn             (resetn         ),
        .inst_sram_rdata    (inst_sram_rdata),
        .npc                (npc            ),
        .id_allowin         (id_allowin     ),
        .if_allowin         (if_allowin     ),
        .if_valid           (if_valid       ),
        .pc_if              (pc_if          ),
        .inst_if            (inst_if        ),
        .inst_sram_en       (inst_sram_en   ),
        .inst_sram_wen      (inst_sram_wen  ),
        .inst_sram_wdata    (inst_sram_wdata),
        .inst_sram_addr     (inst_sram_addr )
    );

    inst_decode inst_decode(
        .clk                (clk             ),
        .resetn             (resetn          ),
        .reg_rdata1         (reg_rdata1      ),
        .reg_rdata2         (reg_rdata2      ),
        .pc_if              (pc_if           ),
        .inst_if            (inst_if         ),
        .inst_ex            (inst_ex         ),
        .alu_result_ex      (alu_result_ex   ),
        .ex_allowin         (ex_allowin      ),
        .if_valid           (if_valid        ),
        .if_allowin         (if_allowin      ),
        .reg_waddr_ex       (reg_waddr_ex    ),
        .reg_waddr_mem      (reg_waddr_mem   ),
        .reg_waddr_wb       (reg_waddr_wb    ),
        .ctrl               (ctrl            ),
        .result_mem         (result_mem      ),
        .reg_wdata          (reg_wdata       ),
        .pc_id              (pc_id           ),
        .inst_id            (inst_id         ),
        .reg_rdata1_id      (reg_rdata1_id   ),
        .reg_rdata2_id      (reg_rdata2_id   ),
        .reg_waddr_id       (reg_waddr_id    ),
        .id_allowin         (id_allowin      ),
        .id_valid           (id_valid        ),
        .reg_raddr1         (reg_raddr1      ),
        .reg_raddr2         (reg_raddr2      ),
        .ctrl_id            (ctrl_id         ),
        .alu_src1_id        (alu_src1_id     ),
        .alu_src2_id        (alu_src2_id     ),
        .ctrl_ex            (ctrl_ex         ),
        .reg_wen            (reg_wen         ),
        .reg_wen_ex         (reg_wen_ex      ),
        .reg_wen_mem        (reg_wen_mem     ),
        .ex_valid           (ex_valid        ),
        .ctrl_mem           (ctrl_mem        )
    );

    execute execute(
        .clk                 (clk              ),
        .resetn              (resetn           ),
        .pc_id               (pc_id            ),
        .inst_id             (inst_id          ),
        .id_valid            (id_valid         ),
        .id_allowin          (id_allowin       ),
        .mem_allowin         (mem_allowin      ),
        .reg_rdata1_id       (reg_rdata1_id    ),
        .reg_rdata2_id       (reg_rdata2_id    ),
        .reg_waddr_id        (reg_waddr_id     ),
        .reg_waddr_mem       (reg_waddr_mem    ),
        .reg_waddr_wb        (reg_waddr_wb     ),
        .ctrl_id             (ctrl_id          ),
        .ctrl_mem            (ctrl_mem         ),
        .alu_src1_id         (alu_src1_id      ),
        .alu_src2_id         (alu_src2_id      ),
        .hi_o                (hi_o             ),
        .lo_o                (lo_o             ),
        .reg_rdata1          (reg_rdata1       ),
        .reg_rdata2          (reg_rdata2       ),
        .ex_valid            (ex_valid         ),
        .ex_allowin          (ex_allowin       ),
        .pc_ex               (pc_ex            ),
        .inst_ex             (inst_ex          ),
        .reg_rdata1_ex       (reg_rdata1_ex    ),
        .reg_rdata2_ex       (reg_rdata2_ex    ),
        .reg_waddr_ex        (reg_waddr_ex     ),
        .alu_result_ex       (alu_result_ex    ),
        .ctrl_ex             (ctrl_ex          ),
        .reg_wen_ex          (reg_wen_ex       ),
        .hi_o_ex             (hi_o_ex          ),
        .lo_o_ex             (lo_o_ex          ),
        .div_complete        (div_complete     ),
        .alu_src1            (alu_src1         ),
        .alu_src2            (alu_src2         ),
        .div                 (div              ),
        .mem_valid           (mem_valid        ),
        .div_result_q_mem    (div_result_q_mem ),
        .div_result_r_mem    (div_result_r_mem ),
        .div_result_q_wb     (div_result_q_wb  ),
        .div_result_r_wb     (div_result_r_wb  ),
        .mul_result_mem      (mul_result_mem   ),
        .mul_result_wb       (mul_result_wb    ),
        .ctrl_wb             (ctrl_wb          ),
        .hi_in               (hi_in            ),
        .lo_in               (lo_in            )
    );

    acc_mem acc_mem(
        .clk                 (clk             ),
        .resetn              (resetn          ),
        .pc_ex               (pc_ex           ),
        .inst_ex             (inst_ex         ),
        .reg_waddr_ex        (reg_waddr_ex    ),
        .alu_result_ex       (alu_result_ex   ),
        .reg_rdata1_ex       (reg_rdata1_ex   ),
        .reg_rdata2_ex       (reg_rdata2_ex   ),
        .ex_valid            (ex_valid        ),
        .ex_allowin          (ex_allowin      ),
        .wb_allowin          (wb_allowin      ),
        .div_complete        (div_complete    ),
        .ctrl_ex             (ctrl_ex         ),
        .reg_wen_ex          (reg_wen_ex      ),
        .data_sram_rdata     (data_sram_rdata ),
        .reg_waddr_mem       (reg_waddr_mem   ),
        .pc_mem              (pc_mem          ),
        .alu_result_mem      (alu_result_mem  ),
        .mem_valid           (mem_valid       ),
        .mem_allowin         (mem_allowin     ),
        .ctrl_mem            (ctrl_mem        ),
        .reg_wen_mem         (reg_wen_mem     ),
        .data_sram_en        (data_sram_en    ),
        .data_sram_wen       (data_sram_wen   ),
        .data_sram_addr      (data_sram_addr  ),
        .data_sram_wdata     (data_sram_wdata ),
        .hi_o_ex             (hi_o_ex         ),
        .lo_o_ex             (lo_o_ex         ),
        .hi_o_mem            (hi_o_mem        ),
        .lo_o_mem            (lo_o_mem        ),
        .result_mem          (result_mem      ),
        .result_wb           (result_wb       ),
        .reg_wdata           (reg_wdata       ),
        .wb_valid            (wb_valid        ),
        .div_result_q        (div_result_q    ),
        .div_result_r        (div_result_r    ),
        .mul_result          (mul_result      ),
        .div_result_q_mem    (div_result_q_mem),
        .div_result_r_mem    (div_result_r_mem),
        .mul_result_mem      (mul_result_mem  ),
        .hi_in               (hi_in           ),
        .lo_in               (lo_in           )
    );

    write_back write_back(
        .clk                 (clk              ),
        .resetn              (resetn           ),
        .hi_o                (hi_o             ),
        .lo_o                (lo_o             ),
        .pc_mem              (pc_mem           ),
        .data_sram_rdata     (data_sram_rdata  ),
        .reg_waddr_mem       (reg_waddr_mem    ),
        .alu_result_mem      (alu_result_mem   ),
        .mem_valid           (mem_valid        ),
        .mem_allowin         (mem_allowin      ),
        .ctrl_mem            (ctrl_mem         ),
        .reg_wen_mem         (reg_wen_mem      ),
        .result_mem          (result_mem       ),
        .reg_waddr_wb        (reg_waddr_wb     ),
        .wb_valid            (wb_valid         ),
        .wb_allowin          (wb_allowin       ),
        .ctrl_wb             (ctrl_wb          ),
        .reg_wen             (reg_wen          ),
        .reg_waddr           (reg_waddr        ),
        .reg_wdata           (reg_wdata        ),
        .debug_wb_rf_wen     (debug_wb_rf_wen  ),
        .debug_wb_rf_wnum    (debug_wb_rf_wnum ),
        .debug_wb_pc         (debug_wb_pc      ),
        .debug_wb_rf_wdata   (debug_wb_rf_wdata),
        .mul_result          (mul_result),
        .result_wb           (result_wb        ),
        .div_result_q_mem    (div_result_q_mem ),
        .div_result_r_mem    (div_result_r_mem ),
        .mul_result_mem      (mul_result_mem   ),
        .div_result_q_wb     (div_result_q_wb  ),
        .div_result_r_wb     (div_result_r_wb  ),
        .mul_result_wb       (mul_result_wb    )
    );

    hilo_reg hilo_reg(
        .clk           (clk       ),
        .resetn        (resetn    ),
        .ctrl          (ctrl_mem  ),
        .hi_in         (hi_in     ),
        .lo_in         (lo_in     ),
        .hi_o          (hi_o      ),
        .lo_o          (lo_o      )
    );

    alu alu(
        .alu_src1         (alu_src1     ),
        .alu_src2         (alu_src2     ),
        .alu_op           (ctrl_ex[3:0] ),
        .alu_result_ex    (alu_result_ex)
    );

    mul mul(
		.mul_clk        (clk        ),
		.resetn         (resetn     ),
		.mul_signed     (ctrl_id[16]),
		.x              (alu_src1_id),
		.y              (alu_src2_id),
		.result         (mul_result ),
        .id_valid       (id_valid),
        .ex_allowin     (ex_allowin)
	);

	div u_div(
		.div_clk       (clk         ),
		.resetn        (resetn      ),
		.div_signed    (ctrl_ex[17] ),
		.div           (div         ),
		.x             (alu_src1    ),
		.y             (alu_src2    ),
		.s             (div_result_q),
		.r             (div_result_r),
		.complete      (div_complete)
	);
    
endmodule