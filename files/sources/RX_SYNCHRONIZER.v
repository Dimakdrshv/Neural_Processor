`timescale 1ps / 1ps

//===========================================================
// File Path: D:/VivadoProjects/UART_Controller/files/sources/RX_SYNCHRONIZER.v
// Author: Kudryashov D.S.
// Created On: 2026-06-03 20:02:45
// Description: external RX signal is async -> make it sync
//===========================================================


module RX_SYNCHRONIZER
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // RX signals
    input  wire rx,
    output reg  rx_sync
);

    reg sync_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg <= 1'b1;
            rx_sync  <= 1'b1;
        end else begin
            sync_reg <= rx;
            rx_sync  <= sync_reg;
        end
    end
    
endmodule
