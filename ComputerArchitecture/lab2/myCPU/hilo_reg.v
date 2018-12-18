module hilo_reg(
    input         clk,
    input         resetn,
    input  [34:0] ctrl,
    input  [31:0] hi_in,
    input  [31:0] lo_in,
    output [31:0] hi_o,
    output [31:0] lo_o
);

    reg [31:0] reg_hi;
    reg [31:0] reg_lo;

    wire hi_wen = ctrl[18] | ctrl[16] | ctrl[17] | ctrl[22] | ctrl[24];
    wire lo_wen = ctrl[19] | ctrl[16] | ctrl[17] | ctrl[22] | ctrl[24];

    always @(posedge clk)begin
      if(!resetn) begin
        reg_hi   <= 32'd0;
        reg_lo   <= 32'd0;
      end
      else begin
        if(hi_wen) begin        //mfhi,mult,multu,div,divu
          reg_hi <= hi_in;
        end
        if(lo_wen) begin        //mflo,mult,multu,div,divu
          reg_lo <= lo_in;
        end
      end
    end

    assign hi_o = resetn ? reg_hi : 32'd0;
    assign lo_o = resetn ? reg_lo : 32'd0;

endmodule