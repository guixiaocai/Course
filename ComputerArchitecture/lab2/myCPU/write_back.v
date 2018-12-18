module write_back(
    input         clk,
    input         resetn,
    input  [31:0] hi_o,
    input  [31:0] lo_o,
    input  [31:0] pc_mem,
    input  [31:0] data_sram_rdata,
    input  [ 4:0] reg_waddr_mem,
    input  [31:0] alu_result_mem,
    input         mem_valid,
    input         mem_allowin,
    input  [34:0] ctrl_mem,
    input  [ 3:0] reg_wen_mem,
    input  [31:0] result_mem,
    output [4:0 ] reg_waddr_wb,
    output        wb_valid,
    output        wb_allowin,
    output [34:0] ctrl_wb,
    output [ 3:0] reg_wen,
    output [ 4:0] reg_waddr,
    output [31:0] reg_wdata,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_pc,
    output [31:0] debug_wb_rf_wdata,
    input  [63:0] mul_result,
    output [31:0] result_wb,
    input  [31:0] div_result_q_mem,
    input  [31:0] div_result_r_mem,
    input  [63:0] mul_result_mem,
    output [31:0] div_result_q_wb,
    output [31:0] div_result_r_wb,
    output [63:0] mul_result_wb
);

    reg        reg_wb_valid;
    reg [31:0] reg_pc_wb;
    reg [ 4:0] reg_reg_waddr_wb;
    reg [ 3:0] reg_reg_wen_wb;
    reg [34:0] reg_ctrl_wb;
    reg [31:0] reg_result_wb;
    reg [31:0] reg_div_result_r_wb;
    reg [31:0] reg_div_result_q_wb;
    reg [63:0] reg_mul_result_wb;

    always @(posedge clk) begin
      if(!resetn) begin
        reg_wb_valid            <= 1'b1;
        reg_ctrl_wb             <= 24'd0;
        reg_reg_waddr_wb        <= 5'd0;
        reg_reg_wen_wb          <= 4'd0;
        reg_result_wb           <= 32'd0;
        reg_pc_wb               <= 32'hbfc00000;
      end
      else begin
        if(mem_allowin & wb_allowin) begin
          reg_pc_wb             <= pc_mem;
          reg_ctrl_wb           <= ctrl_mem;
          reg_reg_waddr_wb      <= reg_waddr_mem;
          reg_reg_wen_wb        <= reg_wen_mem;
          reg_result_wb         <= result_mem;
          reg_div_result_q_wb   <= div_result_q_mem;
          reg_div_result_r_wb   <= div_result_r_mem;
          reg_mul_result_wb     <= mul_result_mem;
        end
        if(wb_allowin & mem_allowin) begin
          reg_wb_valid          <= mem_valid;
        end else if(wb_allowin)
          reg_wb_valid          <= 1'b0;
      end
    end

    assign wb_allowin        = 1'b1;
    assign debug_wb_pc       = reg_pc_wb;
    assign debug_wb_rf_wnum  = reg_waddr;
    assign debug_wb_rf_wen   = reg_wen;
    assign debug_wb_rf_wdata = reg_wdata;
    assign wb_valid          = reg_wb_valid;
    assign ctrl_wb           = reg_ctrl_wb;
    assign result_wb         = reg_result_wb;
    assign reg_wdata         = reg_result_wb;
    assign reg_waddr_wb      = reg_reg_waddr_wb;
    assign reg_waddr         = reg_reg_waddr_wb;
    assign mul_result_wb     = reg_mul_result_wb;
    assign div_result_q_wb   = reg_div_result_q_wb;
    assign div_result_r_wb   = reg_div_result_r_wb;
    assign reg_wen           = reg_reg_wen_wb&{4{wb_valid}};

endmodule