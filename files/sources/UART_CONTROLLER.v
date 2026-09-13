`timescale 1ps / 1ps

//===========================================================
// File Path: D:/Projects/Vivado_Projects/UART_Controller/files/sources/UART_CONTROLLER.v
// Author: Kudryashov D.S.
// Created On: 2026-06-15 11:56:50
// Description: Top level source
// BAUDRATE must be: 300, 600, 1200, 1800, 2400, 3600, 4800, 7200, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400, 460800, 921600.
// FREQ >= BAUDRATE * RATIO.
// RATIO must be: 8, 16, 32.
// PARITY_BIT must be: 0 - off, 1 - odd, 2 - even.
// STOP_BIT must be: 0 - 1 stop bit, 1 - 2 stop bits.
//===========================================================


module UART_CONTROLLER
#(
    parameter FREQ       = 100_000_000,
    parameter BAUDRATE   = 9600,
    parameter RATIO      = 8,
    parameter PARITY_BIT = 0,
    parameter STOP_BIT   = 0
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // Uart signals
    input  wire rx,
    output wire tx,
    
    // AXI4-Stream interface
    output wire       m_tvalid,
    output wire [7:0] m_tdata,
    input  wire       m_tready,
    
    input  wire       s_tvalid,
    input  wire [7:0] s_tdata,
    output wire       s_tready
);

    //-------------------> RX_SYNCHRONIZER
    wire rx_sync;
    
    RX_SYNCHRONIZER rx_synchronizer
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n),
        // RX signals
        .rx(rx),
        .rx_sync(rx_sync)
    );
    
    //-------------------> SAMPLE_CE_GEN
    wire sample_ce;
    
    SAMPLE_CE_GEN
    #(
        .FREQ(FREQ),
        .BAUDRATE(BAUDRATE),
        .RATIO(RATIO)
    )
    sample_ce_gen
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n),
        // Sample CE
        .sample_ce(sample_ce)
    );
    
    //-------------------> RX_SAMPLE_COUNTER
    wire rx_ce;
    wire rx_rst;
    
    RX_SAMPLE_COUNTER 
    #(
        .RATIO(RATIO)
    )
    rx_sample_counter
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n),
        // Sample Clock Enable
        .sample_ce(sample_ce),
        // RX_FSM signals
        .rx_rst(rx_rst), 
        .rx_ce(rx_ce)
    );
    
    //-------------------> TX_SAMPLE_COUNTER
    wire tx_ce;
    wire tx_rst;
    
    TX_SAMPLE_COUNTER
    #(
        .RATIO(RATIO)
    )
    tx_sample_counter
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n),
        // Sample Clock Enable
        .sample_ce(sample_ce),
        // TX_FSM signals
        .tx_rst(tx_rst), 
        .tx_ce(tx_ce)
    );
    
    //-------------------> RX_FSM
    RX_FSM
    #(
        .PARITY_BIT(PARITY_BIT),
        .STOP_BIT(STOP_BIT)
    )
    rx_fsm
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n),
        // RX_SAMPLE_COUNTER signals
        .rx_ce(rx_ce),
        .rx_rst(rx_rst),
        // RX_SYNCHRONIZER signal
        .rx_sync(rx_sync),
        // AXI4-Stream interface
        .m_tvalid(m_tvalid),
        .m_tdata(m_tdata),
        .m_tready(m_tready)
    );
    
    //-------------------> TX_FSM
    TX_FSM
    #(
        .PARITY_BIT(PARITY_BIT),
        .STOP_BIT(STOP_BIT)
    )
    tx_fsm
    (
        // System signals
        .clk(clk),
        .rst_n(rst_n), 
        // TX_SAMPLE_COUNTER signals
        .tx_ce(tx_ce),
        .tx_rst(tx_rst),
        // External signal
        .tx(tx),
        // AXI4-Stream interface
        .s_tvalid(s_tvalid),
        .s_tdata(s_tdata),
        .s_tready(s_tready)
    );
    
endmodule
