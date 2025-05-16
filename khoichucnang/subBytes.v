
module subBytes (
    input  wire [127:0] in,
    output wire [127:0] out
);

    // Wires để nhận output từ 16 instance sbox
    wire [7:0] sb [15:0];

    // 16 instance sbox, dùng tên cổng a (input), c (output)
    sbox u0  (.a(in[7:0]),     .c(sb[0]));
    sbox u1  (.a(in[15:8]),    .c(sb[1]));
    sbox u2  (.a(in[23:16]),   .c(sb[2]));
    sbox u3  (.a(in[31:24]),   .c(sb[3]));
    sbox u4  (.a(in[39:32]),   .c(sb[4]));
    sbox u5  (.a(in[47:40]),   .c(sb[5]));
    sbox u6  (.a(in[55:48]),   .c(sb[6]));
    sbox u7  (.a(in[63:56]),   .c(sb[7]));
    sbox u8  (.a(in[71:64]),   .c(sb[8]));
    sbox u9  (.a(in[79:72]),   .c(sb[9]));
    sbox u10 (.a(in[87:80]),   .c(sb[10]));
    sbox u11 (.a(in[95:88]),   .c(sb[11]));
    sbox u12 (.a(in[103:96]),  .c(sb[12]));
    sbox u13 (.a(in[111:104]), .c(sb[13]));
    sbox u14 (.a(in[119:112]), .c(sb[14]));
    sbox u15 (.a(in[127:120]), .c(sb[15]));

    // Kết quả ghép lại thành 128-bit
    assign out = { sb[15], sb[14], sb[13], sb[12],
                            sb[11], sb[10], sb[9],  sb[8],
                            sb[7],  sb[6],  sb[5],  sb[4],
                            sb[3],  sb[2],  sb[1],  sb[0] };

endmodule
