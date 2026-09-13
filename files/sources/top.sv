`timescale 1ns/1ps

module top
#(
    //======================================
    // UART parameters
    //======================================
    parameter integer FREQ       = 100_000_000,
    parameter integer BAUDRATE   = 57600,
    parameter integer RATIO      = 8,
    parameter integer PARITY_BIT = 0,
    parameter integer STOP_BIT   = 0,

    //======================================
    // Project path
    //======================================
    parameter string PR_DIR = "D:/Projects/Vivado_Projects"
)
(
    //======================================
    // Системные сигналы
    //======================================
    input  logic i_clk,

    //======================================
    // UART
    //======================================
    input  logic i_uart_rx,
    output logic o_uart_tx
);

    //======================================
    // Reset from VIO
    //======================================
    logic reset;
    logic reset_n;

    (* DONT_TOUCH = "yes" *) assign reset_n = ~reset;

    `ifndef SIMULATION
    (* DONT_TOUCH = "yes" *) vio_0 vio_inst
    (
        .clk        (i_clk),
        .probe_out0 (reset)
    );
    `endif //SIMULATION

    //======================================
    // UART RX AXI-Stream
    //======================================
    logic       rx_tvalid;
    logic [7:0] rx_tdata;
    logic       rx_tready;


    //======================================
    // UART TX AXI-Stream
    //======================================
    logic       tx_tvalid;
    logic [7:0] tx_tdata;
    logic       tx_tready;

    //======================================
    // Neural network
    //======================================
    logic [63:0][4:0] pixels;
    logic             pixels_valid;

    logic [3:0] neuron_result;
    logic       neuron_done;

    //======================================
    // UART Controller
    //======================================
    UART_CONTROLLER
    #(
        .FREQ       (FREQ),
        .BAUDRATE   (BAUDRATE),
        .RATIO      (RATIO),
        .PARITY_BIT (PARITY_BIT),
        .STOP_BIT   (STOP_BIT)
    )
    uart_controller_inst
    (
        .clk      (i_clk),
        .rst_n    (reset_n),

        .rx       (i_uart_rx),
        .tx       (o_uart_tx),

        .m_tvalid (rx_tvalid),
        .m_tdata  (rx_tdata),
        .m_tready (rx_tready),

        .s_tvalid (tx_tvalid),
        .s_tdata  (tx_tdata),
        .s_tready (tx_tready)
    );

    //======================================
    // Pixel Collector
    //======================================
    pixel_collector pixel_collector_inst
    (
        .i_clk         (i_clk),
        .i_rst         (reset),

        .s_axis_tdata  (rx_tdata),
        .s_axis_tvalid (rx_tvalid),
        .s_axis_tready (rx_tready),

        .o_pixels      (pixels),
        .o_valid       (pixels_valid),

        .i_done        (neuron_done)
    );

    //======================================
    // Neural Network
    //======================================
    neuron_net
    #(
        .PR_DIR (PR_DIR)
    )
    neuron_net_inst
    (
        .i_clk   (i_clk),
        .i_rst   (reset),
        .i_x     (pixels),
        .i_valid (pixels_valid),
        .o_y     (neuron_result),
        .o_done  (neuron_done)
    );

    //======================================
    // Result Sender
    //======================================
    result_sender result_sender_inst
    (
        .i_clk         (i_clk),
        .i_rst         (reset),

        .i_result      (neuron_result),
        .i_done        (neuron_done),

        .m_axis_tdata  (tx_tdata),
        .m_axis_tvalid (tx_tvalid),
        .m_axis_tready (tx_tready)
    );

endmodule
