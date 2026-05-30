`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/29/2026 11:30:34 PM
// Design Name:
// Module Name: visualization_thread
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


module visualization_thread(input logic clk,
                                        rst,
                                        done, //señal termino calculo de métricas
                            input logic [13:0] min,
                                               max,
                                               mean,
                                               rms,
                            input logic [1:0] sw,
                            output logic [11:0] result //CONVERSION: multiplicacion *1000
                            );

    typedef enum {DISPLAY,
                  READ,
                  NORMALIZE_1,
                  NORMALIZE_2,
                  NORMALIZE_3} state_e;
    state_e current_state, next_state;

    always_comb begin
        next_state = current_state;
        case (current_state)
        DISPLAY: if (done) next_state = NORMALIZE_0;
        NORMALIZE_0: next_state = NORMALIZE_1;
        NORMALIZE_1: next_state = NORMALIZE_2;
        NORMALIZE_2: next_state = NORMALIZE_3;
        NORMALIZE_3: next_state = DISPLAY;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) current_state <= DISPLAY;
        else current_state <= next_state;
    end

    localparam min_init = 0;
    localparam max_init = 1;
    localparam mean_init = 2;
    localparam rms_init = 3;
    logic [13:0] internal_min = min_init,
                 internal_max = max_init,
                 internal_mean = mean_init,
                 internal_rms = rms_init;

    always_ff @(posedge clk) begin
        if (rst) begin
            internal_min <= min_init;
            internal_max <= max_init;
            internal_mean <= mean_init;
            internal_rms <= rms_init;
        end else if (current_state == DISPLAY && done) begin
            internal_min <= min;
            internal_max <= max;
            internal_mean <= mean;
            internal_rms <= rms;
        end else if (current_state == NORMALIZE_0) begin
            internal_min <= mul_res >> 12;
        end else if (current_state == NORMALIZE_1) begin
            internal_max <= mul_res >> 12;
        end else if (current_state == NORMALIZE_2) begin
            internal_mean <= mul_res >> 12;
        end else if (current_state == NORMALIZE_3) begin
            internal_rms <= mul_res >> 12;
        end
    end

    logic [13:0] mul_0;
    logic [25:0] mul_res;

    always_comb begin
        case (current_state)
        NORMALIZE_0: mul_0 = internal_min;
        NORMALIZE_1: mul_0 = internal_max;
        NORMALIZE_2: mul_0 = internal_mean;
        NORMALIZE_3: mul_0 = internal_rms;
        default: mul_0 = '0;
        endcase

        mul_res = mul_0 * 10'd1000;
    end

    always_comb begin
        if (current_state == DISPLAY) begin
            case (sw)
            2'b00: result = internal_min;
            2'b01: result = internal_max;
            2'b10: result = internal_mean;
            2'b11: result = internal_rms;
            endcase
        end else result = 0;
    end
endmodule : visualization_thread
