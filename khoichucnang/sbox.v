module sbox (
    input  wire [7:0] a,
    output wire [7:0] c
);

    // Function: Multiply two 2-bit values in GF(2^2)
    function [1:0] mulGf22;
        input [1:0] a, b;
        begin
            mulGf22[1] = (a[1] & b[1]) ^ (a[0] & b[1]) ^ (a[1] & b[0]);
            mulGf22[0] = (a[1] & b[1]) ^ (a[0] & b[0]);
        end
    endfunction

    // Function: Multiply two 4-bit values in GF(2^4)
    function [3:0] mulGf24;
        input [3:0] a, b;
        reg [1:0] a_msb, a_lsb, b_msb, b_lsb;
        reg [1:0] a_xor, b_xor;
        reg [1:0] msb_mul, xor_mul, lsb_mul, xPhi;
        begin
            a_msb = a[3:2]; a_lsb = a[1:0];
            b_msb = b[3:2]; b_lsb = b[1:0];
            a_xor = a_msb ^ a_lsb;
            b_xor = b_msb ^ b_lsb;
            msb_mul = mulGf22(a_msb, b_msb);
            xor_mul = mulGf22(a_xor, b_xor);
            lsb_mul = mulGf22(a_lsb, b_lsb);
            xPhi[1] = msb_mul[1] ^ msb_mul[0];
            xPhi[0] = msb_mul[1];
            mulGf24[3:2] = xor_mul ^ lsb_mul;
            mulGf24[1:0] = xPhi ^ lsb_mul;
        end
    endfunction

    // Function: Affine transformation
    function [7:0] affine;
        input [7:0] in;
        begin
            affine[0] = in[0] ^ in[4] ^ in[5] ^ in[6] ^ in[7] ^ 1'b1;
            affine[1] = in[0] ^ in[1] ^ in[5] ^ in[6] ^ in[7] ^ 1'b1;
            affine[2] = in[0] ^ in[1] ^ in[2] ^ in[6] ^ in[7];
            affine[3] = in[0] ^ in[1] ^ in[2] ^ in[3] ^ in[7];
            affine[4] = in[0] ^ in[1] ^ in[2] ^ in[3] ^ in[4];
            affine[5] = in[1] ^ in[2] ^ in[3] ^ in[4] ^ in[5] ^ 1'b1;
            affine[6] = in[2] ^ in[3] ^ in[4] ^ in[5] ^ in[6] ^ 1'b1;
            affine[7] = in[3] ^ in[4] ^ in[5] ^ in[6] ^ in[7];
        end
    endfunction

    // Function: GF(2^8) multiplicative inverse
    function [7:0] mulGf28Inv;
        input [7:0] in;
        reg [7:0] iso;
        reg [3:0] msb, lsb, sq, xL, xorBranch, lsb_xor;
        reg [3:0] lsb_mul, inv;
        reg [7:0] inv_input;
        begin
            // Isomorphic mapping
            iso[7] = in[7] ^ in[5];
            iso[6] = in[7] ^ in[6] ^ in[4] ^ in[3] ^ in[2] ^ in[1];
            iso[5] = in[7] ^ in[5] ^ in[3] ^ in[2];
            iso[4] = in[7] ^ in[5] ^ in[3] ^ in[2] ^ in[1];
            iso[3] = in[7] ^ in[6] ^ in[2] ^ in[1];
            iso[2] = in[7] ^ in[4] ^ in[3] ^ in[2] ^ in[1];
            iso[1] = in[6] ^ in[4] ^ in[1];
            iso[0] = in[6] ^ in[1] ^ in[0];
            msb = iso[7:4];
            lsb = iso[3:0];

            // Square
            sq[3] = msb[3];
            sq[2] = msb[3] ^ msb[2];
            sq[1] = msb[2] ^ msb[1];
            sq[0] = msb[3] ^ msb[1] ^ msb[0];

            // x Lambda
            xL[3] = sq[2] ^ sq[0];
            xL[2] = sq[3] ^ sq[2] ^ sq[1] ^ sq[0];
            xL[1] = sq[3];
            xL[0] = sq[2];

            lsb_xor = msb ^ lsb;
            lsb_mul = mulGf24(lsb_xor, lsb);
            xorBranch = xL ^ lsb_mul;

            // Inversion in GF(2^4)
            case (xorBranch)
                4'h0: inv = 4'h0;
                4'h1: inv = 4'h1;
                4'h2: inv = 4'h3;
                4'h3: inv = 4'h2;
                4'h4: inv = 4'hF;
                4'h5: inv = 4'hC;
                4'h6: inv = 4'h9;
                4'h7: inv = 4'hB;
                4'h8: inv = 4'hA;
                4'h9: inv = 4'h6;
                4'hA: inv = 4'h8;
                4'hB: inv = 4'h7;
                4'hC: inv = 4'h5;
                4'hD: inv = 4'hE;
                4'hE: inv = 4'hD;
                4'hF: inv = 4'h4;
                default: inv = 4'hx;
            endcase

            inv_input[7:4] = mulGf24(msb, inv);
            inv_input[3:0] = mulGf24(lsb_xor, inv);

            // Inverse isomorphic mapping
            mulGf28Inv[7] = inv_input[7] ^ inv_input[6] ^ inv_input[5] ^ inv_input[1];
            mulGf28Inv[6] = inv_input[6] ^ inv_input[2];
            mulGf28Inv[5] = inv_input[6] ^ inv_input[5] ^ inv_input[1];
            mulGf28Inv[4] = inv_input[6] ^ inv_input[5] ^ inv_input[4] ^ inv_input[2] ^ inv_input[1];
            mulGf28Inv[3] = inv_input[5] ^ inv_input[4] ^ inv_input[3] ^ inv_input[2] ^ inv_input[1];
            mulGf28Inv[2] = inv_input[7] ^ inv_input[4] ^ inv_input[3] ^ inv_input[2] ^ inv_input[1];
            mulGf28Inv[1] = inv_input[5] ^ inv_input[4];
            mulGf28Inv[0] = inv_input[6] ^ inv_input[5] ^ inv_input[4] ^ inv_input[2] ^ inv_input[0];
        end
    endfunction

    // S-box logic
    wire [7:0] inv_result;
    assign inv_result = mulGf28Inv(a);
    assign c = affine(inv_result);

endmodule

