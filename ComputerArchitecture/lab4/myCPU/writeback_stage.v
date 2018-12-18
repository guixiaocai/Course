module writeback_stage(
    input   clk,
    input   resetn,

    input   [31:0] mem_inst,
    input   [31:0] mem_pc,
    output [31:0] wb_pc,
    output [31:0] wb_inst,
    input   mem_to_wb_valid,

// control signals from mem stage

    input [31:0] mem_rf_wdata,
    //input [31:0] mem_rf_res,

// hi/lo 选择
    //input [2:0] mem_op_HIwen,
    //input [2:0] mem_op_LOWen,
    input [31:0] mem_hi_res,
    input [31:0] mem_lo_res,


//rf_wdata的�?�择在MEM�?? ???????
    input [3:0] mem_rf_wen,
    input [4:0] mem_rf_waddr,
    input [ 1:0] mem_op_mul,
	input [ 1:0] mem_op_div,
    input  [31:0] mem_div_res_q,
	input  [31:0] mem_div_res_r,
	input  [63:0] mem_mul_res,
//    input [] mem_regdata,

    input excep_cmt,
    input int_cmt,
    input eret_cmt,

/*    
    input [31:0] cp0_read,*/

    output wb_allowin,
    output wb_valid,
    output [ 1:0] wb_op_div,
    output [ 1:0] wb_op_mul,
    output [31:0] wb_hi_res,
    output [31:0] wb_lo_res,
//这三个可以直接和 regfile连接
    output [3:0]  wb_rf_wen,
    output [4:0]  wb_rf_waddr,
    output [31:0] wb_rf_wdata,
    output [31:0] wb_div_res_q,
    output [31:0] wb_div_res_r,
    output [63:0] wb_mul_res,
    //debug signals
	output [31:0] debug_wb_pc,
	output [3:0] debug_wb_rf_wen,
	output [4:0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata
);

    //control signals
    reg reg_wb_valid;
    wire wb_ready_go;
    wire out_allow;

    assign wb_valid = reg_wb_valid;
    assign out_allow = 1'b1;
    assign wb_ready_go = 1'b1;
    assign wb_allowin = !wb_valid || wb_ready_go && out_allow;

    always@(posedge clk)
    begin
        if(!resetn)    begin
            reg_wb_valid <= 1'd0;
        end
        else if (wb_allowin)    begin
            reg_wb_valid <= mem_to_wb_valid;
        end
    end

    reg [31:0] reg_wb_pc;
    reg [31:0] reg_wb_inst;
    reg [ 3:0] reg_wb_rf_wen;
    reg [ 4:0] reg_wb_rf_waddr;
    reg [31:0] reg_wb_rf_wdata;
    reg [ 1:0] reg_wb_op_mul;
    reg [ 1:0] reg_wb_op_div;
    reg [31:0] reg_wb_hi_res;
    reg [31:0] reg_wb_lo_res;
    reg [31:0] reg_wb_div_res_q;
	reg [31:0] reg_wb_div_res_r;
	reg [63:0] reg_wb_mul_res;

    always@(posedge clk)
    begin
        if(!resetn)    begin
            reg_wb_pc <= 32'hbfc00000;
            reg_wb_inst <= 32'd0;
            reg_wb_rf_wen  <= 4'd0;
            reg_wb_rf_waddr <= 5'd0;
            reg_wb_rf_wdata <= 32'd0;
            reg_wb_op_mul   <= 2'd0;
            reg_wb_op_div   <= 2'd0;
            reg_wb_hi_res   <= 32'd0;
            reg_wb_lo_res   <= 32'd0;
        end
    //  预留中断、例外清�?? 
        /*else if (excep_cmt||int_cmt||eret_cmt)    begin
            reg_wb_pc <= 32'hbfc00000;
            reg_wb_inst <= 32'd0; 
        end*/
        if (wb_allowin && mem_to_wb_valid)    begin
            reg_wb_pc <= mem_pc;
            reg_wb_inst <= mem_inst;
            reg_wb_rf_wen <= mem_rf_wen;
            reg_wb_rf_waddr <= mem_rf_waddr;
            reg_wb_rf_wdata <= mem_rf_wdata;
            reg_wb_op_mul   <= mem_op_mul;
            reg_wb_op_div   <= mem_op_div;
            reg_wb_hi_res   <= mem_hi_res;
            reg_wb_lo_res   <= mem_lo_res;
            reg_wb_div_res_q <= mem_div_res_q;
            reg_wb_div_res_r <= mem_div_res_r;
            reg_wb_mul_res <= mem_mul_res;
        end
    end

    assign wb_pc = reg_wb_pc;
    assign wb_inst = reg_wb_inst;
    assign wb_rf_wen = reg_wb_rf_wen;
    assign wb_rf_waddr = reg_wb_rf_waddr;
    assign wb_rf_wdata = reg_wb_rf_wdata;
    assign wb_op_mul = reg_wb_op_mul;
    assign wb_op_div = reg_wb_op_div;
    assign wb_hi_res  = reg_wb_hi_res;
    assign wb_lo_res  = reg_wb_lo_res;
    assign wb_div_res_q = reg_wb_div_res_q;
    assign wb_div_res_r = reg_wb_div_res_r;
    assign wb_mul_res = reg_wb_mul_res;

    assign debug_wb_pc = wb_pc;
    assign debug_wb_rf_wen = wb_rf_wen &{4{wb_valid}};
    assign debug_wb_rf_wnum = wb_rf_waddr;
    assign debug_wb_rf_wdata = wb_rf_wdata;
/*
reg [31:0] reg_wb_res;
//assign wb_res = reg_wb_res;
always@(posedge clk)
begin
	if(!resetn)
	begin
		reg_wb_res <= 32'd0;
	end
	else if (excep_cmt || int_cmt || eret_cmt)
	begin
		reg_wb_res <= 32'd0;
	end
	else if (wb_allowin && mem_to_wb_valid)
	begin
		reg_wb_res <= mem_rf_res;	
	end
end*/


/*
always@(posedge clk)
begin
	if(!resetn)
	begin
		reg_wb_rf_wen <= 4'd0;
		reg_wb_rf_waddr <= 5'd0;		
 //      	reg_wb_regdata <= 6'd0;
        reg_wb_rf_wdata <= 32'd0;
	end
	else if (excep_cmt || int_cmt || eret_cmt)
	begin
		reg_wb_rf_wen <= 4'd0;
		reg_wb_rf_waddr <= 5'd0;		
 //       reg_wb_regdata <= 6'd0;
         reg_wb_rf_wdata <= 32'd0;
	end
	else if (wb_allowin && mem_to_wb_valid)
	begin
		reg_wb_rf_wen <= mem_rf_wen;
		reg_wb_rf_waddr <= mem_rf_waddr;
//		reg_wb_regdata <= mem_regdata;	
        reg_wb_rf_wdata <= mem_rf_wdata;
	end
end*/

/*
assign hi_wen = (mem_op_HIwen != 2'd0);
assign lo_wen = (mem_op_LOwen != 2'd0);

reg [31:0] reg_hi_in,reg_lo_in;
assign hi_in = reg_hi_in;
assign lo_in = reg_lo_in;

always@(posedge clk)
begin
	if(!resetn)
	begin
		reg_hi_in <= 32'd0;
		reg_lo_in <= 32'd0;		
	end
	else if (excep_cmt || int_cmt || eret_cmt)
	begin
		reg_hi_in <= 32'd0;
		reg_lo_in <= 32'd0;		

	end
	else if (wb_allowin && mem_to_wb_valid)
	begin
		reg_hi_in <= mem_hi_res;
		reg_lo_in <= mem_lo_res;	
	
	end
end*/

endmodule
