module div(
    input         div_clk,
    input         resetn,
    input         div_signed,
    input         div,
    input  [31:0] x, 
    input  [31:0] y,
    output [31:0] s,      //quotient
    output [31:0] r,      //reminder
    output        complete
);
    
    reg [5 :0] count;
    reg [63:0] x_div;
    reg [32:0] y_div;
    reg [31:0] q_div;
    reg        div_signed_r;
    reg        complete_r;
    reg [32:0] temp_32;

    wire        x_signed = x[31] & div_signed;
    wire        y_signed = y[31] & div_signed;
    wire [63:0] x_abs = {32'd0, ({32{x_signed}}^x) + x_signed};
    wire [32:0] y_abs = {1'd0, ({32{y_signed}}^y) + y_signed};
    wire [31:0] r_abs;
    wire        s_signed = (x[31]^y[31])&div_signed_r;
    wire        r_signed = x[31] & div_signed_r;   
    wire [32:0] temp = count==6'd33 ? temp_32 : x_div[63:31] - y_div;

    always @(posedge div_clk) begin
      if(!resetn) begin
        count        <= 6'd0;
        x_div        <= 64'd0;
        y_div        <= 33'd0;
        q_div        <= 32'd0;
        complete_r   <= 1'd0;
        temp_32      <= 33'd0;
      end
      else if(div) begin
        y_div        <= y_abs;
        q_div        <= count==6'd33 ? 32'd0 : (q_div<<1) + {31'd0, ~temp[32]};
        count        <= count==6'd33 ? 6'd0  : (count + 6'd1);
        complete_r   <= count==6'd32;
        div_signed_r <= count==6'd0  ? div_signed : div_signed_r;
        temp_32      <= count==6'd32 ? x_div[63:31] - y_div : temp_32;
        x_div        <= count==6'd0  ? x_abs                  :
                        temp[32]     ? x_div << 1             :
                                      {temp, x_div[30:0]} << 1;
      end
      else begin
        complete_r   <= count==6'd33 ? 1'd0 : complete_r;
      end
    end

    assign complete = complete_r;
    assign r_abs    = temp[32] ? x_div[63:32] : temp[31:0];
    assign s        = ({32{s_signed}}^q_div) + {30'd0,s_signed};
    assign r        = ({32{r_signed}}^r_abs) + {30'd0,r_signed};
endmodule