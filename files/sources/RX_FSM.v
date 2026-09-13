`timescale 1ps / 1ps

//===========================================================
// File Path: D:/Projects/Vivado_Projects/UART_Controller/files/sources/RX_FSM.v
// Author: Kudryashov D.S.
// Created On: 2026-06-14 14:15:05
// Description: RX fsm
//===========================================================


module RX_FSM
#(
    parameter PARITY_BIT = 0,
    parameter STOP_BIT = 0
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // RX_SAMPLE_COUNTER signals
    input  wire rx_ce,
    output reg  rx_rst,
    
    // RX_SYNCHRONIZER signal
    input wire rx_sync,
    
    // AXI4-Stream interface
    output reg       m_tvalid,
    output reg [7:0] m_tdata,
    input  wire      m_tready
);
    
    // Additional regs
    reg [7:0] rx_data;
    reg [2:0] rx_counter;
    
    // FSM states
    reg [2:0] state;
    
    localparam WSB   = 0,
               SBR   = 1,
               DBR   = 2,
               PBR   = 3,
               STBR1 = 4,
               STBR2 = 5,
               TIB   = 6;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Internal regs
            rx_data    <= {(8){1'b0}};
            rx_rst     <= 1'b1;
            rx_counter <= {(3){1'b0}};
            // AXI4-Stream interface regs
            m_tvalid <= 1'b0;
            m_tdata  <= {(8){1'b0}};
            // State reg
            state <= WSB;
        end else begin
            case (state)
                WSB: begin
                    if (!rx_sync) begin
                        rx_rst <= 1'b0;
                        state  <= SBR;
                    end else begin
                        state <= WSB;
                    end
                end
                
                SBR: begin
                    if (rx_ce) begin
                        if (!rx_sync) begin
                            state <= DBR;
                        end else begin
                            rx_rst <= 1'b1;
                            state  <= WSB;
                        end
                    end else begin
                        state <= SBR;
                    end
                end
                
                DBR: begin
                    if (rx_ce) begin
                        rx_data    <= {rx_sync, rx_data[7:1]};
                        rx_counter <= rx_counter + 1'b1;
                        if (&rx_counter) begin
                            state <= PARITY_BIT == 0 ? STBR1 : PBR;
                        end else begin
                            state <= DBR;
                        end
                    end else begin
                        state <= DBR;
                    end
                end
                
                PBR: begin
                    if (rx_ce && PARITY_BIT == 1) begin
                        if (rx_sync == ~(^rx_data)) begin
                            state <= STBR1;
                        end else begin
                            rx_rst <= 1'b1;
                            state  <= WSB;
                        end
                    end else if (rx_ce && PARITY_BIT == 2) begin
                        if (rx_sync == (^rx_data)) begin
                            state <= STBR1;
                        end else begin
                            rx_rst <= 1'b1;
                            state  <= WSB;
                        end
                    end else begin
                        state <= PBR;
                    end
                end
                
                STBR1: begin
                    if (rx_ce) begin
                        if (rx_sync) begin
                            state    <= STOP_BIT == 0 ? TIB : STBR2;
                            m_tdata  <= STOP_BIT == 0 ? rx_data : {(8){1'b0}};
                            m_tvalid <= STOP_BIT == 0 ? 1'b1 : 1'b0;
                        end else begin
                            rx_rst <= 1'b1;
                            state  <= WSB;
                        end
                    end else begin
                        state <= STBR1;
                    end
                end
                
                STBR2: begin
                    if (rx_ce) begin
                        if (rx_sync) begin
                            state    <= TIB;
                            m_tdata  <= rx_data;
                            m_tvalid <= 1'b1;
                        end else begin
                            rx_rst <= 1'b1;
                            state  <= WSB;
                        end
                    end else begin
                        state <= STBR2;
                    end
                end
                
                TIB: begin
                    if (m_tready) begin
                        m_tvalid <= 1'b0;
                        m_tdata  <= {(8){1'b0}};
                        state    <= WSB;
                        rx_rst   <= 1'b1;
                    end else begin
                        state <= TIB;
                    end
                end
            endcase
        end
    end
    
endmodule
