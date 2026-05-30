`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/26/2026 09:36:05 PM
// Design Name:
// Module Name: avr_rms_sums_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
////////////////////////////////////////////////////////////////////////////////


module avr_rms_sums_sim();
    logic start, clk, rst, data_available;
    logic [13:0] data_in;
    logic [9:0] N;
    logic [11:0] mean;
    logic [13:0]rms;
    logic done;

    // Control state machine logic
    typedef enum {
        IDLE,
        SETUP,
        PRO_0, PRO_1, PRO_2,
        DIV_1, DIV_2,
        NEWTON_N, NEWTON_1, NEWTON_2, NEWTON_3, NEWTON_4, NEWTON_F, NEWTON_D,
        DONE } state_e;

    logic [13:0] data_in_held;
    logic [10:0] data_counter, data_range;
    state_e current_state, next_state;

    always_comb begin
        next_state = current_state;
        // We can use default: next_state = next_state.next;
        unique case (current_state)
        IDLE: if (start) next_state = SETUP;
        SETUP: next_state = PRO_0;
        PRO_0: if (data_available) next_state = PRO_1;
        PRO_1: next_state = PRO_2;
        PRO_2: next_state = data_counter == data_range ? DIV_1 : PRO_0;
        DIV_1: next_state = DIV_2;
        DIV_2: next_state = NEWTON_N;
        NEWTON_N:
            next_state = newton_in[23] || newton_in == '0 ? NEWTON_1 : NEWTON_N;
        NEWTON_1: next_state = NEWTON_2;
        NEWTON_2: next_state = NEWTON_3;
        NEWTON_3: next_state = NEWTON_4;
        NEWTON_4:
            if (newton_guess[16:6] == mul_res[40:29]) next_state = NEWTON_F;
            else next_state = NEWTON_1;
        NEWTON_F: next_state = NEWTON_D;
        NEWTON_D: next_state = DONE;
        DONE: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) current_state <= IDLE;
        else current_state <= next_state;
    end

    always_ff @(posedge clk) begin
        if (rst) data_in_held <= '0;
        else if (data_available) data_in_held <= data_in;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            data_range <= '0;
            data_counter <= '0;
        end else if (current_state == SETUP) begin
            // @todo check if it should be 7 or 8
            if (N < 1016) data_range <= N + 7;
            else data_range <= 1023;
            data_counter <= '0;
        end else if (current_state == PRO_2)
            data_counter <= data_counter + 1;
    end
    ///////////////////////////////////////////////////////////////////////////
    // Mean and RMS
    logic [23:0] internal_mean_sum; //U12.12
    logic [37:0] internal_rms_sum;  //U14.24

    // DSP48E1 25x18 signed multiplication
    logic [23:0] mul_0;     // 24 bits
    logic [16:0] mul_1;     // 17 bits
    logic [40:0] mul_res;   // 41 bits

    // Basys 3 up to 48 bits inputs
    logic [37:0] sum_0;     // 38 bits
    logic [27:0] sum_1;     // 28 bits
    logic [37:0] sum_res;   // 38 bits

    // sum and mul logic a bit down, to add DIV and NEWTON's logic
    always_ff @(posedge clk) begin
        if (rst || current_state == SETUP) begin
            internal_mean_sum <= '0;
            internal_rms_sum <= '0;
        end else if (current_state == PRO_1) begin
            internal_mean_sum <= sum_res[23:0];
        end else if (current_state == PRO_2) begin
            internal_rms_sum <= sum_res[37:0];
        end else if (current_state == DIV_1) begin
            // U12.12 (24 bits) x U0.19 = 2.31 -> U2.10
            internal_mean_sum <= {'0, mul_res[32:21]};
        end else if (current_state == DIV_2) begin
            // U14.10 (24 bits) x U0.19 = 4.29 -> U4.20
            newton_in <= mul_res[32:9];
        end
    end

    ///////////////////////////////////////////////////////////////////////////

    // Division
    // Initialize LUT
    localparam DENOM_WIDTH = 16;
    logic [DENOM_WIDTH-1:0] div_lut[1024];
    initial $readmemh("denom_division.mem", div_lut);
    logic [DENOM_WIDTH:0] denominator; // U0.17 -> really a U0.19 (implicit 00)

    always_ff @(posedge clk) begin
        if (rst) denominator <= '0;
        else if (current_state == SETUP) denominator <= {(N == 0), div_lut[N]};
    end

    ///////////////////////////////////////////////////////////////////////////

    // Newton
    logic [16:0] initial_guess_lut[64];
    initial $readmemh("newton_initial_guess.mem", initial_guess_lut);
    logic [23:0] newton_in;             // U4.20 -> U0.24
    logic [4:0] normalized_right_shift;
    logic denormalized_right_shift;

    logic left_shift;
    assign left_shift = normalized_right_shift < 4;

    logic [16:0] newton_guess;      // Using U.1.16 because of dsp limitations
    logic [23:0] newton_next_guess; // Using 24 bits (U.2.22)

    always_ff @(posedge clk) begin
        if (rst) begin
            newton_in <= '0;
            normalized_right_shift <= '0;
            newton_guess <= '0;
            newton_next_guess <= '0;
        end else if (current_state == SETUP) begin
            newton_in <= '0;
            normalized_right_shift <= '0;
            newton_guess <= '0;
            newton_next_guess <= '0;
        end else if (current_state == NEWTON_N) begin
            if (!newton_in[23]) begin
                newton_in <= newton_in << 1;
                normalized_right_shift <= normalized_right_shift + 1;
            end else begin
                denormalized_right_shift <= left_shift;
                normalized_right_shift <= left_shift ?
                    4 - normalized_right_shift : normalized_right_shift - 4;
                newton_guess <= initial_guess_lut[newton_in[22:17]];
            end
        end else if (current_state == NEWTON_1) begin
            // xn^2 -> U1.16 x U1.16 -> U2.32 => U2.22
            newton_next_guess <= mul_res[33:10];
        end else if (current_state == NEWTON_2) begin
            // U2.22->2.15 x U0.24 -> U2.39 => U2.22 // @todo check overload
            newton_next_guess <= mul_res[40:17];
        end else if (current_state == NEWTON_3) begin
            // newton_next_guess <= 24'hc00000 + (~newton_next_guess) + 1;
            newton_next_guess <= sum_res[23:0];
        end else if (current_state == NEWTON_4) begin
            // newton_guess x newton_next_guess
            // U1.16 x U2.22 -> U3.38 => U2.16 -> U1.16
            newton_guess <= mul_res[40:23];// >> 1;
        end else if (current_state == NEWTON_F) begin
            // U0.24 * U1.16 -> U1.40 => U1.16
            newton_guess <= mul_res[40:24];
        end else if (current_state == NEWTON_D) begin
            // U1.16 x U2.22 -> U3.38 => U2.12
            // U1.16 x U2.16 -> U3.32 => U2.12
            newton_guess <= mul_res[33:20];
        end
    end

    ///////////////////////////////////////////////////////////////////////////

    // Sum
    // sum_0 -> 38 bits
    // sum_1 -> 28 bits
    // sum_res -> 38 bits
    always_comb begin
        case (current_state)
        PRO_1: begin
            sum_0 = {'0, internal_mean_sum};
            sum_1 = {'0, data_in_held};
        end PRO_2: begin
            sum_0 = internal_rms_sum;
            sum_1 = {'0, data_in_held_squared};
        end NEWTON_3: begin
            sum_0 = {'0, ~newton_next_guess}; // Negative value ~val + 1
            sum_1 = {'0, 24'hc00001};
        end default: begin
            sum_0 = '0;
            sum_1 = '0;
        end endcase

        sum_res = sum_0 + sum_1;
    end

    localparam SQRT_2 = 17'h16a09;  // U1.16
    localparam ONE = 17'h10000;     // U1.16
    // Mult
    // mul_0 -> 24 bits
    // mul_1 -> 17 bits
    always_comb begin
        case (current_state)
        PRO_1: begin
            mul_0 = {'0, data_in_held};
            mul_1 = {'0, data_in_held};
        end DIV_1: begin
            mul_0 = {'0, internal_mean_sum};    // U12.12 (24 bits)
            mul_1 = {'0, denominator};          // U0.18 using only 16 (bits)
        end DIV_2: begin
            mul_0 = internal_rms_sum[37:14];    // U14.24 => U14.10 (24 bits)
            mul_1 = {'0, denominator};          // U0.18 using only 16 (bits)
        end NEWTON_1: begin // xn^2
            mul_0 = {'0, newton_guess};
            mul_1 = newton_guess;
        end NEWTON_2: begin // xn^2 * X
            mul_0 = newton_in;
            mul_1 = newton_next_guess[23:7];        // U2.22->2.15
        end NEWTON_4: begin // xn(3- xn^2 * X)
            mul_0 = newton_next_guess;
            mul_1 = newton_guess;
        end NEWTON_F: begin // xn * X (xn = 1/sqrt(X))
            mul_0 = newton_in;
            mul_1 = newton_guess;
        end NEWTON_D: begin
            // mul_0 = {'0, newton_guess, 2'b00} >> (normalized_right_shift >> 1);
            mul_0 = denormalized_right_shift ?
                {'0, newton_guess} >> (normalized_right_shift >> 1) :
                {'0, newton_guess} << (normalized_right_shift >> 1) ;
            mul_1 = (normalized_right_shift & 1) ? SQRT_2: ONE;
        end default: begin
            mul_0 = '0;
            mul_1 = '0;
        end endcase

        mul_res = mul_0 * mul_1;
    end

    logic [27:0] data_in_held_squared;  // U2.12^2 => U4.24
    always_ff @(posedge clk) begin
        if (rst) data_in_held_squared <= '0;
        else if (current_state == PRO_1) data_in_held_squared <= mul_res[27:0];
        else data_in_held_squared <= '0;
    end

    ///////////////////////////////////////////////////////////////////////////

    // Done
    always_comb begin
        done = current_state == DONE;
        if (done) begin
            mean = internal_mean_sum[11:0];
            rms = newton_guess[13:0];
        end else begin
            mean = '0;
            rms = '0;
        end
    end
    ///////////////////////////////////////////////////////////////////////////
    // Simulation
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    localparam n = 47;
    logic [13:0] mem[100];
    // initial $readmemh("100_ones_in_q2.12.mem", mem);
    initial $readmemh("100_sinusoidal.mem", mem);

    initial begin
        #3 rst = 1;
        #2 rst = 0;

        #4 N = n-8;
        #1 start = 1;
        #2 start = 0;
        #2 N = 0;

        for (int i = 0; i < n; i = i + 1) begin
            #16 data_available = 1; data_in = mem[i];
            #2 data_available = 0; data_in = 0;
        end
    end
endmodule
