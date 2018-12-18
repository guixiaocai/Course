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