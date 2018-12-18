`timescale 1ns / 1ps
module cp0_regs(
	/*global signal */
	input 	      clk,
	input         resetn,

	/*write channel*/
	input  [31:0] inst, 
	input  [31:0] pc,
	input  [31:0] data_addr,
	input  [31:0] mtc0_value,	 //from regfile = mtc0_value

	input  [ 5:0] hard_int, 
	input         delay_slot,
	input         ov_cmt, 		//assign to mem_overflow && of_csdr
	input  [ 2:0] ade_cmt, 		//{取指，读存，写存}
	input         rsv_cmt,

	/*read channel */
	output [31:0] mfc0_value,

	/*signals for reflush pipeline*/
	output        excep_cmt, 	//exception_commit
	output        int_cmt,
	output        eret_cmt
);

	wire [4:0] rs;
	wire [4:0] rt;
	wire [4:0] rd;
	wire [4:0] sa;
	wire [2:0] sel;
	wire [5:0] funcode;
	wire [5:0] opcode;

	assign rs      = inst[25:21];
	assign rt      = inst[20:16];
	assign rd      = inst[15:11];
	assign sa      = inst[10: 6];
	assign sel     = inst[ 2: 0];
	assign opcode  = inst[31:26];
	assign funcode = inst[ 5: 0];

	wire inst_mfc0;
	wire inst_mtc0;
	wire inst_eret;
	wire inst_syscall;
	wire inst_break;

	assign inst_mfc0    = (opcode == 6'd16) && (rs == 5'd0) && (sa == 5'd0) && (funcode[4:3] == 2'd0);
	assign inst_mtc0    = (opcode == 6'd16) && (rs == 5'd4) && (sa == 5'd0) && (funcode[4:3] == 2'd0);
	assign inst_eret    = (opcode == 6'd16) && (rs == 5'd16) && (rt == 5'd0) && (rd == 5'd0) && (sa == 5'd0) && (funcode == 6'd24);
	assign inst_syscall = (opcode == 6'd0) && (funcode == 6'd12);
	assign inst_break   =  (opcode == 6'd0) && (funcode == 6'd13);

	assign excep_cmt = exccode_adel||exccode_ades||exccode_ov||exccode_sys||exccode_bk||exccode_ri;
	assign int_cmt   = (!resetn) ? 1'd0 : (exccode_int && (status_exl == 1'd0));
	assign eret_cmt  = inst_eret;

	//time interrupt
	wire time_req;
	assign time_req = (count == compare) && status_im[7];

	//hard interrupt = input int && status_im[]
	wire hw5_req;
	wire hw4_req;
	wire hw3_req;
	wire hw2_req;
	wire hw1_req;
	wire hw0_req;
	assign hw5_req = hard_int[5] && status_im[7];
	assign hw4_req = hard_int[4] && status_im[6];
	assign hw3_req = hard_int[3] && status_im[5];
	assign hw2_req = hard_int[2] && status_im[4];
	assign hw1_req = hard_int[1] && status_im[3];
	assign hw0_req = hard_int[0] && status_im[2];

	//soft interrupt 
	wire sw1_req;
	wire sw0_req;
	assign sw1_req = cause_ip_soft[1] && status_im[1];
	assign sw0_req = cause_ip_soft[0] && status_im[0];

	wire hw_req;
	wire sw_req;
	wire int_req;
	assign hw_req  = hw5_req  || hw4_req|| hw3_req || hw2_req || hw1_req || hw0_req;
	assign sw_req  = sw1_req  || sw0_req;
	assign int_req = time_req || hw_req || sw_req;

	wire mfc0_epc,mfc0_cause,mfc0_status,mfc0_badvaddr,mfc0_count,mfc0_compare;
	wire mtc0_epc,mtc0_cause,mtc0_status,mtc0_badvaddr,mtc0_count,mtc0_compare;

	assign mfc0_epc = inst_mfc0 && (rd == 5'd14);
	assign mfc0_cause = inst_mfc0 && (rd == 5'd13);
	assign mfc0_status = inst_mfc0 && (rd == 5'd12);
	assign mfc0_badvaddr = inst_mfc0 && (rd == 5'd8);
	assign mfc0_count = inst_mfc0 && (rd == 5'd9);
	assign mfc0_compare = inst_mfc0 && (rd == 5'd11);

	assign mtc0_epc = inst_mtc0 && (rd == 5'd14);
	assign mtc0_cause = inst_mtc0 && (rd == 5'd13);
	assign mtc0_status = inst_mtc0 && (rd == 5'd12);
	assign mtc0_badvaddr = inst_mtc0 && (rd == 5'd8);
	assign mtc0_count = inst_mtc0 && (rd == 5'd9);
	assign mtc0_compare = inst_mtc0 && (rd == 5'd11);

	wire exccode_int;
	wire exccode_adel;
	wire exccode_ades;
	wire exccode_ov;
	wire exccode_sys;
	wire exccode_bk;
	wire exccode_ri;
	assign exccode_int = int_req && status_ie;
	assign exccode_sys = inst_syscall;
	assign exccode_bk = inst_break;
	assign exccode_ov = ov_cmt;
	assign exccode_adel = ade_cmt[2] || ade_cmt[1];
	assign exccode_ades = ade_cmt[0];
	assign exccode_ri = rsv_cmt;

	wire [31:0] cp0_epc;
	wire [31:0] cp0_status;
	wire [31:0] cp0_cause;
	wire [31:0] cp0_badvaddr;
	wire [31:0] cp0_count;
	wire [31:0] cp0_compare;

	/* cp0_status */
	wire      status_bev;
	reg [7:0] status_im;
	reg       status_exl;
	reg       status_ie;

	assign cp0_status = { 
							9'd0      , //31-23
							status_bev,	//22
							6'd0      , //21-16
							status_im ,	//15-8
							6'd0      ,	//7-2
							status_exl,	//1
							status_ie	//0
						};

	assign status_bev = 1'd1;

	always@(posedge clk)
	begin
		if(!resetn)
			status_im <= 8'd0;
		else if (mtc0_status)
			status_im <= mtc0_value[15:8];
	end

	always@(posedge clk)
	begin
		if(!resetn)
			status_exl <= 1'd0;
		else if(mtc0_status)
			status_exl <= mtc0_value[1];
		else if (excep_cmt || int_cmt)
			status_exl <= 1'd1;
		else if (eret_cmt)
			status_exl <= 1'd0;
	end

	always@(posedge clk)
	begin
		if(!resetn)
			status_ie <= 1'd0;
		else if (mtc0_status)
			status_ie <= mtc0_value[0];
	end

	/*cp0_cause */
	reg       cause_bd;
	reg       cause_ti;
	reg [5:0] cause_ip_hard;
	reg [1:0] cause_ip_soft;
	reg [4:0] cause_exccode;

	assign cp0_cause = { 
							cause_bd     ,	//31
							cause_ti     ,	//30
							14'd0        ,	//29-16		
							cause_ip_hard,  //15-10
							cause_ip_soft,  //9-8
							1'd0         ,	//7
							cause_exccode,  //6-2
							2'd0			//1-0
						};

	always@(posedge clk)
	begin
		if(!resetn)
			cause_bd <= 1'd0;
		else if ((excep_cmt || int_cmt) && (status_exl == 1'd0))
			cause_bd <= delay_slot;
	end

	always@(posedge clk)
	begin
		if(!resetn)
			cause_ti <= 1'd0;
		else if (count == compare) //???????
			cause_ti <= 1'd1;
		else if (mtc0_compare)
			cause_ti <= 1'd0;
	end

	always@(posedge clk)
	begin
		if(!resetn)
			cause_ip_hard <= 6'd0;
		else if (count == compare)
			cause_ip_hard[5] <= 1'd1;
		else if (mtc0_compare)
			cause_ip_hard[5] <= 1'd0;
	end

	always@(posedge clk)
	begin
		if(!resetn)
			cause_ip_soft <= 2'd0;
		else if (mtc0_cause)
			cause_ip_soft <= mtc0_value[9:8];
	end

	always@(posedge clk)
	begin
		if(!resetn)//no need
			cause_exccode <= 5'h0f;
		else if (exccode_int)
			cause_exccode <= 5'h00;
		else if (ade_cmt[2])
			cause_exccode <= 5'h04;
		else if (exccode_ri)
			cause_exccode <= 5'h0a;
		else if (exccode_ov)
			cause_exccode <= 5'h0c;
		else if (exccode_bk)
			cause_exccode <= 5'h09;
		else if (exccode_sys)
			cause_exccode <= 5'h08;
		else if (ade_cmt[1])
			cause_exccode <= 5'h04;
		else if (ade_cmt[0])
			cause_exccode <= 5'h05;
	end

	/* cp0_epc */
	reg [31:0] epc;
	assign cp0_epc = epc;

	always@(posedge clk)
	begin
		if(!resetn)//no need
			epc <= 32'd0;
		else if (mtc0_epc)
			epc <= mtc0_value;
		else if (excep_cmt && (status_exl == 1'd0))
			epc <= (delay_slot) ? pc-4 : pc;
		else if (int_cmt && (status_exl == 1'd0)) //??????
		begin
			epc <= (mtc0_count||mtc0_compare || mtc0_cause) ? pc+4 :
				   (delay_slot)                             ? pc-4 : pc;
		end

	end

	reg [31:0] count;
	reg 	   count_step;
	assign cp0_count = count;
	always@(posedge clk)
	begin
		if(!resetn)
			count_step <= 1'd0;
		else if(mtc0_compare)
			count_step <= 1'd0;
		else
			count_step <= !count_step;
	end
	always@(posedge clk)
	begin
		if(!resetn) //no need
			count <= 32'd0;
		else if (mtc0_count)
			count <= mtc0_value;
		else
			count <= count + count_step;
	end

	reg [31:0] compare;
	assign cp0_compare = compare;
	always@(posedge clk)
	begin
		if(!resetn)//no need
			compare <= 32'hffff;
		else if (mtc0_compare)
			compare <= mtc0_value;
	end

	reg [31:0] badvaddr;
	assign cp0_badvaddr = badvaddr;
	always@(posedge clk)
	begin
		if(!resetn)//no need
			badvaddr <= 32'd0;
		//adel and ades shoult be deeper considered
		else if (ade_cmt[2])
			badvaddr <= pc;
		else if (ade_cmt[1] || ade_cmt[0])
			badvaddr <= data_addr;
	end
 
	assign mfc0_value = ({32{mfc0_epc|eret_cmt}} & cp0_epc     ) |
						({32{mfc0_cause}}        & cp0_cause   ) |
						({32{mfc0_status}}       & cp0_status  ) |
						({32{mfc0_count}}        & cp0_count   ) |
						({32{mfc0_compare}}      & cp0_compare ) |
						({32{mfc0_badvaddr}}     & cp0_badvaddr);

	endmodule