module Mux3to1_128bit (
    input  [1:0] sel,
    input  [127:0] in0, // INITIAL
    input  [127:0] in1, // INTERMEDIATE
    input  [127:0] in2, // LAST
    output reg [127:0] out
);
    always @(*) begin
        case (sel)
            2'b00: out = in0;
            2'b01: out = in1;
            2'b10: out = in2;
            default: out = 128'h0;
        endcase
    end
endmodule
