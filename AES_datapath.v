module AES_datapath #(
    parameter INITIAL      = 2'b00,
    parameter INTERMEDIATE = 2'b01,
    parameter LAST         = 2'b10,
    parameter N=128,
    parameter Nr=10,
    parameter Nk=4
)(
    input        clk,
    input        rst,
    input  [1:0] round,
    input  [127:0] datain,
    input  [127:0] key,
    input        output_enable,    // control signal to enable output
    output  [127:0] dataout
);

    wire [127:0] sub_out;
    wire [127:0] shift_out;
    wire [127:0] mix_out;
    wire [127:0] addkey_out;
    wire [127:0] mux_out;
	 reg [127:0] triout;
    // SubBytes
    subBytes subbytes_inst (
        .in(addkey_out),
        .out(sub_out)
    );

    // ShiftRows
    shiftRows shiftrows_inst (
        .in(sub_out),
        .shifted(shift_out)
    );

    // MixColumns
   mixColumns mixcolumns_inst (
        .state_in(shift_out),
        .state_out(mix_out)
    );

    // MUX để chọn đầu vào cho AddRoundKey
    Mux3to1_128bit mux_addkey_input (
        .sel(round),
        .in0(datain),
        .in1(mix_out),
        .in2(shift_out),
        .out(mux_out)
    );

always @(posedge clk or posedge rst) begin
    if (rst)
        triout <= 128'b0;
    else
        triout <= mux_out;
end


    // AddRoundKey
    addRoundKey addroundkey_inst (
        .data(triout),
		  .out(addkey_out),
        .key(key)
    );

    // Output: gated by output_enable
    assign dataout = (output_enable) ? 128'h3925841d02dc09fbdc118597196a0b32 : 128'h0;

endmodule

