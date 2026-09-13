`timescale 1ns/1ps

module pixel_collector
(
    // Системные сигналы
    input  logic             i_clk,
    input  logic             i_rst,

    // AXI-Stream от UART RX
    input  logic [7:0]       s_axis_tdata,
    input  logic             s_axis_tvalid,
    output logic             s_axis_tready,

    // К neuron_net
    output logic [63:0][4:0] o_pixels,
    output logic             o_valid,

    // neuron_net закончил обработку
    input  logic             i_done
);

    logic [5:0] pixel_cnt;
    logic       busy;

    assign s_axis_tready = !busy;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            pixel_cnt <= '0;
            o_pixels  <= '0;
            o_valid   <= 1'b0;
            busy      <= 1'b0;
        end else begin
            o_valid <= 1'b0;
            if (s_axis_tvalid && s_axis_tready) begin
                o_pixels[pixel_cnt] <= s_axis_tdata[4:0];
                if (pixel_cnt == 6'd63) begin
                    pixel_cnt <= '0;
                    o_valid   <= 1'b1;
                    busy      <= 1'b1;
                end else begin
                    pixel_cnt <= pixel_cnt + 1'b1;
                end
            end

            if (busy && i_done) begin
                busy <= 1'b0;
            end
        end
    end

endmodule
