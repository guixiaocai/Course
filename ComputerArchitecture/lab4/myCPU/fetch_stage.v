module fetch_stage (
    input clk,
    input resetn,

    output [31:0] if_inst,
    output [31:0] if_pc,
 // input  [31:0] npc, 
 // input  [31:0] epc,
    input [31:0] de_pc,
    input [31:0] de_inst,
    input [31:0] de_alu_src1,
    input [2:0] op_npc,

    // stage control signals
    //output op_npc,
    output if_valid,
    output if_allowin,
    output if_to_de_valid,
    input  de_allowin,

    //Instruction channel
	output        inst_sram_en,
	output [ 3:0] inst_sram_wen,
	output [31:0] inst_sram_addr,
	output [31:0] inst_sram_wdata,	
	input  [31:0] inst_sram_rdata
);
    reg         reg_if_valid;
    wire        validin;
    wire        if_ready_go;
    wire [31:0] npc;

    assign validin = 1'b1;
    assign if_ready_go = 1'b1;
    assign if_allowin = !if_valid || if_ready_go && de_allowin;
    assign if_to_de_valid = if_valid && if_ready_go;
    assign if_valid = reg_if_valid;
    //assign if_ready_go = de_allow_in;

    always@(posedge clk)
    begin
        if(!resetn)   begin
            reg_if_valid <= 1'b1;
        end
        else if (if_allowin)   begin
            reg_if_valid <= validin;
        end
    end

    reg [31:0] reg_if_pc;
    always@(posedge clk)  begin
        if(!resetn)        begin
            reg_if_pc <= 32'hbfc00000;
        end
        else if(validin && if_allowin)  begin
            reg_if_pc <= npc;
        end
    end

    assign if_pc = reg_if_pc;
    assign if_inst = inst_sram_rdata;
    assign inst_sram_en = if_allowin;
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'd0;
    assign inst_sram_addr = !resetn    ? 32'hbfc00000:
                            if_allowin ? npc         :
                                         reg_if_pc   ;
    
    assign npc = //op_npc [] ? epc :
                op_npc[0] ? {de_alu_src1[31:2], 2'd0                               } : 
                op_npc[1] ? {de_pc[31:28], de_inst[25:0], 2'd0                     } :
                op_npc[2] ? de_pc + 32'd4 + {{14{de_inst[15]}}, de_inst[15:0], 2'd0} :
                            if_pc + 32'd4;

    endmodule