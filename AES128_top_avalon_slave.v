module AES128_top_avalon_slave (
    input  wire        iClk,
    input  wire        iReset_n,

    // Avalon-MM Slave interface (active-low control signals)
    input  wire        iChipSelect_n,   // Active low
    input  wire        iWrite_n,        // Active low
    input  wire        iRead_n,         // Active low
    input  wire [3:0]  iAddress,
    input  wire [31:0] iData,
    output reg  [31:0] oData
);

    // ===== Internal Registers =====
    reg [127:0] datain_reg;
    reg [127:0] cipherkey_reg;
    reg [127:0] dataout_reg;
    reg         start_reg;
    reg         done_reg;               // <- thêm thanh ghi giữ trạng thái done
    wire [127:0] dataout_wire;
    wire         done_wire;

    // ===== AES128 Core Instance =====
    AES128_top u_aes (
        .clk(iClk),
        .rst(~iReset_n),
        .start(start_reg),
        .datain(datain_reg),
        .cipherkey(cipherkey_reg),
        .dataout(dataout_wire),
        .done(done_wire)
    );

    // ===== Write logic =====
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            datain_reg     <= 128'd0;
            cipherkey_reg  <= 128'd0;
            start_reg      <= 1'b0;
        end else begin
            // Tu dong clear start sau 1 chu ky
            if (start_reg)
                start_reg <= 1'b0;

            if (!iChipSelect_n && !iWrite_n) begin
                case (iAddress)
                    4'd0: datain_reg[31:0]      <= iData;
                    4'd1: datain_reg[63:32]     <= iData;
                    4'd2: datain_reg[95:64]     <= iData;
                    4'd3: datain_reg[127:96]    <= iData;
                    4'd4: cipherkey_reg[31:0]   <= iData;
                    4'd5: cipherkey_reg[63:32]  <= iData;
                    4'd6: cipherkey_reg[95:64]  <= iData;
                    4'd7: cipherkey_reg[127:96] <= iData;
                    4'd8: start_reg             <= iData[0];  // Bit 0: Start signal
                    default: ;
                endcase
            end
        end
    end

    // ===== Ghi du lieu ma hoa khi done = 1 =====
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n)
            dataout_reg <= 128'd0;
        else if (done_wire)
            dataout_reg <= dataout_wire;
    end

    // ===== Giữ trạng thái DONE =====
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n)
            done_reg <= 1'b0;
        else if (done_wire)
            done_reg <= 1'b1; // giữ trạng thái done
        else if (!iChipSelect_n && !iRead_n && iAddress == 4'd9)
            done_reg <= 1'b0; // clear khi phần mềm đọc
    end

    // ===== Read logic =====
    always @(posedge iClk or negedge iReset_n) begin
        if (!iReset_n) begin
            oData <= 32'd0;
        end else if (!iChipSelect_n && !iRead_n) begin
            case (iAddress)
                4'd0: oData <= dataout_reg[31:0];
                4'd1: oData <= dataout_reg[63:32];
                4'd2: oData <= dataout_reg[95:64];
                4'd3: oData <= dataout_reg[127:96];
                4'd9: oData <= {31'd0, done_reg}; // Bit 0 = done (da duoc giu lai)
                default: oData <= 32'd0;
            endcase
        end
    end

endmodule
