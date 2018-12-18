module inst_decode(
    input         clk,
    input         resetn,
    input  [31:0] reg_rdata1,
    input  [31:0] reg_rdata2,
    input  [31:0] pc_if,
    input  [31:0] inst_if,
    input  [31:0] inst_ex,
    input  [31:0] alu_result_ex,
    input         ex_allowin,
    input         if_valid,
    input         if_allowin,
    input  [4:0 ] reg_waddr_ex,
    input  [4:0 ] reg_waddr_mem,
    input  [4:0 ] reg_waddr_wb,
    input  [34:0] ctrl,
    input  [31:0] result_mem,
    input  [31:0] reg_wdata,
    output [31:0] pc_id,
    output [31:0] inst_id,
    output [31:0] reg_rdata1_id,
    output [31:0] reg_rdata2_id,
    output [4:0 ] reg_waddr_id,
    output        id_allowin,
    output        id_valid,
    output [4:0 ] reg_raddr1,
    output [4:0 ] reg_raddr2,
    output [34:0] ctrl_id,
    output [31:0] alu_src1_id,
    output [31:0] alu_src2_id,
    input  [34:0] ctrl_ex,
    input  [3:0 ] reg_wen,
    output [31:0] reg_wdata_id,
    input  [3:0 ] reg_wen_ex,
    input  [3:0 ] reg_wen_mem,
    input         ex_valid,
    input  [34:0] ctrl_mem
    //output [31:0] sw_data_wdata_id
);
    reg [31:0] reg_pc_id;
    reg [31:0] reg_inst_id;
    reg        reg_id_valid;

    wire [31:0] imm_32;
    wire [ 4:0] rs = inst_id[25:21];
    wire [ 4:0] rt = inst_id[20:16];

    assign id_allowin = ex_allowin & !(lw_hazard & ex_valid);

    always @(posedge clk) begin
      if(!resetn) begin
        reg_id_valid  <= 1'b1;
        reg_pc_id     <= 32'hbfc00000;
        reg_inst_id   <= 32'd0;
      end
      else  begin
        if(if_allowin & id_allowin) begin
          reg_pc_id   <= pc_if;
          reg_inst_id <= inst_if;
        end 
        if(id_allowin & if_allowin) begin
          reg_id_valid <= if_valid;
        end
        else if(id_allowin)
          reg_id_valid <= 1'b0;
      end
    end

    assign ctrl_id       = ctrl;
    assign pc_id         = reg_pc_id;
    assign inst_id       = reg_inst_id;
    assign id_valid      = reg_id_valid;
    assign reg_wdata_id  = reg_wdata;
    assign reg_raddr1    = inst_id[25:21];
    assign reg_raddr2    = inst_id[20:16];

    assign reg_waddr_id  = ctrl[ 6] ? 5'd31         :
                           ctrl[11] ? inst_id[15:11]:
                                      inst_id[20:16];

    assign imm_32      = ctrl[12] ? {{16{inst_id[15]}}, inst_id[15:0]} : {16'd0, inst_id[15:0]};

    // new alu_src2 with forwarding
    assign alu_src1_id = ctrl[15] ? {27'd0, inst_id[10:6]}:                         
                         (inst_id[25:21]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && ~ctrl_ex[14] && reg_wen_ex) ? alu_result_ex:
                         (inst_id[25:21]==reg_waddr_mem && reg_waddr_mem!=5'd0 && reg_wen_mem               ) ? result_mem   :
                         (inst_id[25:21]==reg_waddr_wb  && reg_waddr_wb !=5'd0 && reg_wen                   ) ? reg_wdata    :
                                                                                                                reg_rdata1   ;
    // new alu_src2 with forwarding
    assign alu_src2_id = ctrl[9] ? imm_32:
                         (inst_id[20:16]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && ~ctrl_ex[14] && reg_wen_ex) ? alu_result_ex:
                         (inst_id[20:16]==reg_waddr_mem && reg_waddr_mem!=5'd0 && reg_wen_mem               ) ? result_mem   :
                         (inst_id[20:16]==reg_waddr_wb  && reg_waddr_wb !=5'd0 && reg_wen                   ) ? reg_wdata    :
                                                                                                                reg_rdata2   ;
    // new reg_rdata1 with mthi/mtlo hazard forwarding
    assign reg_rdata1_id = (inst_id[25:21]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && ctrl_id[19:18] && reg_wen_ex ) ? alu_result_ex:
                               (inst_id[25:21]==reg_waddr_mem && reg_waddr_mem!=5'd0 && ctrl_id[19:18] && reg_wen_mem) ? result_mem   :
                               (inst_id[25:21]==reg_waddr_wb  && reg_waddr_wb !=5'd0 && ctrl_id[19:18] && reg_wen    ) ? reg_wdata    :
                                                                                                                      reg_rdata1   ;
    // new reg_rdata2 with sw hazard forwarding
    assign reg_rdata2_id =  (inst_id[20:16]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && ctrl_id[23] && reg_wen_ex ) ? alu_result_ex:
                               (inst_id[20:16]==reg_waddr_mem && reg_waddr_mem!=5'd0 && ctrl_id[23] && reg_wen_mem) ? result_mem   :
                               (inst_id[20:16]==reg_waddr_wb  && reg_waddr_wb !=5'd0 && ctrl_id[23] && reg_wen    ) ? reg_wdata    :
                                                                                                                      reg_rdata2   ;
    // lw hazard, stall pipeline
    assign lw_hazard   = (inst_id[25:21]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && (ctrl_ex[14] || ctrl_ex[21:20])) || 
                         (inst_id[20:16]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && (ctrl_ex[14] || ctrl_ex[21:20])) ||
                         //(inst_id[25:21]==reg_waddr_mem && reg_waddr_mem!=5'd0 && ctrl_mem[21:20]                ) ||
                         //(inst_id[20:16]==reg_waddr_mem && reg_waddr_mem!=5'd0 && ctrl_mem[21:20]                ) ||
                         (inst_id[25:21]==reg_waddr_ex  && reg_waddr_ex !=5'd0 && ctrl_id[19:18]                 ) ||
                         (inst_id[25:21]==reg_waddr_mem && reg_waddr_mem!=5'd0 && ctrl_id[19:18]                 ) ||
                         (inst_id[25:21]==reg_waddr_wb  && reg_waddr_wb !=5'd0 && ctrl_id[19:18]                 ) ;
                         
endmodule