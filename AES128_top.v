module AES128_top (
    input         clk,
    input         rst,
    input         start,
    input  [127:0] datain,
    input  [127:0] cipherkey,
    output [127:0] dataout,
    output        done
);

    wire [1:0]    round;
    wire          output_enable;
    wire [127:0]  key;

    // Connect Control Unit
    AES128_ControlUnit control_unit (
        .clk(clk),
        .rst(rst),
        .start(start),
        .cipherkey(cipherkey),
        .round(round),
        .done(done),
        .key(key)
    );

    // Connect Datapath
    AES_datapath datapath (
        .clk(clk),
        .rst(rst),
        .round(round),
        .datain(datain),
        .key(key),
        .output_enable(done),
        .dataout(dataout)
    );

endmodule

