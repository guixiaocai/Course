module cpu_core(
	input  	      resetn,
	input         clk,

	//hardware interruput
	input  [ 5:0] hard_int,
	//Instruction channel
	output 		  inst_req,
	output 		  inst_wr,
	output [1 :0] inst_size,
	output [31:0] inst_addr,
	output [31:0] inst_wdata,	
	input  	      inst_addr_ok,
	input         inst_data_ok,
	input  [31:0] inst_rdata,
	
	//Data channel
	output 		  data_req,
	output 	      data_wr,
	output [1 :0] data_size,
	output [31:0] data_addr,
	output [31:0] data_wdata,
	output [3 :0] data_wstrb,	
	input 	      data_addr_ok,
	input 	      data_data_ok,
	input  [31:0] data_rdata,
		
	//debug signals
	output [31:0] debug_wb_pc,
	output [3 :0] debug_wb_rf_wen,
	output [4 :0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata

);

	wire [3:0] PCDst;
	wire [2:0] ALUSrc;
	wire [1:0] ALUsa;
	wire [1:0] RegWrite;
	wire [2:0] RegDst;
	wire [5:0] RegData;
	wire [1:0] mult_signal,div_signal;
	wire [2:0] hi_en,lo_en;
	wire [1:0] id_src_csdr,ex_src_csdr,mem_dst_csdr;
	wire [11:0] ALUop_in,ALUop_out;
	wire [31:0] Result;
	wire        Overflow, CarryOut;
	wire        Memread,Memwrite;
	wire [ 1:0] datasize;
	wire [31:0] Rf_rdata1,Rf_rdata2;
	wire [63:0] mul_result;
	wire [31:0] div_s,div_r;
	wire        complete;
	wire [31:0] dataout;
	wire [31:0] datain;

	//for cp0
	wire [31:0] mtc0_value;
	wire [31:0] mfc0_value;
	wire        excep_cmt,int_cmt,eret_cmt;

	//hazard control unit
	wire id_ex_rs_cflc,id_ex_rt_cflc;
	wire id_mem_rs_cflc,id_mem_rt_cflc;
	wire id_wb_rs_cflc,id_wb_rt_cflc;
	wire ex_mem_rs_cflc,ex_mem_rt_cflc;
	wire ex_wb_rs_cflc,ex_wb_rt_cflc;
	wire mem_wb_rt_cflc;

	assign id_ex_rs_cflc  = (id_rs == ex_rf_waddr ) && (id_rs != 5'd0);
	assign id_ex_rt_cflc  = (id_rt == ex_rf_waddr ) && (id_rt != 5'd0);
	assign id_mem_rs_cflc = (id_rs == mem_rf_waddr) && (id_rs != 5'd0);
	assign id_mem_rt_cflc = (id_rt == mem_rf_waddr) && (id_rt != 5'd0);
	assign id_wb_rs_cflc  = (id_rs == wb_rf_waddr ) && (id_rs != 5'd0) ;
	assign id_wb_rt_cflc  = (id_rt == wb_rf_waddr ) && (id_rt != 5'd0);

	assign ex_mem_rs_cflc = (ex_rs == mem_rf_waddr) && (ex_rs != 5'd0);
	assign ex_mem_rt_cflc = (ex_rt == mem_rf_waddr) && (ex_rt != 5'd0);
	assign ex_wb_rs_cflc  = (ex_rs == wb_rf_waddr ) && (ex_rs != 5'd0);
	assign ex_wb_rt_cflc  = (ex_rt == wb_rf_waddr ) && (ex_rt != 5'd0) ;
	assign mem_wb_rt_cflc = (mem_rt == wb_rf_waddr) && (mem_rt != 5'd0);


	wire [1:0] id_src_cflc;
	assign id_src_cflc = id_src_csdr;

	wire hazard_all, hazard_ex, hazard_mem;

	assign hazard_all = hazard_ex || hazard_mem;
	assign hazard_ex =(id_ex_rs_cflc && id_src_cflc[1] && ex_valid && id_valid) || 
					(id_ex_rt_cflc && id_src_cflc[0] && ex_valid && id_valid);
	assign hazard_mem =((id_mem_rs_cflc && id_src_cflc[1] && id_valid) ||
						(id_mem_rt_cflc && id_src_cflc[0] && id_valid) ||
						(ex_mem_rs_cflc && ex_src_cflc[1] && ex_valid) ||
						(ex_mem_rt_cflc && ex_src_cflc[0] && ex_valid))&&
						(mem_dst_cflc[1] ||mem_dst_cflc[0]) && mem_valid  ;


	wire reflush = (excep_cmt || int_cmt || eret_cmt) ;//&& id_readygo 
	reg  id_current_reflush;

	always@(posedge clk)
	begin
		id_current_reflush <= reflush; 
	end

	// these are for situation that id_stage stalls but if_stage inst_req has been responsed.
	// when this happens, if state should not require read tasks,and a special reg for inst is needed.
	// the priority is addr_ok > next_state_allowin
	reg if_inst_accepted,id_inst_accepted,id_inst_arrived;
	reg [31:0] wait_inst;
	always @(posedge clk)
	begin
		if(!resetn)
			if_inst_accepted <= 1'd0;
		else if (reflush)
			if_inst_accepted <= 1'd0;
		else if(id_allowin)
			if_inst_accepted <= 1'd0;
		else if (inst_addr_ok && !id_allowin )//
			if_inst_accepted <= 1'd1;

		if(!resetn)
			id_inst_accepted <= 1'd0;
		else if (reflush)
			id_inst_accepted <= 1'd0;
		else if(inst_data_ok)
			id_inst_accepted <= 1'd0;
		else if (inst_addr_ok && id_allowin )//
			id_inst_accepted <= 1'd1;

		if(!resetn)
			id_inst_arrived <= 1'd0;
		else if (reflush)
			id_inst_arrived <= 1'd0;
		else if (ex_allowin)
			id_inst_arrived <= 1'd0;
		else if (inst_data_ok && !ex_allowin)
			id_inst_arrived <= 1'd1;
	end

	reg mem_data_accepted, wb_data_accepted,wb_data_arrived;
	reg [31:0] wait_data;

	always @(posedge clk)
	begin
		if(!resetn)
			mem_data_accepted <= 1'd0;
		else if (reflush)
			mem_data_accepted <= 1'd0;
		else if(wb_allowin)
			mem_data_accepted<= 1'd0;
		else if (data_addr_ok && !wb_allowin)// 
			mem_data_accepted<= 1'd1;

		if(!resetn)
			wb_data_accepted <= 1'd0;
		else if (reflush)
			wb_data_accepted <= 1'd0;
		else if(data_data_ok)
			wb_data_accepted<= 1'd0;
		else if(data_addr_ok && wb_allowin)// 
			wb_data_accepted<= 1'd1;

		if(!resetn)
			wb_data_arrived <= 1'd0;
		else if (reflush)
			wb_data_arrived <= 1'd0;
		else if (reg_allowin)
			wb_data_arrived <= 1'd0;
		else if (!reg_allowin && data_data_ok)
			wb_data_arrived <= 1'd1;
	end

	//state 1 IF control signals
	reg  if_valid      ;	// value = 0 means this state is empty
	wire if_allowin    ;
	wire if_readygo    ;
	wire if_to_id_valid;
	wire validin       ;

	assign validin        = 1'd1;
	assign if_readygo     = (inst_req && inst_addr_ok) || if_inst_accepted;
	assign if_allowin     = !if_valid || if_readygo&&id_allowin;
	assign if_to_id_valid = if_valid && if_readygo;

	reg [31:0] if_start_pc;
	wire       if_inst_ade;
	assign if_inst_ade= (if_start_pc[1:0] != 2'd0);
	//state IF I/O ports
	assign inst_req = (!resetn) ? 1'd0 : 
					(reflush) ? 1'd0 : 
					!(if_inst_accepted || id_inst_accepted || id_inst_arrived) && if_valid;

	assign inst_wr    = 1'd0;
	assign inst_size  = 2'd2;
	assign inst_addr  = if_start_pc;
	assign inst_wdata = 32'd0;

	always@(posedge clk)
	begin
		if(!resetn)
			if_valid <= 1'd1;
		else if (if_allowin && validin)
			if_valid <= validin;
	end

	always@(posedge clk)
	begin
		if(!resetn)
			if_start_pc <= 32'hbfc00000;
		else if (excep_cmt || int_cmt)
			if_start_pc <= 32'hbfc00380;
		else if (eret_cmt)
			if_start_pc <= mfc0_value;
		else if(validin && if_allowin)
			if_start_pc <= next_pc;
	end

	reg[31:0] if_inst;
	always@(posedge clk)
	begin
		if(!resetn)
			if_inst <= 32'd0;
		else if (reflush)
			if_inst <= 32'd0;
		else if (validin && if_allowin && inst_data_ok)
			if_inst <= inst_rdata;
	end

	//state 2 ID control signals
	reg id_valid       ;// value = 0 means this state is empty
	wire id_allowin    ;
	wire id_readygo    ;
	wire id_to_ex_valid;

	assign id_readygo     = (!resetn)                ? 1'd0 :
							(hazard_ex ||hazard_mem) ? 1'd0 :
							inst_data_ok || id_inst_arrived;
	assign id_allowin     = !id_valid || id_readygo&&ex_allowin;
	assign id_to_ex_valid = id_valid && id_readygo;

	//IF-ID registers
	reg  [31:0] id_pc;
	reg  [31:0] id_inst;
	wire [5:0] id_opcode;
	wire [4:0] id_rs, id_rd, id_rt;
	assign id_opcode = Instruction[31:26];
	assign id_rs     = Instruction[25:21];
	assign id_rt     = Instruction[20:16];
	assign id_rd     = Instruction[15:11];

	//state ID I/O ports
	wire       id_delay_slot;
	reg [31:0] delay_slot_pc;
	reg        id_inst_ade;
	wire       id_rsv_cmt;	// link to decoder.reserve_inst

	assign id_delay_slot = (!resetn) ? 1'd0 :(id_pc == delay_slot_pc);

	always@(posedge clk)
	begin
		if(!resetn)
			id_inst_ade <= 1'd0;
		else if (reflush)
			id_inst_ade <= 1'd0;
		else if (id_allowin && if_to_id_valid)
			id_inst_ade <= if_inst_ade;
	end

	always@(posedge clk)
	begin
		if (PCDst != 4'd0 && (id_inst_arrived || inst_data_ok))//id_valid
			delay_slot_pc <= id_pc + 4;
	end

	wire [31:0] Instruction;
	wire [ 4:0] Rf_raddr1, Rf_raddr2;
	wire [31:0] nextsrc1, nextsrc2;

	assign Instruction = (id_inst_accepted && inst_data_ok) ? inst_rdata :id_inst; 
	assign Rf_raddr1   = id_rs;
	assign Rf_raddr2   = id_rt;
	assign nextsrc1    = (id_mem_rs_cflc && !mem_dst_cflc) ? mem_fwd  : 
						(id_wb_rs_cflc                  ) ? wb_fwd   :
															Rf_rdata1;
	assign nextsrc2 = (id_mem_rt_cflc && !mem_dst_cflc) ? mem_fwd  : 
					(id_wb_rt_cflc                  ) ? wb_fwd   :
														Rf_rdata2;
	//NEXT PC ADDER
	wire [31:0] next_pc;
	wire [31:0] branch_A,branch_B;
	wire [31:0] branch_result;
	wire        next_zero;
	wire [31:0] offset;
	assign branch_A      = nextsrc1;
	assign branch_B      = ~nextsrc2;
	assign branch_result = branch_A + branch_B + 1;
	assign next_zero     = (branch_result == 32'd0);
	assign offset        = {{16{Instruction[15]}},Instruction[15:0]};
		
	assign next_pc = PCDst[0]                                                                ? {if_start_pc[31:28],Instruction[25:0],2'b00}:
					PCDst[1]                                                                ? nextsrc1: 
					PCDst[2]&id_opcode[0]^((id_opcode[1]&nextsrc1[31])|next_zero)) == 1'b1 ? if_start_pc + (offset << 2):
					PCDst[3]&(id_rt[0]^nextsrc1[31])                                        ? if_start_pc + (offset << 2):
																							if_start_pc + 4;

	always@(posedge clk)
	begin
		if(!resetn)
			id_valid <= 1'b0;
		else if(id_allowin)
			id_valid <= if_to_id_valid;
	end

	always@(posedge clk)
	begin
		if(!resetn) 
			id_pc <= 32'hbfc00000;
		else if (reflush)
			id_pc <= 32'hbfc00000;
		else if (id_allowin && if_to_id_valid)
			id_pc <= if_start_pc;
	end

	always@(posedge clk)
	begin	
		if(!resetn)
			id_inst <= 32'd0;
		else if (reflush)
			id_inst <= 32'd0;
		else if (id_inst_accepted && inst_data_ok)
			id_inst <= inst_rdata;
	end

	//state 3 EX control signals
	reg  ex_valid       ;// value = 0 means this state is empty
	wire ex_allowin     ;
	wire ex_readygo     ;
	wire ex_to_mem_valid;

	assign ex_readygo      = ex_div_signal[1] ? complete : !hazard_mem;
	assign ex_allowin      = (!ex_valid || ex_readygo&&mem_allowin);
	assign ex_to_mem_valid = ex_valid && ex_readygo;

	//ID-EX registers
	reg [31:0] ex_pc;
	reg [31:0] ex_inst;
	reg [12:0] ex_aluop;
	reg [ 2:0] ex_alusrc;
	reg [ 1:0] ex_alusa;
	reg [31:0] ex_operate1, ex_operate2;
	reg [ 1:0] ex_mul_signal, ex_div_signal;
	reg        ex_memread,ex_memwrite;
	reg [ 1:0] ex_regwrite;
	reg [ 4:0] ex_rf_waddr;
	reg [ 5:0] ex_regdata;
	reg [ 2:0] ex_hi_en,ex_lo_en;
	reg [ 1:0] ex_src_cflc;
	reg        ex_mem_src_csdr;
	wire [4:0] ex_rs, ex_rd, ex_rt;

	assign ex_rs = ex_inst[25:21];
	assign ex_rt = ex_inst[20:16];
	assign ex_rd = ex_inst[15:11];

	//state EX I/O ports
	wire [31:0] sign_extend,zero_extend;
	wire [31:0] normal_alusrc2;
	wire [31:0] ex_alusrc1,ex_alusrc2;
	wire [31:0] ALUdata1, ALUdata2;
	wire [ 4:0] shamt;
	wire [31:0] mul_x,mul_y;
	wire [31:0] div_x,div_y;
	wire [31:0] ex_divsrc1,ex_divsrc2;
	wire [31:0] ex_mulsrc1,ex_mulsrc2;
	wire        start_div;

	assign start_div = (ex_wb_rs_cflc || ex_wb_rt_cflc) && wb_state_ld ? ex_div_signal[1] && wb_to_reg_valid :ex_div_signal[1];

	reg [1:0] ex_mem_dst_csdr;
	reg       ex_delay_slot;
	reg       ex_inst_ade;
	reg       ex_rsv_cmt;

	always@(posedge clk)
	begin
		if(!resetn)
		begin
			ex_delay_slot <= 1'd0;
			ex_inst_ade   <= 1'd0;
			ex_rsv_cmt    <= 1'd0;
		end
		else if (reflush)
		begin
			ex_delay_slot <= 1'd0;
			ex_inst_ade   <= 1'd0;
			ex_rsv_cmt    <= 1'd0;
		end
		else if (ex_allowin && id_to_ex_valid)
		begin
			ex_delay_slot <= id_delay_slot;
			ex_inst_ade   <= id_inst_ade;
			ex_rsv_cmt    <= id_rsv_cmt;
		end
	end

	assign sign_extend = {{16{ex_inst[15]}},ex_inst[15:0]};
	assign zero_extend = {16'd0,ex_inst[15:0]};
	assign normal_alusrc2 = ({32{ex_alusrc[0]}} & zero_extend) |
							({32{ex_alusrc[1]}} & sign_extend) |
							({32{ex_alusrc[2]}} & ex_operate2) ;

	assign ex_alusrc1 = (ex_mem_rs_cflc && (mem_dst_cflc == 2'd0)) ? mem_fwd    :		  			 
						(ex_wb_rs_cflc							 ) ? wb_fwd     :
																	ex_operate1;
	assign ex_alusrc2= (ex_mem_rt_cflc &&(mem_dst_cflc == 2'd0)&& ex_alusrc[2]) ? mem_fwd       :		  			 
					(ex_wb_rt_cflc&& ex_alusrc[2]                          ) ? wb_fwd        :
																				normal_alusrc2;
	assign ex_divsrc1 =  (ex_mem_rs_cflc &&(mem_dst_cflc == 2'd0)) ? mem_fwd    :		  			 
						(ex_wb_rs_cflc                          ) ? wb_fwd     :
																	ex_operate1;
	assign ex_divsrc2 = (ex_mem_rt_cflc &&(mem_dst_cflc == 2'd0)&& ex_div_signal[1]) ?  mem_fwd    :		  			 
						(ex_wb_rt_cflc&& ex_div_signal[1]                          ) ?  wb_fwd     :
																						ex_operate2;
	assign ex_mulsrc1 =  (ex_mem_rs_cflc &&(mem_dst_cflc == 2'd0)) ? mem_fwd    :		  			 
						(ex_wb_rs_cflc                         ) ? wb_fwd     :
																	ex_operate1;    
	assign ex_mulsrc2 = (ex_mem_rt_cflc && (mem_dst_cflc == 2'd0)&& ex_mul_signal[1]) ? mem_fwd    :		  			 
						(ex_wb_rt_cflc&& ex_mul_signal[1]                          ) ? wb_fwd     :
																						ex_operate2; 
	assign ALUdata1 = ex_alusrc1;
	assign ALUdata2 = ex_alusrc2;
	assign shamt    = ({5{ex_alusa[0]}} & ex_operate1[4:0]) | ({5{ex_alusa[1]}} & ex_inst[10:6]);
	assign ALUop_in = ex_aluop;

	assign div_x = ex_divsrc1;
	assign div_y = ex_divsrc2;
	assign mul_x = ex_mulsrc1;
	assign mul_y = ex_mulsrc2;

	always@(posedge clk)
	begin
		if(!resetn)
			ex_valid <= 1'b0;
		else if (ex_allowin)
			ex_valid <= id_to_ex_valid;
	end

	always@(posedge clk)
	begin
		if(!resetn)
		begin		
			ex_pc   <= 32'hbfc00000;
			ex_inst <= 32'd0;
		end
		else if (reflush)
		begin
			ex_pc   <= 32'hbfc00000;
			ex_inst <= 32'd0;		
		end
		else if (ex_allowin && id_to_ex_valid)
		begin	
			ex_pc   <= id_pc;	
			ex_inst <= Instruction;
		end
	end

	always@(posedge clk)
	begin	
		if(!resetn || reflush)
		begin
			ex_aluop      <= 12'd0;	
			ex_alusrc     <= 3'd0;
			ex_alusa      <= 2'd0;	
			ex_operate1   <= 32'd0;
			ex_operate2   <= 32'd0;
			ex_mul_signal <= 2'd0;
			ex_div_signal <= 2'd0;
		end
		else if (ex_allowin && id_to_ex_valid)
		begin
			ex_aluop      <= ALUop_out;
			ex_alusrc     <= ALUSrc;
			ex_alusa      <= ALUsa;
			ex_operate1   <= nextsrc1;
			ex_operate2   <= nextsrc2;
			ex_mul_signal <= mult_signal;
			ex_div_signal <= div_signal;
		end
	end
		
	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			ex_memread  <= 1'b0;
			ex_memwrite <= 1'd0;
		end
		else if (ex_allowin && id_to_ex_valid)
		begin
			ex_memread  <= Memread;
			ex_memwrite <= Memwrite;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			ex_regwrite <= 2'd0;		
			ex_rf_waddr <= 5'd0;
			ex_regdata <= 6'd0;
			ex_hi_en <= 3'd0;
			ex_lo_en <= 3'd0;
		end
		else if (ex_allowin && id_to_ex_valid)
		begin
			ex_regwrite <= RegWrite;
			ex_rf_waddr <= ({5{RegDst[0]}} & 5'd31) |
						({5{RegDst[1]}} & id_rd) |
						({5{RegDst[2]}} & id_rt) ;
			ex_regdata <= RegData;
			ex_hi_en   <= hi_en;
			ex_lo_en   <= lo_en;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			ex_src_cflc     <= 2'd0;
			ex_mem_dst_csdr <= 2'd0;
		end
		else if (ex_allowin && id_to_ex_valid)
		begin
			ex_src_cflc     <= ex_src_csdr;
			ex_mem_dst_csdr <= mem_dst_csdr;
		end
	end

	//state 4 MEM control signals
	reg mem_valid       ;
	wire mem_allowin    ;
	wire mem_readygo    ;
	wire mem_to_wb_valid;

	assign mem_readygo     = (mem_state_ld || mem_state_st) ? (data_req && data_addr_ok || mem_data_accepted) : 1'd1;

	assign mem_allowin     = !mem_valid || mem_readygo&&wb_allowin;
	assign mem_to_wb_valid = mem_valid && mem_readygo;

	//EX-MEM registers
	reg [31:0] mem_inst;
	reg [31:0] mem_pc;
	reg [31:0] mem_operate1, mem_operate2;
	reg [31:0] mem_result;
	reg 	   mem_memread,mem_memwrite;
	reg        mem_rf_wen;
	reg [ 4:0] mem_rf_waddr;
	reg [ 5:0] mem_regdata;
	reg [ 2:0] mem_hi_en, mem_lo_en;
	reg [ 1:0] mem_dst_cflc;
	wire [5:0] mem_opcode;
	wire [1:0] mem_ea;
	wire [4:0] mem_rs, mem_rd, mem_rt;
	assign mem_opcode = mem_inst[31:26];
	assign mem_rs     = mem_inst[25:21];
	assign mem_rt     = mem_inst[20:16];
	assign mem_rd     = mem_inst[15:11];
	assign mem_ea     = mem_result[1:0];

	//mem_state_st == mem_src_cflc
	wire [31:0] send_data;
	assign send_data = (mem_wb_rt_cflc && mem_state_st) ? wb_fwd : mem_operate2;

	//wire mem_state_conflic;
	wire mem_state_ld,mem_state_st;

	assign mem_state_ld = mem_memread && !mem_memwrite;
	assign mem_state_st = mem_memread && mem_memwrite; 
	//assign mem_state_conflic = (!mem_regdata[5])&& (mem_regdata != 6'd0);

	assign mtc0_value = (mem_wb_rt_cflc) ? wb_fwd : mem_operate2;

	reg        mem_delay_slot;
	reg        mem_inst_ade;
	reg        mem_ov_cmt;
	reg        mem_rsv_cmt;
	wire       mem_ld_ade;
	wire       mem_st_ade; // link to st_ade from dataout_dealer
	wire [2:0] mem_ade_cmt;

	assign mem_ade_cmt = {mem_inst_ade,mem_ld_ade,mem_st_ade};

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			mem_delay_slot <= 1'd0;
			mem_inst_ade   <= 1'd0;
			mem_rsv_cmt    <= 1'd0;
		end
		else if (mem_allowin && ex_to_mem_valid)
		begin
			mem_delay_slot <= ex_delay_slot;
			mem_inst_ade   <= ex_inst_ade;
			mem_rsv_cmt    <= ex_rsv_cmt;
		end
	end

	wire [31:0] mem_fwd;
	assign mem_fwd = ({32{mem_regdata[0]}} & mfc0_value) 
				| ({32{mem_regdata[3]}} & (mem_pc + 8))
				| ({32{mem_regdata[5]}} & mem_result); 


	//state MEM I/O ports
	assign data_req = (!resetn                        ) ? 1'd0 :
					(excep_cmt || int_cmt ||eret_cmt) ? 1'd0 :
					(mem_state_ld                   ) ? !(mem_data_accepted || wb_data_accepted || wb_data_arrived) && mem_valid :
					(mem_state_st                   ) ? !mem_data_accepted && mem_valid : 1'd0;
	assign data_wr = (!resetn || reflush             ) ? 1'd0 : 
					(excep_cmt || int_cmt ||eret_cmt) ? 1'd0 :
					(mem_state_st                   ) ? !mem_data_accepted && mem_valid : 1'd0;

	always@(posedge clk)
	begin
		if(!resetn)
			mem_valid <= 1'b0;
		else if (mem_allowin)
			mem_valid <= ex_to_mem_valid;
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin					
			mem_pc   <= 32'hbfc00000;
			mem_inst <= 32'd0;
		end
		else if (ex_to_mem_valid && mem_allowin)
		begin		
			mem_pc   <= ex_pc;
			mem_inst <= ex_inst;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin					
			mem_operate1 <= 32'd0;
			mem_operate2 <= 32'd0;
		end
		else if (ex_to_mem_valid && mem_allowin)
		begin		
			mem_operate1 <= ex_operate1;
			mem_operate2 <= ex_operate2;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			mem_result <= 32'd0;
			mem_ov_cmt <= 1'd0;
		end
		else if (mem_allowin && ex_to_mem_valid)
		begin
			mem_result <= Result;
			mem_ov_cmt <= Overflow && ex_regwrite[1];
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin					
			mem_memread <= 1'd0;
			mem_memwrite <= 1'd0;
		end
		else if (ex_to_mem_valid && mem_allowin)
		begin		
			mem_memread <= ex_memread;
			mem_memwrite <= ex_memwrite;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin					
			mem_rf_wen   <= 1'b0;
			mem_rf_waddr <= 5'd0;
			mem_regdata  <= 6'd0;
			mem_hi_en    <= 3'd0;
			mem_lo_en    <= 3'd0;
		end
		else if (ex_to_mem_valid && mem_allowin)
		begin		
			mem_rf_wen   <= !(ex_regwrite[0] | (ex_regwrite[1] & Overflow));	
			mem_rf_waddr <= ex_rf_waddr;
			mem_regdata  <= ex_regdata;
			mem_hi_en    <= ex_hi_en;
			mem_lo_en    <= ex_lo_en;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn)
			mem_dst_cflc <= 2'd0;
		else if (ex_to_mem_valid && mem_allowin)
		begin		
			mem_dst_cflc <= ex_mem_dst_csdr;
		end
	end
	//state 5 WB control registers
	reg wb_valid        ;
	wire wb_readygo     ;
	wire wb_allowin     ;
	wire reg_allowin    ;
	wire wb_to_reg_valid;

	assign reg_allowin     = 1'd1;
	assign wb_readygo      = (!resetn) ? 1'd0 :
							(wb_data_arrived) ? 1'd1 : 
							(wb_memread && !wb_memwrite) ? data_data_ok : 1'd1;//??????????
	assign wb_allowin      = !wb_valid||wb_readygo&&reg_allowin;
	assign wb_to_reg_valid = wb_valid && wb_readygo;

	wire wb_state_ld = wb_memread && !wb_memwrite;
	//state WB I/O ports
	reg [31:0] wb_pc;
	reg [31:0] wb_inst;
	reg [31:0] wb_operate1,wb_operate2;
	reg [31:0] wb_result;
	reg [31:0] wb_rdata;
	reg        wb_memread,wb_memwrite;
	wire[31:0] receive_data;
	assign receive_data = (wb_data_accepted && data_data_ok) ? data_rdata : wb_rdata;

	reg wb_rf_wen;
	reg [4 :0] wb_rf_waddr;
	reg [5 :0] wb_regdata;
	reg [31:0] HI,LO;

	//CP0 registers  should place them here?
	assign debug_wb_pc = wb_pc;
	assign debug_wb_rf_wen = {4{wb_rf_wen & wb_to_reg_valid}};
	assign debug_wb_rf_wnum = wb_rf_waddr;
	assign debug_wb_rf_wdata = Rf_wdata;

	wire [5:0] wb_opcode;
	wire [4:0] wb_rs,wb_rd, wb_rt;

	assign wb_opcode = wb_inst[31:26];
	assign wb_rs     = wb_inst[25:21];
	assign wb_rt     = wb_inst[20:16];
	assign wb_rd     = wb_inst[15:11];

	wire [1:0] wb_ea;
	assign wb_ea = wb_result[1:0];

	reg [31:0] cp0_read;

	always@(posedge clk)
	begin
		if(!resetn)
			cp0_read <= 32'd0;
		else if (reflush)
			cp0_read <= 32'd0;
		else if (wb_allowin && mem_to_wb_valid)
			cp0_read <= mfc0_value;
	end

	wire        Rf_wen;
	wire [ 4:0] Rf_waddr;
	wire [31:0] Rf_wdata;

	wire [31:0] wb_fwd;
	assign wb_fwd = Rf_wdata;

	assign Rf_wen 	= wb_rf_wen;
	assign Rf_waddr = wb_rf_waddr;				                 
	assign Rf_wdata = ({32{wb_regdata[0]}} & cp0_read)
					| ({32{wb_regdata[1]}} & LO)
					| ({32{wb_regdata[2]}} & HI)
					| ({32{wb_regdata[3]}} & (wb_pc + 8))
					| ({32{wb_regdata[4]}} & datain)
					| ({32{wb_regdata[5]}} & wb_result); 
	assign wb_fwd   = Rf_wdata;

	always@(posedge clk)
	begin
		if(!resetn)
			wb_valid <= 1'b0;
		else if (wb_allowin)
			wb_valid <= mem_to_wb_valid;
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			wb_pc   <= 32'hbfc00000;
			wb_inst <= 32'd0;
		end
		else if (wb_allowin && mem_to_wb_valid)
		begin
			wb_pc   <= mem_pc;
			wb_inst <= mem_inst;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			wb_operate1 <= 32'd0;
			wb_operate2 <= 32'd0;
		end
		else if (wb_allowin && mem_to_wb_valid)
		begin
			wb_operate1 <= mem_operate1;
			wb_operate2 <= mem_operate2;
		end
	end

	always@(posedge clk)
	begin
		if(!resetn)
			wb_result <= 32'd0;
		else if (reflush)
			wb_result <= 32'd0;
		else if (wb_allowin && mem_to_wb_valid)
			wb_result <= mem_result;	
	end

	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin					
			wb_memread  <= 1'd0;
			wb_memwrite <= 1'd0;
		end
		else if (mem_to_wb_valid && wb_allowin)
		begin		
			wb_memread  <= mem_memread;  //&& data_addr_ok
			wb_memwrite <= mem_memwrite; // && data_addr_ok
		end
	end
	always@(posedge clk)
	begin
		if(!resetn)
			wb_rdata <= 32'd0;
		else if (reflush)
			wb_rdata <= 32'd0;
		else if (data_data_ok && wb_state_ld)
			wb_rdata <= data_rdata;
	end
	always@(posedge clk)
	begin
		if(!resetn || reflush)
		begin
			wb_rf_wen   <=1'd0;
			wb_rf_waddr <= 5'd0;		
			wb_regdata  <= 6'd0;
		end
		else if (wb_allowin && mem_to_wb_valid)
		begin
			wb_rf_wen   <= mem_rf_wen;
			wb_rf_waddr <= mem_rf_waddr;
			wb_regdata  <= mem_regdata;	
		end
	end

	always@(posedge clk)
	begin
		if (wb_allowin && mem_to_wb_valid)
		begin
				if(mem_hi_en[2])
				HI <= mul_result[63:32];
			else if (mem_hi_en[1])
				HI <= div_r;
			else if (mem_hi_en[0])
				HI <= mem_operate1;
			if(mem_lo_en[2])
				LO <= mul_result[31:0];
			else if (mem_lo_en[1])
				LO <= div_s;
			else if (mem_lo_en[0])
				LO <= mem_operate1;
		end
	end
	reg_file reg_file(
		.clk    (clk      ),
		.resetn (resetn   ),
		.waddr  (Rf_waddr ),
		.raddr1 (Rf_raddr1),
		.raddr2 (Rf_raddr2),
		.wen    (Rf_wen   ),
		.wdata  (Rf_wdata ),
		.rdata1 (Rf_rdata1),
		.rdata2 (Rf_rdata2)
	);

	alu alu(
		.A        (ALUdata1),
		.B        (ALUdata2),
		.sa       (shamt   ),
		.ALUop    (ALUop_in),
		.Overflow (Overflow),
		.CarryOut (CarryOut),
		.Result   (Result  )
	);

	decoder decoder(
		.Instruction  (Instruction ),	
		.PCDst        (PCDst       ),
		.ALUop        (ALUop_out   ),
		.ALUSrc       (ALUSrc      ),
		.ALUsa        (ALUsa       ),
		.mult_signal  (mult_signal ),
		.div_signal   (div_signal  ),
		.Memread      (Memread     ),
		.Memwrite     (Memwrite    ),
		.RegWrite     (RegWrite    ),
		.RegDst       (RegDst      ),	
		.RegData      (RegData     ),
		.hi_en        (hi_en       ),
		.lo_en        (lo_en       ),
		.rsv_cmt      (id_rsv_cmt  ),
		.id_src_csdr  (id_src_csdr ),
		.ex_src_csdr  (ex_src_csdr ),
		.mem_dst_csdr (mem_dst_csdr)
	);

	multiplier multiplier(
		.mul_clk    (clk             ),
		.resetn     (resetn          ),
		.mul_signed (ex_mul_signal[0]), 
		.x          (mul_x           ),
		.y          (mul_y           ),
		.mul_result (mul_result      )
	);

	divider divider(
		.div_clk    (clk             ),
		.resetn     (resetn          ),
		.div        (start_div       ),
		.div_signed (ex_div_signal[0]),
		.x          (div_x           ),
		.y          (div_y           ),
		.s          (div_s           ),
		.r          (div_r           ),
		.complete   (complete        )
	);

	dataout_dealer dataout_dealer(
		.opcode      (mem_opcode),
		.ea          (mem_ea    ),
		.regdata     (send_data ),
		.alu_result  (mem_result),
		.address     (data_addr ),
		.dataout     (data_wdata),
		.wt_strb     (data_wstrb),
		.datasize    (data_size ),
		.ld_ade      (mem_ld_ade),
		.st_ade      (mem_st_ade)
	);

	datain_dealer datain_dealer(
		.opcode   (wb_opcode   ),
		.ea       (wb_ea       ),
		.regdata  (wb_operate2 ),
		.loadin   (receive_data),
		.datain   (datain      )
	); 

	cp0_regs cp0_regs(
		.clk         (clk           ),
		.resetn      (resetn        ),
		.inst        (mem_inst      ),
		.pc          (mem_pc        ),
		.data_addr   (data_addr     ),
		.mtc0_value  (mtc0_value    ),
		.hard_int    (hard_int      ),
		.delay_slot  (mem_delay_slot),
		.ov_cmt      (mem_ov_cmt    ),
		.ade_cmt     (mem_ade_cmt   ),
		.rsv_cmt     (mem_rsv_cmt   ),
		.mfc0_value  (mfc0_value    ),
		.excep_cmt   (excep_cmt     ),
		.int_cmt     (int_cmt       ),
		.eret_cmt    (eret_cmt      )
	);
	
endmodule