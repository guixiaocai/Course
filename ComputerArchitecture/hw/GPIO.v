／／阅读AMBA APB总线的协议并设计一个APB接口的GPIO模块
module GPIO(
    input         pclk,
    input         presetn,
    input         pen,
    input         pwrite,
    input         psel,
    input  [ 9:0] paddr,
    output [31:0] prdata,
    input  [31:0] pwdata,
    input  [31:0] gpio_i,
    input  [31:0] gpio_o,
    output [31:0] gpio_o_e
);

    reg [31:0] reg_gpio_i;
    reg [31:0] reg_gpio_o;
    reg [31:0] reg_gpio_o_e;
    reg [31:0] reg_gpio_i_r;
    
    // read channel
    always @ (posedge pclk)  begin
        if(!presetn)  begin
            reg_gpio_i   <= 32'd0
            reg_gpio_i_r <= 32'd0;
        end
        else begin
            reg_gpio_i   <= reg_gpio_i_r;
            reg_gpio_i_r <= gpio_i;
        end
    end

    assign prdata = paddr==10'd0 ? reg_gpio_o   :
                    paddr==10'd1 ? reg_gpio_o_e :
                                   reg_gpio_i   ;

    // write channel
    always @(posedge pclk)  begin
        if(!presetn)  begin
            reg_gpio_o   <= 32'd0;
            reg_gpio_o_e <= 32'd0;
        end
        else if(pen & pwrite & psel) begin
            if(paddr == 10'd1)
                reg_gpio_o_e <= pwdata;
            else if (paddr == 10'd0)
                reg_gpio_o   <= pwdata;
        end
    end

    assign gpio_o   = reg_gpio_o;
    assign gpio_o_e = reg_gpio_o_e;
    
endmodule