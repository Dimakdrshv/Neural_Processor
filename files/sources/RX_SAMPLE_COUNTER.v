`timescale 1ps / 1ps

//===========================================================
// File Path: D:/VivadoProjects/UART_Controller/files/sources/RX_SAMPLE_COUNTER.v
// Author: Kudryashov D.S.
// Created On: 2026-06-03 21:41:46
// Description: rx_ce signal for rx_fsm
//===========================================================


module RX_SAMPLE_COUNTER 
#(
    parameter RATIO = 8
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // Sample Clock Enable
    input wire sample_ce,
    
    // RX_FSM signals
    input  wire rx_rst, 
    output wire rx_ce
);

    localparam CNT_WDT = $clog2(RATIO);
    reg [CNT_WDT - 1 : 0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {(CNT_WDT){1'b0}};
        end else begin
            if (rx_rst) begin
                counter <= {(CNT_WDT){1'b0}};
            end else if (sample_ce) begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    assign rx_ce = (!counter[CNT_WDT - 1]) && (&counter[CNT_WDT - 2 : 0]) && sample_ce;
    
endmodule
