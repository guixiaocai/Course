module acc_mem(
    input        clk,
    input        resetn,
    input [31:0] pc_ex,
    input [31:0] inst_ex,
    input [ 4:0] reg_waddr_ex,
    input [31:0] alu_result_ex,
    input [31:0] reg_rdata1_ex,
    input [31:0] reg_rdata2_ex,
    input         ex_valid,
    input         ex_allowin,
    input         wb_allowin,
    input         div_complete,
    input  [34:0] ctrl_ex,
    input  [ 3:0] reg_wen_ex, 
    input  [31:0] data_sram_rdata,
    //input  [31:0] sw_data_wdata_ex,
    output [ 4:0] reg_waddr_mem,
    output [31:0] pc_mem,
    output [31:0] alu_result_mem,
    //output [31:0] reg_rdata1_mem,
    //output [31:0] reg_rdata2_mem,
    output        mem_valid,
    output        mem_allowin,
    output [34:0] ctrl_mem,
    output [ 3:0] reg_wen_mem,
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] hi_o_ex,
    input  [31:0] lo_o_ex,
    output [31:0] hi_o_mem,
    output [31:0] lo_o_mem,
    output [31:0] result_mem,
    input  [31:0] result_wb,
    input  [31:0] reg_wdata,
    input         wb_valid,
    input  [31:0] div_result_q,
    input  [31:0] div_result_r,
    input  [63:0] mul_result,
    output [31:0] div_result_q_mem,
    output [31:0] div_result_r_mem,
    output [63:0] mul_result_mem,
    output [31:0] hi_in,
    output [31:0] lo_in
);
    reg [31:0] reg_pc_mem;
    reg [31:0] reg_reg_rdata2_mem;
    reg [31:0] reg_reg_rdata1_mem;
    reg [31:0] reg_alu_result_mem;
    reg [ 4:0] reg_reg_waddr_mem;
    reg [34:0] reg_ctrl_mem;
    reg [ 3:0] reg_reg_wen_mem;
    reg [31:0] reg_hi_o_mem;
    reg [31:0] reg_lo_o_mem;
    reg        reg_mem_valid;
    reg [31:0] reg_reg_wdata;
    reg [31:0] reg_div_result_q_mem;
    reg [31:0] reg_div_result_r_mem;
    reg [63:0] reg_mul_result_mem;
    //reg [31:0] reg_sw_data_wdata_mem;
    reg [31:0] data_rdata;
    reg [31:0] data_wdata;

    wire [ 1:0] ea = data_sram_addr[1:0];
    wire [ 3:0] write_strb;
    wire        lw_stall = ctrl_mem[14] & wb_valid;
    assign mem_allowin = wb_allowin & !lw_stall;

    always @(posedge clk) begin
      if(!resetn) begin
        reg_mem_valid      <= 1'b1;
        reg_pc_mem         <= 32'hbfc00000;
        reg_reg_rdata1_mem <= 32'd0;
        reg_reg_rdata2_mem <= 32'd0;
        reg_alu_result_mem <= 32'd0;
        reg_reg_waddr_mem  <= 5'd0;
        reg_ctrl_mem       <= 24'd0;
        reg_reg_wen_mem    <= 4'd0;
        reg_hi_o_mem       <= 32'd0;
        reg_lo_o_mem       <= 32'd0;
        reg_reg_wdata      <= 32'd0;
      end
      else begin    
        if(ex_allowin & mem_allowin) begin
          reg_pc_mem             <= pc_ex;
          reg_reg_rdata1_mem     <= reg_rdata1_ex;
          reg_reg_rdata2_mem     <= reg_rdata2_ex;
          reg_alu_result_mem     <= alu_result_ex;
          reg_reg_waddr_mem      <= reg_waddr_ex;
          reg_ctrl_mem           <= ctrl_ex;
          reg_reg_wen_mem        <= reg_wen_ex;
          reg_hi_o_mem           <= hi_o_ex;
          reg_lo_o_mem           <= lo_o_ex;
          reg_reg_wdata          <= reg_wdata;
          reg_div_result_q_mem   <= div_result_q;
          reg_div_result_r_mem   <= div_result_r;
          reg_mul_result_mem     <= mul_result;
          //reg_sw_data_wdata_mem  <= sw_data_wdata_ex;
        end
        if(mem_allowin & ex_allowin) begin
          reg_mem_valid <= ex_valid;
        end
        else if(mem_allowin) 
          reg_mem_valid <= 1'b0;
      end
    end

    assign hi_o_mem           = reg_hi_o_mem;
    assign lo_o_mem           = reg_lo_o_mem;
    assign mem_valid          = reg_mem_valid;
    assign pc_mem             = reg_pc_mem;
    assign alu_result_mem     = reg_alu_result_mem;
    assign reg_waddr_mem      = reg_reg_waddr_mem;
    assign ctrl_mem           = reg_ctrl_mem;
    assign reg_wen_mem        = reg_reg_wen_mem&{4{mem_valid}};
    assign data_sram_en       = reg_mem_valid;
    assign div_result_q_mem   = reg_div_result_q_mem;
    assign div_result_r_mem   = reg_div_result_r_mem;
    assign mul_result_mem     = reg_mul_result_mem;
    assign data_sram_addr     = alu_result_mem;
    assign data_sram_wen      = ~ctrl_mem[13] ? write_strb : 4'd0;

    assign result_mem = ctrl_mem[20] ? hi_o_mem       :
                        ctrl_mem[21] ? lo_o_mem       :
                        ctrl_mem[ 7] ? pc_mem + 32'd8 :
                        ctrl_mem[14] ? data_rdata     :
                                       alu_result_mem ;

    assign hi_in =   ctrl_mem[18]                 ? reg_reg_rdata1_mem   :
                    (ctrl_mem[16] | ctrl_mem[24]) ? mul_result_mem[63:32]:
                    (ctrl_mem[17] | ctrl_mem[22]) ? div_result_r_mem     :
                                                    reg_reg_rdata1_mem   ;

    assign lo_in =   ctrl_mem[19]                 ? reg_reg_rdata1_mem  :
                    (ctrl_mem[16] | ctrl_mem[24]) ? mul_result_mem[31:0]:
                    (ctrl_mem[17] | ctrl_mem[22]) ? div_result_q_mem    :
                                                    reg_reg_rdata1_mem  ;
    
    //muxes for swl, swr, sb, sh
    assign data_sram_wdata[31:24] = ctrl_mem[25] && ea!=2'b11                 ? 8'd0                        :
                                    ctrl_mem[26] && ea==2'b01                 ? reg_reg_rdata2_mem[23:16]:
                                    ctrl_mem[26] && ea==2'b11 || ctrl_mem[27] ? reg_reg_rdata2_mem[ 7: 0]:
                                    ctrl_mem[26] && ea==2'b10 || ctrl_mem[28] ? reg_reg_rdata2_mem[15: 8]:
                                                                                  reg_reg_rdata2_mem[31:24];

    assign data_sram_wdata[23:16] = ctrl_mem[26] && ea==2'b11 || ctrl_mem[25] && !ea[1] ? 8'd0                        :
                                    ctrl_mem[26] && ea==2'b10 || ctrl_mem[28:27]          ? reg_reg_rdata2_mem[ 7: 0]:
                                    ctrl_mem[26] && ea==2'b01                             ? reg_reg_rdata2_mem[15: 8]:
                                    ctrl_mem[25] && ea==2'b10                             ? reg_reg_rdata2_mem[31:24]:
                                                                                              reg_reg_rdata2_mem[23:16];

    assign data_sram_wdata[15: 8] = ctrl_mem[25] && ea==2'b00 || ctrl_mem[26] && ea[1] ? 8'd0                        :
                                    ctrl_mem[26] && ea==2'b01 || ctrl_mem[27]             ? reg_reg_rdata2_mem[ 7: 0]:
                                    ctrl_mem[25] && ea==2'b01                             ? reg_reg_rdata2_mem[31:24]:
                                    ctrl_mem[25] && ea==2'b10                             ? reg_reg_rdata2_mem[23:16]:
                                                                                              reg_reg_rdata2_mem[15: 8];

    assign data_sram_wdata[ 7: 0] = ctrl_mem[26] && ea!=2'b00 ? 8'd0                     :
                                    ctrl_mem[25] && ea==2'b10 ? reg_reg_rdata2_mem[15: 8]:
                                    ctrl_mem[25] && ea==2'b00 ? reg_reg_rdata2_mem[31:24]:
                                    ctrl_mem[25] && ea==2'b01 ? reg_reg_rdata2_mem[23:16]:
                                                                reg_reg_rdata2_mem[ 7: 0];
//yulai data_sram_rdata 等一拍或者直接赋值部分位

    assign write_strb = ({4{ctrl_mem[25]}}&{ea[1]&ea[0], ea[1], ea[1]|ea[0], 1'b1}) |
                        ({4{ctrl_mem[26]}}&{1'b1, ~ea[1]|~ea[0], ~ea[1], ~ea[1]&~ea[0]}) |
                        ({4{ctrl_mem[27]}}&{ea[1]&ea[0], ea[1]&~ea[0], ~ea[1]&ea[0], ~ea[1]&~ea[0]}) |
                        ({4{ctrl_mem[28]}}&{ea[1], ea[1], ~ea[1], ~ea[1]}) |
                        ({4{ctrl_mem[23]&!ctrl_mem[28:25]}});
/*
    always @ (*) begin
        case (ctrl_mem[28:25])
          //swl
          4'b0001: 
            case (ea)
              2'b00: data_wdata[ 7: 0] = reg_reg_rdata2_mem[31:24];
              2'b01: data_wdata[15: 0] = reg_reg_rdata2_mem[31:16];
              2'b10: data_wdata[23: 0] = reg_reg_rdata2_mem[31: 8];
              default: data_wdata[31: 0] = reg_reg_rdata2_mem[31: 0];
            endcase
          //swr
          4'b0010: 
            case (ea)
              2'b01: data_wdata[31: 8] = reg_reg_rdata2_mem[23: 0];
              2'b10: data_wdata[31:16] = reg_reg_rdata2_mem[15: 0];
              2'b11: data_wdata[31:24] = reg_reg_rdata2_mem[ 7: 0];
              default: data_wdata[31: 0] = reg_reg_rdata2_mem[31: 0];
            endcase
          //sb
          4'b0100: 
            case (ea)
              2'b00: data_wdata[ 7: 0] = reg_reg_rdata2_mem[ 7: 0];
              2'b01: data_wdata[15: 8] = reg_reg_rdata2_mem[ 7: 0];
              2'b10: data_wdata = {reg_reg_rdata2_mem[ 7: 0]};
              default: data_wdata[31:24] = reg_reg_rdata2_mem[ 7: 0];
            endcase
          //sh
          4'b1000: 
            case (ea)
              2'b00, 2'b01: data_wdata[15: 0] = reg_reg_rdata2_mem[15: 0];
              default: data_wdata[31:16] = reg_reg_rdata2_mem[15: 0];
            endcase
          default:  data_wdata[31: 0] = reg_reg_rdata2_mem[31: 0];
        endcase
    end

*/

    //muxes for lb, lbu, lh, lhu, lwl, lwr	
    always @ (*) begin
        case (ctrl_mem[34:29])
          //lwl
          6'b000001: data_rdata = ea==2'd0 ? {data_sram_rdata[ 7: 0], reg_reg_rdata2_mem[23: 0]}://xiugai  yuanlai
                                  ea==2'd1 ? {data_sram_rdata[15: 0], reg_reg_rdata2_mem[15: 0]}:
                                  ea==2'd2 ? {data_sram_rdata[23: 0], reg_reg_rdata2_mem[ 7: 0]}:
                                               data_sram_rdata                                       ;
          //lwr
          6'b000010: data_rdata = ea==2'd0 ? data_sram_rdata                                       :
                                  ea==2'd1 ? {reg_reg_rdata2_mem[31:24], data_sram_rdata[31: 8]}:
                                  ea==2'd2 ? {reg_reg_rdata2_mem[31:16], data_sram_rdata[31:16]}:
                                               {reg_reg_rdata2_mem[31: 8], data_sram_rdata[31:24]};
          //lb
          6'b000100: data_rdata = ea==2'd0 ? {{24{data_sram_rdata[ 7]}},data_sram_rdata[ 7: 0]}:
                                  ea==2'd1 ? {{24{data_sram_rdata[15]}},data_sram_rdata[15: 8]}:
                                  ea==2'd2 ? {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}:
                                               {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]};
          //lbu
          6'b001000: data_rdata = ea==2'd0 ? {{24{1'b0}},data_sram_rdata[ 7: 0]}:
                                  ea==2'd1 ? {{24{1'b0}},data_sram_rdata[15: 8]}:
                                  ea==2'd2 ? {{24{1'b0}},data_sram_rdata[23:16]}:
                                               {{24{1'b0}},data_sram_rdata[31:24]};
          //lh
          6'b010000: data_rdata = ea[1] ? {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}:
                                            {{16{data_sram_rdata[15]}},data_sram_rdata[15: 0]};
          //lhu
          6'b100000: data_rdata = ea[1] ? {{16{1'b0}},data_sram_rdata[31:16]}:
                                            {{16{1'b0}},data_sram_rdata[15: 0]};
          default: data_rdata = data_sram_rdata;
        endcase
    end






endmodule