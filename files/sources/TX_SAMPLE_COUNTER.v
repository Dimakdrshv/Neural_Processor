`timescale 1ps / 1ps

//===========================================================
// File Path: D:/VivadoProjects/UART_Controller/files/sources/TX_SAMPLE_COUNTER.v
// Author: Kudryashov D.S.
// Created On: 2026-06-03 22:13:47
// Description: tx_ce signal for tx_fsm
//===========================================================


module TX_SAMPLE_COUNTER
#(
    parameter RATIO = 8
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // Sample Clock Enable
    input wire sample_ce,
    
    // TX_FSM signals
    input  wire tx_rst, 
    output wire tx_ce
);

    localparam CNT_WDT = $clog2(RATIO);
    reg [CNT_WDT - 1 : 0] counter;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {(CNT_WDT){1'b0}};
        end else begin
            if (tx_rst) begin
                counter <= {(CNT_WDT){1'b0}};
            end else if (sample_ce) begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    assign tx_ce = (&counter) && sample_ce;
    
endmodule
