module cpu_axi_interface(
/* sram_like ports,slave */
    input         clk,
    input         resetn,
// for inst_sram,slave 
    input         inst_req,                     
    input         inst_wr,
    input  [1 :0] inst_size,                    // 2'd0 : 1byte  2'd1:2byte  2'd2:4byte
    input  [31:0] inst_addr,
    input  [31:0] inst_wdata,
    output        inst_addr_ok,
    output        inst_data_ok,
    output [31:0] inst_rdata,
// for data_sram,slave
    input         data_req,
    input         data_wr,
    input  [1 :0] data_size,
    input  [31:0] data_addr,
    input  [31:0] data_wdata,
    input  [3 :0] data_wstrb,
    output        data_addr_ok,
    output        data_data_ok,
    output [31:0] data_rdata,

/* axi ports,master */
// read require address channel,master
    output [3 :0] arid,                         //inst = 0 data = 1
    output [31:0] araddr,
    output [7 :0] arlen,                        //always = 0
    output [2 :0] arsize,
    output [1 :0] arburst,                      //always = 2'b01
    output [1 :0] arlock,                       //always = 0
    output [3 :0] arcache,                      //always = 0
    output [2 :0] arprot,                       //always = 0
    output        arvalid,                      //*
    input         arready,                      //*
// read require data channel,master
    input  [3 :0] rid,                          //inst = 0 data = 1
    input  [31:0] rdata,
    input  [1 :0] rresp,                        //could ignore
    input         rlast,                        //could ignore
    input         rvalid,                       //*
    output        rready,                       //*
// write require address channel,master
    output [3 :0] awid,                         //always = 1
    output [31:0] awaddr,
    output [7 :0] awlen,                        //always = 0
    output [2 :0] awsize,
    output [1 :0] awburst,                      //always = 2'b01
    output [1 :0] awlock,                       //always = 0
    output [3 :0] awcache,                      //always = 0
    output [2 :0] awprot,                       //always = 0
    output        awvalid,                      //*
    input         awready,                      //*   
// write require data channel,master
    output [3 :0] wid,                          //always = 1
    output [31:0] wdata,
    output [3 :0] wstrb,                        //*
    output        wlast,                        //always = 1
    output        wvalid,                       //*
    input         wready,                       //*
// write require response channel,master
    input  [3 :0] bid,                          //could ignore
    input  [1 :0] bresp,                        //could ignore
    input         bvalid,                       //*
    output        bready                        //*
);
// unvarying axi ports
assign arlen = 8'd0;
assign arburst = 2'b01;
assign arlock = 2'd0;
assign arcache = 4'd0;
assign arprot = 3'd0;
assign awid = 4'd1;
assign awlen = 8'd0;
assign awburst = 2'b01;
assign awlock = 2'd0;
assign awcache = 4'd0;
assign awprot = 3'd0;
assign wid = 4'd1;
assign wlast = 1'd1;
// read and write channel state could use state machine
// saving cpu-from data registers
reg [1 :0] inst_rd_size,data_rd_size,data_wt_size;
reg [31:0] inst_rd_addr,data_rd_addr,data_wt_addr;
reg [31:0] data_rd_rdata,data_wt_wdata;
reg [3 :0] data_wt_strb;
always @(posedge clk)
begin
    if(!resetn)
    begin
        inst_rd_size <= 2'd0;
        inst_rd_addr <= 32'd0;
    end
    else if (inst_addr_ok)//&& how to define first require
    begin
        inst_rd_size <= inst_size;
        inst_rd_addr <= inst_addr;
    end
end
assign inst_addr_ok = inst_req && !inst_wr && (!axi_inst_rd) && !axi_data_wt;

always@(posedge clk)
begin
    if(!resetn)
    begin
        data_rd_size <= 2'd0;
        data_rd_addr <= 32'd0;
    end
    else if (data_rd_addr_ok)//&& how to define first require
    begin
        data_rd_size <= data_size;
        data_rd_addr <= data_addr;
    end

    if(!resetn)
    begin
        data_rd_rdata <= 32'd0;
    end
    else if (rready && rvalid && arid == 4'd1)
    begin
        data_rd_rdata <= rdata;
    end

    if(!resetn)
    begin
        data_wt_size <= 2'd0;
        data_wt_addr <= 32'd0;
        data_wt_wdata <= 32'd0;
        data_wt_size <= 4'd0;
    end
    else if (data_wt_addr_ok)// && other ?
    begin
        data_wt_size <= data_size;
        data_wt_addr <= data_addr;
        data_wt_wdata <= data_wdata;
        data_wt_strb <= data_wstrb;
    end
end
wire data_rd_addr_ok,data_wt_addr_ok;
assign data_rd_addr_ok = (data_req && !data_wr && !axi_data_rd && !axi_data_wt);//
assign data_wt_addr_ok = (data_req && data_wr && !axi_data_wt && !axi_data_rd);//
assign data_addr_ok = (data_rd_addr_ok )|| (data_wt_addr_ok);

reg inst_rd_req,inst_rd_rsv_wait,inst_wt_req,inst_wt_sd_wait,inst_wt_rsv_wait;
reg data_rd_req,data_rd_rsv_wait,data_wt_req,data_wt_sd_wait,data_wt_rsv_wait;

// inst read part
always @(posedge clk)
begin
    if(!resetn)
    begin
        inst_rd_req <= 1'd0;
    end    
    else if (arvalid && arready && (arid == 4'd0))
    begin
        inst_rd_req <= 1'd0;
    end
    else if (inst_addr_ok)
    begin
        inst_rd_req <= 1'd1;
    end
  
    if(!resetn)
    begin
        inst_rd_rsv_wait <= 1'd0;
    end 
    else if (rready && rvalid && (rid == 4'd0))
    begin
        inst_rd_rsv_wait <= 1'd0;
    end  
    else if (arvalid && arready && (arid == 4'd0))
    begin
        inst_rd_rsv_wait <= 1'd1;
    end

end
// inst write part is not needed
// data read part
always @(posedge clk)
begin
    if(!resetn)
    begin
        data_rd_req <= 1'd0;
    end
    else if (arvalid && arready && (arid == 4'd1)) 
    begin
        data_rd_req <= 1'd0;
    end
    else if (data_rd_addr_ok)//
    begin
        data_rd_req <= 1'd1;
    end
    
    if(!resetn)
    begin
        data_rd_rsv_wait <= 1'd0;
    end    
    else if (rready && rvalid && (rid == 4'd1))
    begin
        data_rd_rsv_wait <= 1'd0;
    end  
    else if (arvalid && arready && (arid == 4'd1))
    begin
        data_rd_rsv_wait <= 1'd1;
    end

end

//data write part
always@(posedge clk)
begin
    if(!resetn)
    begin
        data_wt_req <= 1'd0;
    end
    else if (awvalid && awready)
    begin
        data_wt_req <= 1'd0;
    end
    else if (data_wt_addr_ok)//
    begin
        data_wt_req <= 1'd1;
    end
    
    if(!resetn)
    begin
        data_wt_sd_wait <= 1'd0;
    end   
    else if (wvalid && wready)
    begin
        data_wt_sd_wait <= 1'd0;
    end
    else if (awvalid && awready)
    begin
        data_wt_sd_wait <= 1'd1;
    end

    if(!resetn)
    begin
        data_wt_rsv_wait <= 1'd0;
    end
    else if (bready && bvalid)
    begin
        data_wt_rsv_wait <= 1'd0;
    end
    else if (wready && wvalid)
    begin
        data_wt_rsv_wait <= 1'd1;
    end
end
wire axi_rd_req,axi_rd_wait,axi_wt_req,axi_wt_wait;
wire axi_rd,axi_wt;
wire axi_inst_rd,axi_data_rd,axi_data_wt;
assign axi_rd_req = inst_rd_req || data_rd_req;
assign axi_rd_wait = inst_rd_rsv_wait || data_rd_rsv_wait;
assign axi_rd = axi_rd_req || axi_rd_wait;
assign axi_wt_req = data_wt_req;
assign axi_wt_wait = data_wt_sd_wait || data_wt_rsv_wait;
assign axi_wt = axi_wt_req || axi_wt_wait;//(data_wt_addr_ok) ||
assign axi_inst_rd = inst_rd_req || inst_rd_rsv_wait;//(inst_addr_ok) ||
assign axi_data_rd = data_rd_req || data_rd_rsv_wait;//(data_rd_addr_ok) ||
assign axi_data_wt = data_wt_req || data_wt_sd_wait || data_wt_rsv_wait;//(data_wt_addr_ok) ||


assign arid = (data_rd_req) ? 4'd1 : 
              (inst_rd_req) ? 4'd0 :
                                    4'd0;
assign araddr = (data_rd_req) ? data_rd_addr : 
                (inst_rd_req) ? inst_rd_addr : 
                                                32'd0;
assign arsize = (data_rd_req && data_rd_size == 2'd0) ? 3'd1 :
                (data_rd_req && data_rd_size == 2'd1) ? 3'd2 :
                (data_rd_req && data_rd_size == 2'd2) ? 3'd4 :
                (inst_rd_req && inst_rd_size == 2'd2) ? 3'd4 :
                                                               3'd0;

reg reg_arvalid;
assign arvalid = reg_arvalid;
// need to ensure that no waiting bvalid writing task
always@(posedge clk)
begin
    if(!resetn)
    begin
        reg_arvalid <= 1'd0;
    end    
    else if (arvalid && arready)
    begin
        reg_arvalid <= 1'd0;
    end
    else if (axi_rd_req)//slow 1 tick  //*******&& !(data_wt_addr_ok ||axi_data_wt)
    begin
        reg_arvalid <= 1'd1;
    end

end

//read require data channel
reg reg_rready;
assign rready = 1'b1;//reg_rready;
always @(posedge clk)
begin
    if(!resetn)
    begin
        reg_rready <= 1'd0;
    end
    else if (rvalid && rready)
    begin
        reg_rready <= 1'd0;
    end
    else if (arvalid && arready)
    begin
        reg_rready <= 1'd1;
    end
end

//write require address channel
assign awaddr = (data_wt_req) ? data_wt_addr : 32'd0;
assign awsize = (data_wt_req && data_wt_size == 2'd0) ? 3'd1 :
                (data_wt_req && data_wt_size == 2'd1) ? 3'd2 :
                (data_wt_req && data_wt_size == 2'd2) ? 3'd4 :
                                                               3'd0;              
reg reg_awvalid;
assign awvalid = reg_awvalid;
always@(posedge clk)
begin
    if (!resetn)
    begin
        reg_awvalid <= 1'd0;
    end    
    else if (awready && awvalid)
    begin
        reg_awvalid <= 1'd0;
    end
    else if (axi_wt_req)//slow 1 tick 
    begin
        reg_awvalid <= 1'd1;
    end
end

//write require data channel
assign wdata = {32{data_wt_sd_wait}} & data_wt_wdata;//?????????

/*wire data_size0,data_size1,data_size2,data_size3;
wire data_addr0,data_addr1,data_addr2,data_addr3;
assign data_size0 = data_wt_size == 2'd0;
assign data_size1 = data_wt_size == 2'd1;
assign data_size2 = data_wt_size == 2'd2;
assign data_size3 = data_wt_size == 2'd3;
assign data_addr0 = data_wt_addr[1:0] == 2'd0;
assign data_addr1 = data_wt_addr[1:0] == 2'd1;
assign data_addr2 = data_wt_addr[1:0] == 2'd2;
assign data_addr3 = data_wt_addr[1:0] == 2'd3;
assign wstrb = ({4{data_size0 & data_addr0}} & 4'd1 )
              |({4{data_size0 & data_addr1}} & 4'd2 )
              |({4{data_size0 & data_addr2}} & 4'd4 )
              |({4{data_size0 & data_addr3}} & 4'd8 )
              |({4{data_size1 & data_addr0}} & 4'd3 )
              |({4{data_size1 & data_addr2}} & 4'd12)
              |({4{data_size2 & data_addr0}} & 4'd15);*/
              
assign wstrb = data_wt_strb;
reg reg_wvalid;
assign wvalid = reg_wvalid;
always@(posedge clk)
begin
    if(!resetn)
    begin
        reg_wvalid <= 1'd0;
    end    
    else if (wready && wvalid)
    begin
        reg_wvalid <= 1'd0;
    end
    else if (awready && awvalid) //slow 1 tick 
    begin
        reg_wvalid <= 1'd1;
    end
end

//write response channel
reg reg_bready;
assign bready = reg_bready;
always@(posedge clk)
begin
    if(!resetn)
    begin
        reg_bready <= 1'd0;
    end    
    else if (bvalid && bready)
    begin
        reg_bready <= 1'd0;
    end
    else if (wready && wvalid)//slow 1 tick
    begin
        reg_bready <= 1'd1;
    end
end

wire inst_rd_ok;
assign inst_rd_ok = (rready && rvalid && rid == 4'd0);
assign inst_data_ok = inst_rd_ok;
assign inst_rdata = {32{inst_rd_ok}} & rdata;

wire data_rd_ok,data_wt_ok;
assign data_rd_ok = (rready && rvalid && rid == 4'd1);
assign data_wt_ok = (bready && bvalid);
assign data_data_ok = data_rd_ok || data_wt_ok;
assign data_rdata = ({32{data_rd_ok}} & rdata);
endmodule