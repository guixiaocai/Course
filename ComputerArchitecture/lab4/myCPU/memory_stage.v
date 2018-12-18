module memory_stage(
	input         clk,
    input         resetn,

    input  [31:0] ex_pc,
    input  [31:0] ex_inst,
	input  [31:0] ex_rf_rdata1,
    input  [31:0] ex_rf_rdata2,
    input  [31:0] ex_rf_res,
    //  input ex_alu_overflow,

    input  [ 3:0] ex_op_RegWen,
    input  [ 4:0] ex_rf_waddr,
    input  [ 5:0] ex_op_RegWrite,
    input  [31:0] ex_hi_res,
    input  [31:0] ex_lo_res,
    input  [ 2:0] ex_op_StByt,
    input  [ 2:0] ex_op_LdByt,
	input  [ 1:0] ex_op_mul,
	input  [ 1:0] ex_op_div,
    input  [ 1:0] ex_op_HIWen,
    input  [ 1:0] ex_op_LOWen,
    input         wb_allowin,
	input  [31:0] div_res_q,
	input  [31:0] div_res_r,
	input  [63:0] ex_mul_res,

//中断、例外 
    input         excep_cmt,
    input         int_cmt,
    input         eret_cmt,

    input  [31:0] ex_hi_out,
    input  [31:0] ex_lo_out,
    //input  [31:0] cp0_read,

    input         ex_to_mem_valid,
	input         wb_valid,
    output        mem_allowin,
    output        mem_valid,
    output        mem_to_wb_valid,

    output [31:0] mem_pc,
    output [31:0] mem_inst,
    output [31:0] mem_rf_wdata,
	output [ 1:0] mem_op_mul,
	output [ 1:0] mem_op_div,
    output [ 1:0] mem_op_HIWen,
    output [ 1:0] mem_op_LOWen,
	output [31:0] mem_div_res_q,
	output [31:0] mem_div_res_r,
	output [63:0] mem_mul_res,
    output [31:0] mem_hi_res,
    output [31:0] mem_lo_res,
	output [ 3:0] mem_rf_wen,
	output [ 4:0] mem_rf_waddr,
	output [ 1:0] mem_inst_mt,
	output [31:0] hi_in,
    output [31:0] lo_in,

//data_sram
    output        data_sram_en,
	output [ 3:0] data_sram_wen,
	output [31:0] data_sram_addr,
	output [31:0] data_sram_wdata,	
	input  [31:0] data_sram_rdata
);
	reg  reg_mem_valid;
	wire mem_ready_go;

	assign mem_valid       = reg_mem_valid;
	assign mem_allowin     = !mem_valid || mem_ready_go && wb_allowin;
	assign mem_ready_go    = !(reg_mem_op_RegWrite[4] && wb_valid);
	assign mem_to_wb_valid = mem_valid && mem_ready_go;

	always@(posedge clk)
	begin
		if(!resetn)
		begin
			reg_mem_valid <= 1'b0;
		end
		else if (mem_allowin)
		begin
			reg_mem_valid <= ex_to_mem_valid;
		end
	end

	reg [31:0] reg_mem_pc;
	reg [31:0] reg_mem_res;
	reg [31:0] reg_mem_inst;
	reg [ 3:0] reg_mem_rf_wen;
	reg [ 4:0] reg_mem_rf_waddr;
	reg [ 5:0] reg_mem_op_RegWrite;
	reg [ 1:0] reg_mem_op_mul;
	reg [ 1:0] reg_mem_op_div;
	reg [ 1:0] reg_mem_op_HIWen;
	reg [ 1:0] reg_mem_op_LOWen;
	reg [31:0] reg_mem_hi_res;
	reg [31:0] reg_mem_lo_res;
	reg [31:0] reg_mem_hi_out;
	reg [31:0] reg_mem_lo_out;
	reg [ 2:0] reg_mem_op_LdByt;
	reg [ 2:0] reg_mem_op_StByt;
	reg [31:0] reg_mem_rf_rdata1;
	reg [31:0] reg_mem_rf_rdata2;
	reg [31:0] reg_mem_div_res_q;
	reg [31:0] reg_mem_div_res_r;
	reg [63:0] reg_mem_mul_res;
	wire [31:0] mem_rf_res;

	always@(posedge clk)
	begin
		if(!resetn)	begin					
			reg_mem_pc <= 32'hbfc00000;
			reg_mem_inst <= 32'd0;
			reg_mem_rf_rdata1 <= 32'd0;
			reg_mem_rf_rdata2 <= 32'd0;
			reg_mem_rf_wen    <= 4'd0;
			reg_mem_op_LdByt  <= 3'd0;
			reg_mem_op_StByt  <= 3'd0;
			reg_mem_res       <= 32'd0;
			reg_mem_hi_res    <= 32'd0;
			reg_mem_lo_res     <= 32'd0;
			reg_mem_op_mul      <= 2'd0;
			reg_mem_op_div      <= 2'd0;
			reg_mem_rf_waddr  <= 5'd0;
			reg_mem_op_RegWrite <= 6'd0;
			reg_mem_hi_out      <= 32'd0;
			reg_mem_lo_out      <= 32'd0;
			reg_mem_div_res_q <= 32'd0;
			reg_mem_div_res_r <= 32'd0;
			reg_mem_mul_res <= 32'd0;
		end
		/*else if (excep_cmt || int_cmt || eret_cmt)	begin
			reg_mem_pc <= 32'hbfc00000;
			reg_mem_inst <= 32'd0;
		end*/
		if (ex_to_mem_valid && mem_allowin)	begin		
			reg_mem_pc          <= ex_pc;
			reg_mem_inst        <= ex_inst;
			reg_mem_op_LdByt    <= ex_op_LdByt;
			reg_mem_op_StByt    <= ex_op_StByt;
			reg_mem_res         <= ex_rf_res;
			reg_mem_rf_rdata1   <= ex_rf_rdata1;
			reg_mem_rf_rdata2   <= ex_rf_rdata2;
			reg_mem_rf_wen      <= ex_op_RegWen;
			reg_mem_rf_waddr    <= ex_rf_waddr;
			reg_mem_op_RegWrite <= ex_op_RegWrite;
			reg_mem_hi_res      <= ex_hi_res;
			reg_mem_lo_res      <= ex_lo_res;
			reg_mem_op_mul      <= ex_op_mul;
			reg_mem_op_div      <= ex_op_div;
			reg_mem_hi_out      <= ex_hi_out;
			reg_mem_lo_out      <= ex_lo_out;
			reg_mem_div_res_q   <= div_res_q;
			reg_mem_div_res_r   <= div_res_r;
			reg_mem_mul_res     <= ex_mul_res;
			reg_mem_op_HIWen    <= ex_op_HIWen;
			reg_mem_op_LOWen    <= ex_op_LOWen;
		end
	end

	//reg reg_mem_alu_overflow;
	assign mem_rf_res   = reg_mem_res;
	assign mem_pc       = reg_mem_pc;
	assign mem_inst     = reg_mem_inst;
	assign mem_hi_res   = reg_mem_hi_res;
	assign mem_lo_res   = reg_mem_lo_res;
	assign mem_rf_wen   = reg_mem_rf_wen;
	assign mem_rf_waddr = reg_mem_rf_waddr;
	assign mem_op_mul   = reg_mem_op_mul;
	assign mem_op_div   = reg_mem_op_div;
	assign mem_div_res_q = reg_mem_div_res_q;
	assign mem_div_res_r = reg_mem_div_res_r;
	assign mem_mul_res   = reg_mem_mul_res;
	assign mem_op_HIWen  = reg_mem_op_HIWen;
	assign mem_op_LOWen  = reg_mem_op_LOWen;
	//assign mem_rf_rdata1 = reg_mem_rf_rdata1;
	assign mem_inst_mt  = { (!mem_inst[31:26] && mem_inst[5:0]==6'b010001),
					    	(!mem_inst[31:26] && mem_inst[5:0]==6'b010011)};

	assign hi_in        = mem_inst_mt[1] ? reg_mem_rf_rdata1     :
                            mem_op_mul[0] ? mem_mul_res[63:32]:
                            mem_op_div[0] ? mem_div_res_r        :
                                                 reg_mem_rf_rdata1     ;//reg_mem_hi_res;
	assign lo_in        = mem_inst_mt[0] ? reg_mem_rf_rdata1     :
                            mem_op_mul[0] ? mem_mul_res[31: 0]:
                            mem_op_div[0] ? mem_div_res_q        :
                                                 reg_mem_rf_rdata1     ;//reg_mem_lo_res;
 
	wire [1:0] ea;
	assign ea = data_sram_addr[1:0];
	wire ea0 = ea==2'd0;
	wire ea1 = ea==2'd1;
	wire ea2 = ea==2'd2;
	wire ea3 = ea==2'd3;

	wire case_swl = reg_mem_op_StByt==3'd1;
	wire case_swr = reg_mem_op_StByt==3'd2;
	wire case_sb  = reg_mem_op_StByt==3'd3;
	wire case_sh  = reg_mem_op_StByt==3'd4;
	wire case_sw  = reg_mem_op_StByt==3'd5;

	wire [31:0] sb_data,sh_data,sw_data, swl_data, swr_data;

	assign sb_data = ({32{ea0}} & {24'd0,reg_mem_rf_rdata2[7:0]})
					|({32{ea1}} & {16'd0,reg_mem_rf_rdata2[7:0],8'd0})
					|({32{ea2}} & {8'd0,reg_mem_rf_rdata2[7:0],16'd0})
					|({32{ea3}} & {reg_mem_rf_rdata2[7:0],24'd0});

	assign sh_data = ({32{ea1|ea0}} & {16'd0,reg_mem_rf_rdata2[15:0]})
					|({32{ea2|ea3}} & {reg_mem_rf_rdata2[15:0],16'd0});

	assign sw_data = reg_mem_rf_rdata2;
	assign swl_data = ({32{ea0}} & {24'd0,reg_mem_rf_rdata2[31:24]})
			|({32{ea1}} & {16'd0,reg_mem_rf_rdata2[31:16]})
			|({32{ea2}} & {8'd0,reg_mem_rf_rdata2[31:8]})
			|({32{ea3}} & reg_mem_rf_rdata2);
	assign swr_data = ({32{ea0}} & reg_mem_rf_rdata2)
			|({32{ea1}} & {reg_mem_rf_rdata2[23:0],8'd0})
			|({32{ea2}} & {reg_mem_rf_rdata2[15:0],16'd0})
			|({32{ea3}} & {reg_mem_rf_rdata2[7:0],24'd0});

	assign data_sram_wdata = ({32{case_sb }} & sb_data)
							|({32{case_sh }} & sh_data)
							|({32{case_sw }} & sw_data)
							|({32{case_swl}} & swl_data)
							|({32{case_swr}} & swr_data);

	wire [3:0] sb_wen,sh_wen,sw_wen,swl_wen,swr_wen;
	assign sb_wen = {ea3,ea2,ea1,ea0};
	assign sh_wen = {{2{ea2|ea3}},{2{ea1|ea0}}};
	assign sw_wen = 4'd15;
	assign swl_wen = {ea3,(ea3|ea2),!ea0,1'd1};
	assign swr_wen = {1'd1,!ea3,(ea1|ea0),ea0};

	assign data_sram_wen = ({4{case_sb }} & sb_wen)
							|({4{case_sh }} & sh_wen)
							|({4{case_sw }} & sw_wen)
							|({4{case_swl}} & swl_wen)
							|({4{case_swr}} & swr_wen);

	reg [31:0] data_rdata;

	always @ (*) begin
			case (reg_mem_op_LdByt)
			//lwl
			3'd1: data_rdata = ea==2'd0 ? {data_sram_rdata[ 7: 0], reg_mem_rf_rdata2[23: 0]}:
									ea==2'd1 ? {data_sram_rdata[15: 0], reg_mem_rf_rdata2[15: 0]}:
									ea==2'd2 ? {data_sram_rdata[23: 0], reg_mem_rf_rdata2[ 7: 0]}:
												data_sram_rdata                                       ;
			//lwr
			3'd2:  data_rdata = ea==2'd0 ? data_sram_rdata                                       :
									ea==2'd1 ? {reg_mem_rf_rdata2[31:24], data_sram_rdata[31: 8]}:
									ea==2'd2 ? {reg_mem_rf_rdata2[31:16], data_sram_rdata[31:16]}:
												{reg_mem_rf_rdata2[31: 8], data_sram_rdata[31:24]};
			//lb
			3'd3: data_rdata = ea==2'd0 ? {{24{data_sram_rdata[ 7]}},data_sram_rdata[ 7: 0]}:
									ea==2'd1 ? {{24{data_sram_rdata[15]}},data_sram_rdata[15: 8]}:
									ea==2'd2 ? {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}:
												{{24{data_sram_rdata[31]}},data_sram_rdata[31:24]};
			//lbu
			3'd4: data_rdata = ea==2'd0 ? {{24{1'b0}},data_sram_rdata[ 7: 0]}:
									ea==2'd1 ? {{24{1'b0}},data_sram_rdata[15: 8]}:
									ea==2'd2 ? {{24{1'b0}},data_sram_rdata[23:16]}:
												{{24{1'b0}},data_sram_rdata[31:24]};
			//lh
			3'd5: data_rdata = ea[1] ? {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}:
												{{16{data_sram_rdata[15]}},data_sram_rdata[15: 0]};
			//lhu
			3'd6: data_rdata = ea[1] ? {{16{1'b0}},data_sram_rdata[31:16]}:
												{{16{1'b0}},data_sram_rdata[15: 0]};
			default: data_rdata = data_sram_rdata;
			endcase
		end

	assign mem_rf_wdata = //reg_mem_op_RegWrite[5] ? mem_rf_res :
						reg_mem_op_RegWrite[4] ? data_rdata :
						reg_mem_op_RegWrite[3] ? mem_pc + 8 :
						reg_mem_op_RegWrite[2] ? reg_mem_hi_out :
						reg_mem_op_RegWrite[1] ? reg_mem_lo_out :
						//reg_mem_op_RegWrite[0] ? cp0_read :
												 mem_rf_res;

	//state MEM I/O ports
	assign data_sram_addr = mem_rf_res;
	assign data_sram_en = mem_valid;


endmodule