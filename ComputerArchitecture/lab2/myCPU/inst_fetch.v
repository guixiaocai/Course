module inst_fetch(
    input         clk,
    input         resetn,
    input  [31:0] inst_sram_rdata,
    input  [31:0] npc,
    input         id_allowin,
    output        if_allowin,
    output        if_valid,
    output [31:0] pc_if,
    output [31:0] inst_if,
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,
    output [31:0] inst_sram_wdata,
    output [31:0] inst_sram_addr
);
    reg [31:0] reg_pc_if;

    assign if_allowin = id_allowin;

    always @ (posedge clk) begin
        if(!resetn) begin
            reg_pc_if <= 32'hbfc00000;
        end
        else if(if_allowin) begin
            reg_pc_if <= npc;
        end
    end

    assign if_valid        = 1'b1;
    assign inst_sram_en    = 1'd1;
    assign inst_sram_wen   = 4'd0;
    assign inst_sram_wdata = 32'd0;
    assign pc_if           = reg_pc_if;
    assign inst_if         = inst_sram_rdata;
    assign inst_sram_addr  = !resetn    ? 32'hbfc00000:
                             if_allowin ? npc         :
                                          reg_pc_if   ;


endmodule