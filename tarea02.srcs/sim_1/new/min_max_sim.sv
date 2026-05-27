`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/25/2026 11:12:38 PM
// Design Name:
// Module Name: min_max_sim
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
///////////////////////////////////////////////////////////////////////////////


module min_max_sim();
    logic start, clk, rst, data_available;
    logic [13:0] data_in;
    logic [9:0] N;
    logic [13:0] min, max;
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
    logic [9:0] data_counter, data_range;
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

    // Min and Max
    logic [13:0] minimum, maximum;
    logic [13:0] cmp_0, cmp_1;
    logic cmp_res;

    // Tie logic to control state machine state
    always_comb begin
        cmp_0 = '0;
        cmp_1 = '0;

        if (current_state == PRO_1) begin
            cmp_0 = data_in_held;
            cmp_1 = minimum;
        end else if (current_state == PRO_2) begin
            cmp_0 = ~data_in_held;
            cmp_1 = ~maximum;
        end

        cmp_res = cmp_0 < cmp_1;
    end

    always_ff @(posedge clk) begin
        if (rst || current_state == SETUP) begin
            minimum <= '1;
            maximum <= '0;
        end else if (current_state == PRO_1 && cmp_res) begin
            minimum <= data_in_held;
        end else if (current_state == PRO_2 && cmp_res) begin
            maximum <= data_in_held;
        end
    end

    // Done
    always_comb begin
        done = current_state == DONE;
        if (done) begin
            min = minimum;
            max = maximum;
        end else begin
            min = '0;
            max = '0;
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
    initial $readmemh("100_shuffle_increasing_data.mem", mem);

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
