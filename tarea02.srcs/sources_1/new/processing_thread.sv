`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/21/2026 01:43:27 PM
// Design Name:
// Module Name: processing_thread
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


module processing_thread (
    input logic start,
                clk,
                rst,
                data_available,
    input logic [13:0] data_in,
    input logic [9:0] N,
    output logic [13:0] min,
                        max,
                        mean,
                        rms,
    output logic done
    );

    // Control state machine logic
    typedef enum { IDLE, SETUP, PRO_0, PRO_1, PRO_2, DIV_1, DIV_2, DIV_3, NEWTON, DONE } state_e;

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
        DIV_2: next_state = DIV_3;
        DIV_3: next_state = NEWTON;
        NEWTON: next_state = DONE;
        DONE: next_state = IDLE;
        endcase
    end


    always_ff @(posedge clk) begin
        if (rst) current_state = IDLE;
        else current_state = next_state;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            data_range <= '0;
            data_counter <= '0;
        end else if (current_state == SETUP) begin
            // @todo check if it should be 7 or 8
            if (N < 8) data_range <= 7; // at least 8 data
            else data_range <= N;
            data_counter <= '0;
        end else if (current_state == PRO_1)
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
            cmp_0 = data_in;
            cmp_1 = minimum;
        end else if (current_state == PRO_2) begin
            cmp_0 = ~data_in;
            cmp_1 = ~maximum;
        end

        cmp_res = cmp_0 < cmp_1;
    end

    always_ff @(posedge clk) begin
        if (rst || current_state == SETUP) begin
            minimum <= '1;
            maximum <= '0;
        end else if (current state == PRO_1 && cmp_res) begin
            minimum <= data_in;
        end else if (current state == PRO_2 && cmp_res) begin
            maximum <= data_in;
        end
    end
    ///////////////////////////////////////////////////////////////////////////
    
    // Mean and RMS
    logic [23:0] mean;
    logic [25:0] rms;

    logic [27:0] mul_0;
    logic [17:0] mul_1;
    logic [45:0] mul_res;

    logic [25:0] sum_0;
    logic [17:0] sum_1;
    logic [25:0] sum_res;

    // sum and mul logic a bit down, to add DIV and NEWTON's logic
    always_ff @(posedge clk) begin
        if (rst || current_state == SETUP) begin
            mean <= '0;
            rms <= '0;
        end else if (current_state == PRO_1)
            mean <= sum_res[23:0];
        else if (current_state == PRO_2)
            rms <= sum_res;
    end
    ///////////////////////////////////////////////////////////////////////////

    // Division
endmodule
