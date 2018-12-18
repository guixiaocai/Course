module execute(
    input         clk,
    input         resetn,
    input         id_valid,
    input         mem_valid,
    input         id_allowin,
    input         mem_allowin,
    input         div_complete,
    input         lw_hazard,
    input  [31:0] hi_o,
    input  [31:0] lo_o,
    input  [31:0] pc_id,
    input  [31:0] inst_id,
    input  [34:0] ctrl_wb,
    input  [34:0] ctrl_id,
    input  [34:0] ctrl_mem,
    input  [31:0] reg_rdata1,
    input  [31:0] reg_rdata2,
    input  [31:0] alu_src1_id,
    input  [31:0] alu_src2_id,
    input  [ 4:0] reg_waddr_wb,
    input  [31:0] reg_wdata_id,
    input  [ 4:0] reg_waddr_id,
    input  [63:0] mul_result_wb,
    input  [31:0] reg_rdata1_id,
    input  [31:0] reg_rdata2_id,
    input  [31:0] alu_result_ex,
    input  [ 4:0] reg_waddr_mem,
    input  [63:0] mul_result_mem,
    input  [ 1:0] sw_hilo_hazard,
    input  [31:0] div_result_q_wb,
    input  [31:0] div_result_r_wb,
    input  [31:0] div_result_q_mem,
    input  [31:0] div_result_r_mem,
    input  [31:0] sw_data_wdata_id,
    output        ex_valid,
    output        ex_allowin,
    output [31:0] pc_ex,
    output [31:0] inst_ex,
    output [31:0] reg_rdata1_ex,
    output [31:0] reg_rdata2_ex,
    output [4:0] reg_waddr_ex,
    output [34:0] ctrl_ex,
    output [ 3:0] reg_wen_ex,
    output [31:0] hi_o_ex,
    output [31:0] lo_o_ex,
    output [31:0] alu_src1,
    output [31:0] alu_src2,
    output        div,
    input  [31:0] hi_in,
    input  [31:0] lo_in
);
    reg        reg_ex_valid;
    reg [31:0] reg_pc_ex;
    reg [31:0] reg_inst_ex;
    reg [31:0] reg_reg_rdata1_ex;
    reg [31:0] reg_reg_rdata2_ex;
    reg [ 4:0] reg_reg_waddr_ex;
    reg [34:0] reg_ctrl_ex;
    reg [31:0] reg_alu_arc1;
    reg [31:0] reg_alu_src2;

    assign div = (ctrl_ex[17] | ctrl_ex[22]) & ~div_complete;
    assign ex_allowin = mem_allowin & ~div;

    always @(posedge clk) begin
      if(!resetn) begin
        reg_ex_valid      <= 1'b1;
        reg_inst_ex       <= 32'd0;
        reg_ctrl_ex       <= 34'd0;
        reg_reg_waddr_ex  <= 5'd0;
        reg_reg_rdata1_ex <= 32'd0;
        reg_reg_rdata2_ex <= 32'd0;
        reg_alu_arc1      <= 32'd0;
        reg_alu_src2      <= 32'd0;
        reg_pc_ex         <= 32'hbfc00000;
      end
      else begin        
          if(id_valid & ex_allowin) begin
            reg_pc_ex             <= pc_id;
            reg_inst_ex           <= inst_id;
            reg_ctrl_ex           <= ctrl_id;
            reg_reg_waddr_ex      <= reg_waddr_id;
            reg_reg_rdata1_ex     <= reg_rdata1_id;
            reg_reg_rdata2_ex     <= reg_rdata2_id;
            reg_alu_arc1          <= alu_src1_id;
            reg_alu_src2          <= alu_src2_id;
        end
        if(ex_allowin & id_allowin) begin
          reg_ex_valid <= id_valid;
        end else if(ex_allowin)
          reg_ex_valid <= 1'b0;
      end
    end
    
    assign pc_ex             = reg_pc_ex;
    assign inst_ex           = reg_inst_ex;
    assign ctrl_ex           = reg_ctrl_ex;
    assign alu_src1          = reg_alu_arc1;
    assign alu_src2          = reg_alu_src2;
    assign ex_valid          = reg_ex_valid;
    assign reg_wen_ex        = {4{ctrl_ex[13]}};
    assign reg_waddr_ex      = reg_reg_waddr_ex;
    assign reg_rdata1_ex     = reg_reg_rdata1_ex;
    assign reg_rdata2_ex     = reg_reg_rdata2_ex;
    
    assign hi_o_ex = ctrl_ex[20] && (ctrl_mem[17] || ctrl_mem[22]) ? div_result_r_mem     :
                     ctrl_ex[20] && (ctrl_wb[17]  || ctrl_wb[22] ) ? div_result_r_wb      :
                     ctrl_ex[20] && (ctrl_mem[16] || ctrl_mem[24]) ? mul_result_mem[63:32]:
                     ctrl_ex[20] && (ctrl_wb[16]  || ctrl_wb[24] ) ? mul_result_wb[63:32] :
                     ctrl_ex[20] && ctrl_mem[18]                   ? hi_in                :  //mthi & mfhi hazard
                     hi_o; 
    
    assign lo_o_ex = ctrl_ex[21] && (ctrl_mem[17] || ctrl_mem[22]) ? div_result_q_mem    :
                     ctrl_ex[21] && (ctrl_wb[17]  || ctrl_wb[22] ) ? div_result_q_wb     :
                     ctrl_ex[21] && (ctrl_mem[16] || ctrl_mem[24]) ? mul_result_mem[31:0]:
                     ctrl_ex[21] && (ctrl_wb[16]  || ctrl_wb[24] ) ? mul_result_wb[31:0] :
                     ctrl_ex[21] && ctrl_mem[19]                   ? lo_in               :  //mtlo & mflo hazard 
                     lo_o;

endmodule