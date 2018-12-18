module mul(
    input         mul_clk,
    input         resetn,
    input         mul_signed,
    input  [31:0] x,
    input  [31:0] y,
    input         de_to_ex_valid,
    input         ex_allowin,
    output [63:0] result
);

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

    reg  [16:0] booth_c_r;              //booth couts from pipeline 1
    reg  [16:0] part_prod_r[63:0];      //part prods from pipeline 1
    wire [13:0] c[63:0];                //couts for wallace tree
    wire [63:0] add_src1, add_src2;     //final add operands
    
    always @(posedge mul_clk)
    begin
        if(de_to_ex_valid & ex_allowin) begin
                booth_c_r <= booth_c;
        end
    end

    genvar m;
    generate
        for(m = 0; m < 64; m = m + 1) begin : part_prod_trans
            always @(posedge mul_clk)
            begin
                if(de_to_ex_valid & ex_allowin) begin
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

module booth_2b(
    input [2:0] Y,
    input [63:0] X,
    output [63:0] P,
    output C
);
    assign P = Y==3'b001 ? X      :
               Y==3'b010 ? X      :
               Y==3'b011 ? X<<1   :
               Y==3'b100 ? ~(X<<1):
               Y==3'b101 ? ~X     :
               Y==3'b110 ? ~X     :
                           68'd0;
    assign C = Y==3'b100 || Y==3'b101 || Y==3'b110;

endmodule

module wallace_16(
    input  [13:0] cin,
    input  [16:0] data_in,
    output [13:0] cout,
    output        C,
    output        S
);
    wire B1_2, A1_2, C1_3, B1_3, A1_3, A2_0, C2_1, B2_1, A2_1, B3_1, A3_1, A4_0, B4_0, A5_0;

    function [1:0] Add_1;
        input A, B, CIN;
        begin
          Add_1 = A + B + CIN;
        end
    endfunction

    assign {cout[ 0], B1_2} = Add_1(data_in[ 4], data_in[ 3], data_in[ 2]),
           {cout[ 1], A1_2} = Add_1(data_in[ 7], data_in[ 6], data_in[ 5]),
           {cout[ 2], C1_3} = Add_1(data_in[10], data_in[ 9], data_in[ 8]),
           {cout[ 3], B1_3} = Add_1(data_in[13], data_in[12], data_in[11]),
           {cout[ 4], A1_3} = Add_1(data_in[16], data_in[15], data_in[14]),
           {cout[ 5], A2_0} = Add_1(    cin[ 2],     cin[ 1],     cin[ 0]),
           {cout[ 6], C2_1} = Add_1(data_in[ 0],     cin[ 4],     cin[ 3]),
           {cout[ 7], B2_1} = Add_1(       A1_2,        B1_2, data_in[ 1]),
           {cout[ 8], A2_1} = Add_1(       A1_3,        B1_3,        C1_3),
           {cout[ 9], B3_1} = Add_1(       A2_0,     cin[ 6],     cin[ 5]),
           {cout[10], A3_1} = Add_1(       A2_1,        B2_1,        C2_1),
           {cout[11], B4_0} = Add_1(    cin[ 9],     cin[ 8],     cin[ 7]),
           {cout[12], A4_0} = Add_1(       A3_1,        B3_1,     cin[10]),
           {cout[13], A5_0} = Add_1(       A4_0,        B4_0,     cin[11]),
           {C       , S   } = Add_1(       A5_0,     cin[13],     cin[12]);

endmodule