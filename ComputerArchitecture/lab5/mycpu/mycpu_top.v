module mycpu_top(
    input  [5 :0] int,                          //hard_int
    input         aclk,
    input         aresetn,
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
    output        bready,                       //*
//debug signals
	output [31:0] debug_wb_pc,
	output [3 :0] debug_wb_rf_wen,
	output [4 :0] debug_wb_rf_wnum,
	output [31:0] debug_wb_rf_wdata
);


wire        inst_req,data_req;
wire        inst_wr,data_wr;
wire [1 :0] inst_size,data_size;
wire [31:0] inst_addr,data_addr;
wire [31:0] inst_wdata,data_wdata;
wire        inst_addr_ok,data_addr_ok;
wire        inst_data_ok,data_data_ok;
wire [31:0] inst_rdata,data_rdata;
wire [3 :0] data_wstrb;

cpu_axi_interface cpu_axi_ifc  (
    .clk         (aclk        ),
    .resetn      (aresetn     ),

    .inst_req    (inst_req    ),
    .inst_wr     (inst_wr     ),
    .inst_size   (inst_size   ),
    .inst_addr   (inst_addr   ),
    .inst_wdata  (inst_wdata  ),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),
    .inst_rdata  (inst_rdata  ),

    .data_req    (data_req    ),
    .data_wr     (data_wr     ),
    .data_size   (data_size   ),
    .data_addr   (data_addr   ),
    .data_wdata  (data_wdata  ),
    .data_wstrb  (data_wstrb  ),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    .data_rdata  (data_rdata  ),

    .arid        (arid        ),
    .araddr      (araddr      ),
    .arlen       (arlen       ),
    .arsize      (arsize      ),
    .arburst     (arburst     ),
    .arlock      (arlock      ),
    .arcache     (arcache     ),
    .arprot      (arprot      ),
    .arvalid     (arvalid     ),
    .arready     (arready     ),

    .rid         (rid         ),
    .rdata       (rdata       ),
    .rresp       (rresp       ),
    .rlast       (rlast       ),
    .rvalid      (rvalid      ),
    .rready      (rready      ),

    .awid        (awid        ),
    .awaddr      (awaddr      ),
    .awlen       (awlen       ),
    .awsize      (awsize      ),
    .awburst     (awburst     ),
    .awlock      (awlock      ),
    .awcache     (awcache     ),
    .awprot      (awprot      ),
    .awvalid     (awvalid     ),
    .awready     (awready     ),   

    .wid         (wid         ),
    .wdata       (wdata       ),
    .wstrb       (wstrb       ),
    .wlast       (wlast       ),
    .wvalid      (wvalid      ),
    .wready      (wready      ),   

    .bid         (bid         ),
    .bresp       (bresp       ),
    .bvalid      (bvalid      ),
    .bready      (bready      )    
);

cpu_core  cpu_core(
    .clk         (aclk        ),
    .resetn      (aresetn     ),
    .hard_int    (int         ),
    
    .inst_req    (inst_req    ),
    .inst_wr     (inst_wr     ),
    .inst_size   (inst_size   ),
    .inst_addr   (inst_addr   ),
    .inst_wdata  (inst_wdata  ),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),
    .inst_rdata  (inst_rdata  ),

    .data_req    (data_req    ),
    .data_wr     (data_wr     ),
    .data_size   (data_size   ),
    .data_addr   (data_addr   ),
    .data_wdata  (data_wdata  ),
    .data_wstrb  (data_wstrb  ),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    .data_rdata  (data_rdata  ),

    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);
endmodule