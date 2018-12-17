#include <stdio.h>
#include <stdlib.h>

char *myname="Chen Mingyu";
char gdata[128];
char bdata[16] = {1,2,3,4};
main() {
	char * ldata[16];	
	char * ddata;

	ddata = malloc(16);
	printf("gdata: %llX\nbdata:%llX\nldata:%llx\nddata:%llx\n",
		gdata,bdata,ldata,ddata);
	free(ddata);
}


module my_cpu(
    input [0:0] clk,
    input [0:0] resetn,
    output [0:0] inst_sram_en,
    output [3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input [31:0] inst_sram_rdata,
    output [0:0] data_sram_en,
    output [3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input [31:0] data_sram_rdata,
    output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );
    
endmodule