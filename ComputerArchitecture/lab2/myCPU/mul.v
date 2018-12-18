module mul(
    input         mul_clk,
    input         resetn,
    input         mul_signed,
    input  [31:0] x,
    input  [31:0] y,
    input         id_valid,
    input         ex_allowin,
    output [63:0] result
);
    reg pipe1_valid;
    reg pipe2_valid;

    //pipeline 1
   /* wire pipe1_ready_go = 1'b1;
    wire pipe1_allowin = !pipe1_valid || pipe1_ready_go && pipe2_allowin;
    wire pipe1_to_pipe2_valid = pipe1_valid & pipe1_ready_go;

    always @(posedge mul_clk) begin
      if(!resetn) begin
        pipe1_valid <= 1'b0;
      end else if(pipe1_allowin) begin
        pipe1_valid <= 1'b1;
      end
    end */

    //booth 2 bits 
    wire [16:0] booth_c;                             //Booth Couts
    wire [63:0] booth_part_prod [16:0];              //part products before switch
    wire [16:0] part_prod [63:0];                    //part products after switch
    wire [63:0] x_mul = {{32{x[31]&mul_signed}}, x}; 
    wire [33:0] y_mul = {{ 2{y[31]&mul_signed}}, y};
    
    genvar j;
    generate
    for(j = 0; j < 17; j = j + 1) begin : booth
        if(j == 0) begin
          booth_2b booth_0(
                            .Y({y_mul[1:0], 1'b0}), 
                            .X(x_mul             ),
                            .P(booth_part_prod[0]), 
                            .C(booth_c[0]        )
                          );
        end else begin
          booth_2b booth(
                            .Y(y_mul[2*j+1:2*j-1]), 
                            .X(x_mul<<(2*j)      ), 
                            .P(booth_part_prod[j]), 
                            .C(booth_c[j]        )
                        );
        end
    end
    endgenerate

    //switch part products
    genvar k;
    generate
    for(k = 0; k < 64; k = k + 1)
        begin: switch
            assign part_prod[k] = {
                                        booth_part_prod[16][k],
                                        booth_part_prod[15][k], 
                                        booth_part_prod[14][k], 
                                        booth_part_prod[13][k], 
                                        booth_part_prod[12][k], 
                                        booth_part_prod[11][k], 
                                        booth_part_prod[10][k], 
                                        booth_part_prod[ 9][k], 
                                        booth_part_prod[ 8][k], 
                                        booth_part_prod[ 7][k], 
                                        booth_part_prod[ 6][k], 
                                        booth_part_prod[ 5][k], 
                                        booth_part_prod[ 4][k], 
                                        booth_part_prod[ 3][k], 
                                        booth_part_prod[ 2][k], 
                                        booth_part_prod[ 1][k], 
                                        booth_part_prod[ 0][k]
                                  };
        end
    endgenerate

    //pipeline 2
	/*wire pipe2_ready_go = 1'b1;
    wire out_allow = 1'b1;
	wire pipe2_allowin = !pipe2_valid || pipe2_ready_go && out_allow;
*/
    reg  [16:0] booth_c_r;              //booth couts from pipeline 1
    reg  [16:0] part_prod_r[63:0];      //part prods from pipeline 1
    wire [13:0] c[63:0];                //couts for wallace tree
    wire [63:0] add_src1, add_src2;     //final add operands
    
    always @(posedge mul_clk)
    begin
        /*if (!resetn) begin
            pipe2_valid <= 1'b0;
        end else begin
            if(pipe2_allowin) begin
                pipe2_valid <= pipe1_to_pipe2_valid;
            end
            if(pipe1_to_pipe2_valid & pipe2_allowin) begin
                booth_c_r <= booth_c;
            end
        end*/
        
        if(id_valid & ex_allowin) begin
                booth_c_r <= booth_c;
            end
    end

    genvar m;
    generate
        for(m = 0; m < 64; m = m + 1) begin : part_prod_trans
            always @(posedge mul_clk)
            begin
                if(id_valid & ex_allowin) begin
                    part_prod_r[m] <= part_prod[m];
                end
            end
        end
    endgenerate

    assign c[0] = booth_c_r[13:0];
    assign add_src2[0] = booth_c_r[14];
    
    genvar i;
    generate
    for(i = 0; i < 64; i = i + 1) 
    begin: wallace
        if(i < 63) begin
            wallace_16 wallace(
                                    .cin    (c[i]          ), 
                                    .data_in(part_prod_r[i]), 
                                    .cout   (c[i+1]        ), 
                                    .C      (add_src2[i+1] ), 
                                    .S      (add_src1[i]   )
                               );
        end else begin
            wallace_16 wallace_63(
                                    .cin    (c[63]          ),
                                    .data_in(part_prod_r[63]), 
                                    .S      (add_src1[63]   )
                                 );
        end
    end
    endgenerate

    assign result = add_src1 + add_src2 + booth_c_r[15] + booth_c_r[16];
    
endmodule