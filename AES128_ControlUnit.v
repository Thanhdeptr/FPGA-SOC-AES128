// Control Unit FSM for AES-128 datapath (no enable signals)
// Generates round state and done signal only
// Assumes 10 rounds (0 = initial AddRoundKey, 1-9 = intermediate, 10 = last)

module AES128_ControlUnit (
    input              clk,
    input              rst,
    input              start,
    input       [127:0]cipherkey,          // start signal
    output reg  [1:0]  round,          // 00: INITIAL, 01: INTERMEDIATE, 10: LAST
    output reg         done,
    output   [127:0]key           // high when finished
);

    // FSM state encoding
    parameter IDLE   = 2'b00;
    parameter BUSY   = 2'b01;
    parameter DONE_S = 2'b10;

    reg [1:0] current_state, next_state;

    // Round counter (0 to 10)
    reg [3:0] round_cnt; // needs 4 bits to count to 10

    // State transition
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            round_cnt     <= 4'd0;
        end else begin
            current_state <= next_state;
            if (current_state == BUSY) begin
                round_cnt <= round_cnt + 1'b1;
            end else if (current_state == IDLE && start) begin
                round_cnt <= 4'd0;
            end
        end
    end

    // Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start) begin
                    next_state = BUSY;
                end
            end
            BUSY: begin
                if (round_cnt == 4'd10) begin
                    next_state = DONE_S;
                end
            end
            DONE_S: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output logic
    always @(*) begin
        round          = 2'b00;
        done           = 1'b0;

        case (current_state)
            IDLE: begin
                round = 2'b00;
                done  = 1'b0;
            end
            BUSY: begin

                if (round_cnt == 4'd0) begin
                    round = 2'b00; // INITIAL
                end else if (round_cnt == 4'd10) begin
                    round = 2'b10;
                    done = 1'b1; // LAST
                end else begin
                    round = 2'b01;
                    done = 1'b0; // INTERMEDIATE
                end
            end
            DONE_S: begin
                done = 1'b0;
            end
        endcase
    end

keyExpansion ks(cipherkey,round_cnt,key);

endmodule
