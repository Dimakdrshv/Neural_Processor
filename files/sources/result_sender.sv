`timescale 1ns/1ps

module result_sender
(
    // Системные сигналы
    input  logic       i_clk,
    input  logic       i_rst,

    // От neuron_net
    input  logic [3:0] i_result,
    input  logic       i_done,

    // AXI-Stream к UART TX
    output logic [7:0] m_axis_tdata,
    output logic       m_axis_tvalid,
    input  logic       m_axis_tready
);

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            m_axis_tdata  <= '0;
            m_axis_tvalid <= 1'b0;
        end else begin
            if (!m_axis_tvalid) begin
                if (i_done) begin
                    m_axis_tdata  <= {4'b0000, i_result};
                    m_axis_tvalid <= 1'b1;
                end
            end else if (m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule
