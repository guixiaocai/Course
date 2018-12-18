module reg_file(
    input         clk,
    input         resetn,
    input  [ 3:0] reg_wen,
    input  [ 4:0] reg_raddr1,
    input  [ 4:0] reg_raddr2,
    input  [ 4:0] reg_waddr,
    input  [31:0] reg_wdata,
    output [31:0] reg_rdata1,
    output [31:0] reg_rdata2
);
    reg [31:0] rf [31:0];

    always @(posedge clk) begin
      if(!resetn)
        rf[0] <= 32'd0;
      else
        rf[reg_waddr] <= reg_wen ? reg_wdata : rf[reg_waddr];
    end    

    assign reg_rdata1 = reg_raddr1 ? rf[reg_raddr1] : 32'd0;
    assign reg_rdata2 = reg_raddr2 ? rf[reg_raddr2] : 32'd0;

endmodule