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
    logic [13:0] mean, rms;
    logic done;

    // Control state machine logic
    typedef enum {
        IDLE,
        SETUP,
        PRO_0, PRO_1, PRO_2,
        DIV_1, DIV_2,
        NEWTON_N, NEWTON_1, NEWTON_2, NEWTON_3, NEWTON_4, NEWTON_D,
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
        NEWTON_N: next_state = NEWTON_1;
        NEWTON_1: next_state = NEWTON_2;
        NEWTON_2: next_state = NEWTON_3;
        NEWTON_3: next_state = NEWTON_4;
        NEWTON_4: next_state = NEWTON_D;
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
    logic [23:0] internal_mean; //U12.12
    logic [25:0] internal_rms;  //U14.12

    // DSP48E1 25x18 signed multiplication
    logic [23:0] mul_0; // 24 bits
    logic [16:0] mul_1; // 17 bits
    logic [40:0] mul_res;

    logic [24:0] sum_0;
    logic [17:0] sum_1;
    logic [25:0] sum_res;

    // sum and mul logic a bit down, to add DIV and NEWTON's logic
    always_ff @(posedge clk) begin
        if (rst || current_state == SETUP) begin
            internal_mean <= '0;
            internal_rms <= '0;
        end else if (current_state == PRO_1) begin
            internal_mean <= sum_res[23:0];
        end else if (current_state == PRO_2) begin
            internal_rms <= sum_res;
        end else if (current_state == DIV_1) begin
            // U12.12 (24 bits) x U0.18 = U2.12
            internal_mean <= {'0, mul_res[40:19]};     // @todo check the slices
        end else if (current_state == DIV_2) begin
            // 4x12 = 14.12 x 0.19
            // U14.10 (24 bits) x U0.18 = U14.28 leave -> U2.12
            internal_rms <= {'0, mul_res[40:17]};      // @todo check the slices
        end
    end

    ///////////////////////////////////////////////////////////////////////////

    // Division
    // Initialize LUT
    localparam DENOM_WIDTH = 16;
    logic [DENOM_WIDTH-1:0] div_lut[1024];
    initial $readmemh("denom_division.mem", div_lut);
    logic [DENOM_WIDTH:0] denominator;

    always_ff @(posedge clk) begin
        if (rst) denominator <= '0;
        else if (current_state == SETUP) denominator <= {(N == 0), div_lut[N]};
    end

    ///////////////////////////////////////////////////////////////////////////

    // Newton
    // logic [15:0] guess, next_guess;
    // logic [5:0] newton_first_guess;

    // always_comb begin
    //     newton_first_guess = '0;
    //     if (current_state == NEWTON_N) begin
    //         if ('0 == )
    //     end
    // end
    ///////////////////////////////////////////////////////////////////////////

    // Sum
    always_comb begin
        case (current_state)
        PRO_1: begin
            sum_0 = {'0, internal_mean};
            sum_1 = {'0, data_in_held};
        end PRO_2: begin
            sum_0 = internal_rms;
            sum_1 = {'0, data_in_held_squared};
        // end NEWTON_4: begin
        //     sum_0 = {'0, ~newton_next_guess + 1};
        //     sum_1 = 2'd3;
        end default: begin
            sum_0 = '0;
            sum_1 = '0;
        end endcase

        sum_res = sum_0 + sum_1;
    end

    // Mult
    always_comb begin
        case (current_state)
        PRO_1: begin
            mul_0 = {'0, data_in_held};
            mul_1 = {'0, data_in_held};
        end DIV_1: begin
            mul_0 = {'0, internal_mean};    // U12.12 (24 bits)
            mul_1 = {'0, denominator};      // U0.18 using only 16 (bits)
        end DIV_2: begin
            mul_0 = internal_rms[25:2];     // U14.12 => U14.10 (24 bits)
            mul_1 = {'0, denominator};      // U0.18 using only 16 (bits)
        // end NEWTON_1: begin
        //     mul_0 = {'0, newton_guess};
        //     mul_1 = {'0, newton_guess};
        // end NEWTON_2: begin
        //     mul_0 = {'0, newton_guess};
        //     mul_1 = {'0, newton_target};
        // end NEWTON_4: begin
        //     mul_0 = {'0, newton_guess};
        //     mul_1 = {'0, newton_next_guess};
        end default: begin
            mul_0 = '0;
            mul_1 = '0;
        end endcase

        mul_res = mul_0 * mul_1;
    end

    logic [15:0] data_in_held_squared;
    always_ff @(posedge clk) begin
        if (rst) data_in_held_squared <= '0;
        else if (current_state == PRO_1) data_in_held_squared <= mul_res[27:12];
        else data_in_held_squared <= '0;
    end
    ///////////////////////////////////////////////////////////////////////////

    // Done
    always_comb begin
        done = current_state == DONE;
        if (done) begin
            mean = internal_mean;
            rms = internal_rms;
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

    localparam n = 7;
    logic [13:0] mem[100];
    // initial $readmemh("100_ones_in_q2.12.mem", mem);
    initial $readmemh("100_sinusoidal.mem", mem);

    initial begin
        #3 rst = 1;
        #2 rst = 0;

        #4 N = n;
        #1 start = 1;
        #2 start = 0;
        #2 N = 0;

        for (int i = 0; i < n + 8; i = i + 1) begin
            #16 data_available = 1; data_in = mem[i];
            #2 data_available = 0; data_in = 0;
        end
    end
endmodule
