`timescale 1ps / 1ps

//===========================================================
// File Path: D:/VivadoProjects/UART_Controller/files/sources/SAMPLE_CE_GEN.v
// Author: Kudryashov D.S.
// Created On: 2026-06-03 20:09:35
// Description: Clock Enable generator for sample counter
//===========================================================


module SAMPLE_CE_GEN
#(
    parameter FREQ = 100_000_000,
    parameter BAUDRATE = 9600,
    parameter RATIO = 8
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // Sample CE
    output reg sample_ce
);
    
    localparam max_value = FREQ / (BAUDRATE * RATIO);
    reg [$clog2(max_value) - 1 : 0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= {($clog2(max_value)){1'b0}};
            sample_ce <= 1'b0;
        end else begin
            if (counter == max_value - 1) begin
                sample_ce <= 1'b1;
                counter   <= {($clog2(max_value)){1'b0}};
            end else begin
                sample_ce <= 1'b0;
                counter   <= counter + 1'b1;
            end
        end
    end
    
endmodule
