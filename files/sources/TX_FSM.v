`timescale 1ps / 1ps

//===========================================================
// File Path: D:/Projects/Vivado_Projects/UART_Controller/files/sources/TX_FSM.v
// Author: Kudryashov D.S.
// Created On: 2026-06-15 09:24:03
// Description: TX fsm
//===========================================================


module TX_FSM
#(
    parameter PARITY_BIT = 0,
    parameter STOP_BIT = 0
)
(
    // System signals
    input wire clk,
    input wire rst_n,
    
    // TX_SAMPLE_COUNTER signals
    input  wire tx_ce,
    output reg  tx_rst,
    
    // External signal
    output reg tx,
    
    // AXI4-Stream interface
    input  wire       s_tvalid,
    input  wire [7:0] s_tdata,
    output reg        s_tready
);
    
    // Additional regs
    reg [7:0] tx_data;
    reg [2:0] tx_counter;
    
    // FSM states
    reg [2:0] state;
    
    localparam WBS   = 0,
               SDB   = 1,
               SPB   = 2,
               SSTB1 = 3,
               SSTB2 = 4,
               PNB   = 5;
    
    initial begin
        tx = 1'b1;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Internal regs
            tx_data    <= {(8){1'b0}};
            tx_rst     <= 1'b1;
            tx_counter <= {(3){1'b0}};
            // External reg
            tx <= 1'b1;
            // AXI4-Stream reg
            s_tready <= 1'b1;
            // FSM state
            state <= WBS;
        end else begin
            case (state)
                WBS: begin
                    if (s_tvalid) begin
                        tx_data  <= s_tdata;
                        s_tready <= 1'b0;
                        tx_rst   <= 1'b0;
                        tx       <= 1'b0;
                        state    <= SDB;
                    end else begin
                        state <= WBS;
                    end
                end
                
                SDB: begin
                    if (tx_ce) begin
                        tx         <= tx_data[tx_counter];
                        tx_counter <= tx_counter + 1'b1;
                        if (&tx_counter) begin
                            state <= PARITY_BIT == 0 ? SSTB1 : SPB;
                        end else begin
                            state <= SDB;
                        end
                    end else begin
                        state <= SDB;
                    end
                end
                
                SPB: begin
                    if (tx_ce) begin
                        if (PARITY_BIT == 1) begin
                            tx <= ~(^tx_data[7:0]);
                        end else if (PARITY_BIT == 2) begin
                            tx <= (^tx_data[7:0]);
                        end
                        state <= SSTB1;
                    end else begin
                        state <= SPB;
                    end
                end
                
                SSTB1: begin
                    if (tx_ce) begin
                        tx <= 1'b1;
                        if (STOP_BIT == 0) begin
                            state <= PNB;
                        end else if (STOP_BIT == 1) begin
                            state <= SSTB2;
                        end
                    end else begin
                        state <= SSTB1;
                    end
                end
                
                SSTB2: begin
                    if (tx_ce) begin
                        tx <= 1'b1;
                        state <= PNB;
                    end else begin
                        state <= SSTB2;
                    end
                end
                
                PNB: begin
                    if (tx_ce) begin
                        tx_rst   <= 1'b1;
                        s_tready <= 1'b1;
                        state    <= WBS;
                    end else begin
                        state <= PNB;
                    end
                end
            endcase
        end
    end

endmodule
