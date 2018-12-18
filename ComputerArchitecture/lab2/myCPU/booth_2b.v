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