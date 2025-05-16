
module keyExpansion #(parameter nk=4,parameter nr=10)(key,counter,w_out);
// The first [(nk*32)-1 ]-bit key that we use to generate the rest of the keys of the other rounds.
// [(nk*32)-1 ] is the key length (128-bit key, 192-bit key or 256-bit key for nK=4,6 or 8 respectively).
input [0 : (nk * 32) - 1] key;  
input [3:0] counter;
// w represents the array that will store all the generated keys of all rounds.
/* [(128 * (nr + 1)) - 1] this formula is meant to calculate the length of W ; so that it can store all the
generated keys of all rounds.*/
output reg [127:0] w_out;
reg [0 : (128 * (nr + 1)) - 1] w;
reg [0:31] temp;
reg [0:31] r;
reg [0:31] rot; // It stores the returned value from the function rotword().
reg [0:31] x;	//It stores the returned value from the function subwordx().
reg [0:31] rconv; //It stores the returned value from the function rconx().
reg [0:31]new;

integer i;
/*
	We generate all the keys needed in the encryption and decryption at the beginning of the encryption or decryption
 and store them, then we use them in the AES_Encrypt and AES_Decrypt modules as needed according to the current 
 round.
*/
/*
 The functions:
 1) subwordx() applies a table lookup to all to all four bytes of the sent word. subwordx() calls the function
	 c() four times, each time it sends to c() 1-byte to perform the table lookup on it.
 2) rconx() contains the values given by [x^(i-1),{00},{00},{00}], with x^(i-1) being powers 
	 of x (x is denoted as {02}) in the field GF(28).
 3) rotword() applies a cyclic shift of the bytes in a word. For example,{09cf4f3c} is changed into {cf4f3c09}
	 after applying this function.
*/

/*
		The pseudo-code of the this algorithm is found in the NIST.pdf attached to the repository with some modification
	in the code to fit with verilog.
*/
/*
		For simplicity, We are going to explain the storing mechanism of the generated keys on an example of
	128-bit key.It would be easy to apply the same concept on 192-bit and 256-bit keys. We would explain it in one 
	round only. The next rounds would perform the same operations.
	
	-The example:
		-Note that in case of 128-bit key w[0:1407].
		
		1) when w=key then w= {1279*{0}:key} where 1279*{0} means that the first 1279 bits are all zero valued
			and the end of the w array contains the current 128-bit key.
		2) when temp = w[(128 * (nr + 1) - 32) +: 32] then temp=w[1376 +:32] so temp in the first round would contain
			the last 32-bit word of the the current key. 
		3) After performing (temp = SubWord(RotWord(temp)) xor Rcon[i/Nk]) or (temp = SubWord(temp)), We would perform
			(new = w[(128*(nr+1)-(nk*32))+:32] ^ temp) which is (new=w[1280+:32] ^ temp) in the first round,
			where w[(128*(nr+1)-(nk*32))+:32] here is equivelent to w[i-Nk] in the pseudo-code. Now we have the new
			generated key word (new) and we need to add it at the end of (W) array.
		4) We would shift W by 32-bit to the left to empty space to the new generated key word.
		5) w = {w[0 : (128 * (nr + 1) - 32) - 1], new} is w={w[0:1375],new} where w now contains w={1247*{0}:key:new} 
			where 1247*{0} means that the first 1247 bits are all zero valued and they are followed by the original 
			128-bit key, which are followed by the new generated 32-bit key.
		6) Repeat this process for the rest of the rounds.At the end of all the rounds we would have all the W array
			filled with all the keys.
	
*/
always@* begin
//The first [(nk*32)-1 ]-bit key is stored in W.
	w = key;    
	for(i = nk; i < 4*(nr + 1); i = i + 1) begin
	temp = w[(128 * (nr + 1) - 32) +: 32];
	if(i % nk == 0) begin
		rot = rotword(temp); // A call to the function rotword() is done and the returned value is stored in rot.
		x = subwordx (rot);	//A call to the function subwordx() is done and the returned value is stored in x.
		rconv = rconx (i/nk); //A call to the function rconx() is done and the returned value is stored in rconv.
		temp = x ^ rconv;   
	end
	else if(nk >6 && i % nk == 4) begin
		temp = subwordx(temp);
	end
	new = (w[(128*(nr+1)-(nk*32))+:32] ^ temp);
	// We would shift W by 32 bit to the left to add the new generated key word (new) at its end.
	w = w << 32;
	w = {w[0 : (128 * (nr + 1) - 32) - 1], new};
	if (counter < 11) begin
        w_out = get_w_block(w, counter);
    end
end

end

function [127:0] get_w_block;
    input [1407:0] w;
    input [3:0] index; // tá»« 0 Äáº¿n 10
    begin
        get_w_block = w[1407 - index*128 -: 128];
    end
endfunction


function [0:31] rotword;
input [0:31] x;
begin
		rotword={x[8:31],x[0:7]};
end
endfunction

function [0:31] subwordx;
input [0:31] a;
begin
subwordx[0:7]=c(a[0:7]);
subwordx[8:15]=c(a[8:15]);
subwordx[16:23]=c(a[16:23]);
subwordx[24:31]=c(a[24:31]);
end
endfunction


    function [1:0] mulGf22;
        input [1:0] a, b;
        begin
            mulGf22[1] = (a[1] & b[1]) ^ (a[0] & b[1]) ^ (a[1] & b[0]);
            mulGf22[0] = (a[1] & b[1]) ^ (a[0] & b[0]);
        end
    endfunction
    
    
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
    
function [7:0] c;
    input [7:0] a;

    // Internal functions and regs
    reg [7:0] inv_result;
    reg [7:0] iso, inv_input;
    reg [3:0] msb, lsb, sq, xL, xorBranch, lsb_xor;
    reg [3:0] lsb_mul, inv;


    // --- mulGf28Inv ---
    begin
        iso[7] = a[7] ^ a[5];
        iso[6] = a[7] ^ a[6] ^ a[4] ^ a[3] ^ a[2] ^ a[1];
        iso[5] = a[7] ^ a[5] ^ a[3] ^ a[2];
        iso[4] = a[7] ^ a[5] ^ a[3] ^ a[2] ^ a[1];
        iso[3] = a[7] ^ a[6] ^ a[2] ^ a[1];
        iso[2] = a[7] ^ a[4] ^ a[3] ^ a[2] ^ a[1];
        iso[1] = a[6] ^ a[4] ^ a[1];
        iso[0] = a[6] ^ a[1] ^ a[0];

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

        inv_result[7] = inv_input[7] ^ inv_input[6] ^ inv_input[5] ^ inv_input[1];
        inv_result[6] = inv_input[6] ^ inv_input[2];
        inv_result[5] = inv_input[6] ^ inv_input[5] ^ inv_input[1];
        inv_result[4] = inv_input[6] ^ inv_input[5] ^ inv_input[4] ^ inv_input[2] ^ inv_input[1];
        inv_result[3] = inv_input[5] ^ inv_input[4] ^ inv_input[3] ^ inv_input[2] ^ inv_input[1];
        inv_result[2] = inv_input[7] ^ inv_input[4] ^ inv_input[3] ^ inv_input[2] ^ inv_input[1];
        inv_result[1] = inv_input[5] ^ inv_input[4];
        inv_result[0] = inv_input[6] ^ inv_input[5] ^ inv_input[4] ^ inv_input[2] ^ inv_input[0];

        c = affine(inv_result);
    end
endfunction



function[0:31] rconx;
input [0:31] r; 
begin
 case(r)
    4'h1: rconx=32'h01000000;
    4'h2: rconx=32'h02000000;
    4'h3: rconx=32'h04000000;
    4'h4: rconx=32'h08000000;
    4'h5: rconx=32'h10000000;
    4'h6: rconx=32'h20000000;
    4'h7: rconx=32'h40000000;
    4'h8: rconx=32'h80000000;
    4'h9: rconx=32'h1b000000;
    4'ha: rconx=32'h36000000;
    default: rconx=32'h00000000;
  endcase
  end
endfunction

endmodule