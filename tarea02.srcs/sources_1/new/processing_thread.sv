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

    typedef enum { IDLE, SETUP, PROCESSING, DIVIDING, NEWTON, DONE } state_e;

    state_e current_state, next_state;

    always_comb begin
        next_state = current_state;
        // We can use default: next_state = next_state.next;
        unique case (current_state)
        IDLE: if (start) next_state = SETUP;
        SETUP: next_state = PROCESSING;
        PROCESSING: if (state_counter == data_range) next_state = DIVIDING;
        DIVIDING: next_state = NEWTON;
        NEWTON: next_state = DONE;
        DONE: next_state = IDLE;
        endcase
    end



endmodule
