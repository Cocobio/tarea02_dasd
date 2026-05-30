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


module visualization_thread( input logic clk,
                                         rst,
                                         done, //señal termino calculo de métricas
                            input logic [13:0] min,
                                               max,
                                               mean,
                                               rms,
                                               sw,
                            output logic [11:0] result //CONVERSION: multiplicacion *1000
                            );

    //DEFINICION DE ESTADOS
    typedef enum logic{SELECT, //PARA VER EN QUE COMB DE SW COMIENZA
                       CONVERT} //SEPARAR VALORES PARA DISPLAY
     state_t ;
     state_t state , next_state ;

    logic [13:0] valor_ing; //valor_ingresado a convertir

    //TRANSICION DE ESTADOS
    always_ff@(posedge clk)begin
    if(done == 1)
        state <= next_state;
    end

    //ELEGIR SIGUIENTE ESTADO
    always_comb begin
        case(state)
            SELECT: next_state = CONVERT;
            CONVERT: next_state = SELECT;
        endcase
    end


    //QUE HACER EN CADA ESTADO
    always_ff@(posedge clk)begin
        case(state)
        SELECT: begin
            case(sw) //QUE VALOR INGRESAR CON CADA SWITCH
                2'b00: valor_ing <= min;
                2'b01: valor_ing <= max;
                2'b10: valor_ing <= mean;
                2'b11: valor_ing <= rms;
            endcase
        end

        CONVERT: begin //MULTIPLICAR POR 1000 PARA CONVERTIR
            result <= (valor_ing * 1000) >> 12;
        end
        endcase
    end
endmodule : visualization_thread
