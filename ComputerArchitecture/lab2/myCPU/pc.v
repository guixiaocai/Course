module pc(
    input  [31:0] pc_if,
    input  [31:0] pc_id,
    input  [31:0] alu_src1_id,
    input  [34:0] ctrl,
    input  [31:0] inst_id,
    output [31:0] npc
);

    assign npc = ctrl[4] ? {alu_src1_id[31:2], 2'd0                               }:
                 ctrl[5] ? {pc_id[31:28], inst_id[25:0], 2'd0                     }:
                 ctrl[8] ? pc_id + 32'd4 + {{14{inst_id[15]}}, inst_id[15:0], 2'd0}:
                           pc_if + 32'd4;
    
endmodule