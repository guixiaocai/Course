`timescale 1ns / 1ps
module mycpu_top(
    input [0:0] clk,
    input [0:0] resetn,
    input [31:0] inst_sram_rdata,
    input [31:0] data_sram_rdata,
    output reg inst_sram_en,
    output [3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    output reg [0:0] data_sram_en,
    output reg [3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output reg [31:0] data_sram_wdata,
    output reg [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output reg [31:0] debug_wb_rf_wdata
    );
   
    wire [5:0] op, func;
    wire [4:0] rs, rt, rd, sa;           
    wire [15:0] immediate;
    wire [31:0] immediate_32, reg_rdata1, reg_rdata2, ALU_Result, A, B;
    wire [12:0] Ctrl;
    wire [4:0] reg_waddr;
    wire [3:0] ALUop, Write_strb;
    wire Zero, reg_wen;
                    
    reg [2:0] state, next_state;
    reg [31:0] PC, inst; 
                    
    //operation code        
    parameter ADDIU = 6'b001001, LW = 6'b100011, SW = 6'b101011, BNE = 6'b000101, NOP = 6'b000000, ADDU = 6'b100001, BEQ = 6'b000100, LUI = 6'b001111, SUBU = 6'b100011, SLL = 6'b000000, SLTI = 6'b001010, SLT = 6'b101010, SLTIU = 6'b001011, OR = 6'b100101, ORI = 6'b001101, AND = 6'b100100, MOVE = 6'b100101, J = 6'b000010, JAL = 6'b000011, JR = 6'b001000, ANDI = 6'b001100, BGEZ = 5'b00001, BLEZ = 6'b000110, BLTZ = 5'b00000, JALR = 6'b001001, LB = 6'b100000, LBU = 6'b100100, LH = 6'b100001, LHU = 6'b100101, LWL = 6'b100010, LWR = 6'b100110, MOVN = 6'b001011, MOVZ = 6'b001010, NOR = 6'b100111, SB = 6'b101000, SH = 6'b101001, SLLV = 6'b000100, SLTU = 6'b101011, SRA = 6'b000011, SRAV = 6'b000111, SRL = 6'b000010, SRLV = 6'b000110, SWL = 6'b101010, SWR = 6'b101110, XOR = 6'b100110, XORI = 6'b001110, SPE = 6'b000000, BGTZ = 6'b000111;       
    
    //different states        
    parameter IF = 3'd0,      //fetch instruction
              IW = 3'd1,      //instruction wait
              ID_EX = 3'd2,   //execute
              LD = 3'd3,      //load
              RDW = 3'd4,     //read and write wait
              WB = 3'd5,      //write back
              ST = 3'd6;      //store
    
    assign op = inst[31:26];        
    assign rs = inst[25:21];        
    assign rt = inst[20:16];        
    assign rd = inst[15:11];        
    assign sa = inst[10:6];        
    assign immediate = inst[15:0];        
    assign func = inst[5:0];        
    assign inst_sram_addr = PC;
    assign inst_sram_wen = 4'b0;
    assign inst_sram_wdata = 32'b0;
    assign data_sram_addr = {ALU_Result[31:2], 2'd0};
    assign debug_wb_rf_wen = {4{reg_wen}};
    assign debug_wb_rf_wnum = reg_waddr;
    assign reg_wen = (state == WB) ? Ctrl[5] : (!Ctrl[10:9] && state == ID_EX);  
    assign reg_waddr = (Ctrl[10] | Ctrl[9]) ? 5'd31: 
                       Ctrl[6]              ?    rd:
                                                 rt;      
        
    //alu operands
    assign A = Ctrl[0] ?       32'd0:
               Ctrl[1] ? {27'd0, sa}:
                          reg_rdata1;   
    assign B = Ctrl[2] ? immediate_32 : reg_rdata2;
        
    //sign extend 1:signed 0:unsigned        
    assign immediate_32 = Ctrl[3] ? {{16{immediate[15]}}, immediate[15:0]} : {16'd0, immediate[15:0]};

    //skip of state        
    always @ (posedge clk)    begin      
        if(!resetn)        
            state <= IF;
        else
            state <= next_state;        
    end            
        
    //get next state       
    always @ (*) begin        
        case(state)        
            IF: next_state = inst_sram_en ? IW : IF;        
            IW: next_state = ID_EX;
            ID_EX: begin        
                if(Ctrl[7]) begin 
                    next_state = ST;
                end
                else if(Ctrl[8]) begin
                    next_state = LD;
                end
                else if(Ctrl[4] | Ctrl[12] | Ctrl[11] | Ctrl[10] | Ctrl[9]||op==BNE||op==BEQ) begin
                    next_state = IF;
                end
                else begin
                    next_state = WB;
                end
            end        
            LD: next_state = data_sram_en ? RDW : LD;      
            RDW: next_state = WB;    
            WB: next_state = IF;        
            ST: next_state = (data_sram_en & data_sram_wen) ? IF : ST;
            default: next_state = IF;     
        endcase        
    end 
        
    //output different signals in different state & pc update 
    always @ (posedge clk) begin
        if(!resetn) begin        
            PC <= 32'hbfc00000;
            debug_wb_pc <= 32'hbfc00000;
            inst_sram_en <= 1'd1;
            data_sram_en <= 1'd0;
            data_sram_wen <= 4'd0;
        end        
        else begin
        case(state)
            IF: inst_sram_en <= 1'b0;
            IW: inst <= inst_sram_rdata;
            ID_EX: 
            begin
                data_sram_en <= (Ctrl[8] | Ctrl[7]) ? 1'd1 : 1'd0;
                data_sram_wen <= Ctrl[7] ? Write_strb : 4'd0;
                inst_sram_en <= next_state == IF ? 1'd1 : 1'd0;
                if(Ctrl[11] | Ctrl[9])  
                begin      
                    PC[31:2] <= reg_rdata1[31:2];  
                    debug_wb_pc[31:2] <= next_state == IF ? reg_rdata1[31:2] : debug_wb_pc[31:2];
                end         
                else if(Ctrl[12] | Ctrl[10])   
                begin
                    PC[31:2] <= {PC[31:28], inst[25:0]};     
                    debug_wb_pc[31:2] <= next_state == IF ? {PC[31:28], inst[25:0]} : debug_wb_pc[31:2];
                end
                else    
                begin
                    PC <= Ctrl[4] ? ( PC + 4 + immediate_32*4) : (PC + 4);  
                    debug_wb_pc <= next_state == IF ? ( Ctrl[4] ? ( PC + 4 + immediate_32*4) : (PC + 4)) : debug_wb_pc;
                end
            end
            ST: 
            begin
                debug_wb_pc <= PC; 
                data_sram_en <= 1'd0;
                data_sram_wen <= 4'd0;
                inst_sram_en <= 1'd1;
            end
            LD: 
            begin
                data_sram_en <= 1'b0;   
            end
            WB: 
            begin
                debug_wb_pc <= PC;
                inst_sram_en <= 1'd1;
            end
            default:;
        endcase
        end        
    end         
                  
            
    //write data back in registers        
    always @ (*) 
    begin        
        if(Ctrl[10:9])        
            debug_wb_rf_wdata = PC + 32'd8;         
        else if(Ctrl[8])    
        begin        
            if(op == LWL)    
            begin       
                case(ALU_Result[1:0])        
                    2'b00:debug_wb_rf_wdata = {data_sram_rdata[7:0], reg_rdata2[23:0]};        
                    2'b01:debug_wb_rf_wdata = {data_sram_rdata[15:0], reg_rdata2[15:0]};        
                    2'b10:debug_wb_rf_wdata = {data_sram_rdata[23:0], reg_rdata2[7:0]};        
                    2'b11:debug_wb_rf_wdata = data_sram_rdata;       
                endcase        
            end                
            else if(op == LWR)    
            begin        
                case(ALU_Result[1:0])        
                    2'b00:debug_wb_rf_wdata = data_sram_rdata;        
                    2'b01:debug_wb_rf_wdata = {reg_rdata2[31:24], data_sram_rdata[31:8]};        
                    2'b10:debug_wb_rf_wdata = {reg_rdata2[31:16], data_sram_rdata[31:16]};        
                    2'b11:debug_wb_rf_wdata = {reg_rdata2[31:8], data_sram_rdata[31:24]};        
                endcase        
            end                
            else if(op == LB || op == LBU)    
            begin        
                case(ALU_Result[1:0])        
                    2'b00:debug_wb_rf_wdata = (op==LB)?{{24{data_sram_rdata[7]}},data_sram_rdata[7:0]}:{{24{1'b0}},data_sram_rdata[7:0]};        
                    2'b01:debug_wb_rf_wdata = (op==LB)?{{24{data_sram_rdata[15]}},data_sram_rdata[15:8]}:{{24{1'b0}},data_sram_rdata[15:8]};        
                    2'b10:debug_wb_rf_wdata = (op==LB)?{{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}:{{24{1'b0}},data_sram_rdata[23:16]};        
                    2'b11:debug_wb_rf_wdata = (op==LB)?{{24{data_sram_rdata[31]}},data_sram_rdata[31:24]}:{{24{1'b0}},data_sram_rdata[31:24]};        
                endcase        
            end                
            else if(op == LH || op == LHU)    
            begin        
                case(ALU_Result[1])        
                    1'b0: debug_wb_rf_wdata = (op==LH)?{{16{data_sram_rdata[15]}},data_sram_rdata[15:0]}:{{16{1'b0}},data_sram_rdata[15:0]};        
                    1'b1: debug_wb_rf_wdata = (op==LH)?{{16{data_sram_rdata[31]}},data_sram_rdata[31:16]}:{{16{1'b0}},data_sram_rdata[31:16]};                  
                endcase        
            end                
            else        
                debug_wb_rf_wdata = data_sram_rdata;    
        end                
        else if(Ctrl[0] & Ctrl[5])        
            debug_wb_rf_wdata = reg_rdata1;        
        else if(!Ctrl[8])        
            debug_wb_rf_wdata = ALU_Result;        
    end            
        
    //write data in memory       
            always @ (*) 
            begin        
                if(op == SWL)    
                begin      
                    case(ALU_Result[1:0])        
                        2'b00:data_sram_wdata = {{24{1'b0}}, reg_rdata2[31:24]};        
                        2'b01:data_sram_wdata = {{16{1'b0}}, reg_rdata2[31:16]};        
                        2'b10:data_sram_wdata = {{8{1'b0}}, reg_rdata2[31:8]};        
                        2'b11:data_sram_wdata = reg_rdata2;        
                    endcase        
                end                
                else if(op == SWR) 
                begin      
                    case(ALU_Result[1:0])        
                        2'b00:data_sram_wdata = reg_rdata2;        
                        2'b01:data_sram_wdata = {reg_rdata2[23:0], {8{1'b0}}};       
                        2'b10:data_sram_wdata = {reg_rdata2[15:0], {16{1'b0}}};        
                        2'b11:data_sram_wdata = {reg_rdata2[7:0], {24{1'b0}}};        
                    endcase        
                end                
                else if (op == SB)        
                    data_sram_wdata = {reg_rdata2[7:0], reg_rdata2[7:0], reg_rdata2[7:0], reg_rdata2[7:0]};            
                else if(op == SH)        
                    data_sram_wdata = {reg_rdata2[15:0], reg_rdata2[15:0]};        
                else        
                    data_sram_wdata = reg_rdata2;        
            end  
        
            control_unit cu(        
                    .op         (op        ),        
                    .func       (func      ),        
                    .rt         (rt        ),        
                    .Zero       (Zero      ),       
                    .ALU_Result (ALU_Result),        
                    .reg_rdata1 (reg_rdata1),        
                    .Ctrl       (Ctrl      ),       
                    .ALUop      (ALUop     ),       
                    .Write_strb (Write_strb)
                  );        
                
            alu u_alu(
                    .A          (A         ),  
                    .B          (B         ),
                    .ALUop      (ALUop     ),
                    .Zero       (Zero      ),
                    .ALU_Result (ALU_Result)
                    );        
                   
            reg_file rf_i(        
                    .clk        (clk              ),         
                    .rst        (resetn           ),
                    .waddr      (reg_waddr        ),         
                    .raddr1     (rs               ),
                    .raddr2     (rt               ),
                    .wen        (reg_wen          ),        
                    .wdata      (debug_wb_rf_wdata),        
                    .reg_rdata1     (reg_rdata1       ),         
                    .reg_rdata2     (reg_rdata2       )        
                    );
endmodule

