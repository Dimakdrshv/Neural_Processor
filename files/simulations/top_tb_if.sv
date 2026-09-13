`timescale 1ns/1ps

interface top_tb_if
#(
    parameter integer BAUDRATE = 1_250_000
);

    // =====================================
    // UART lines
    // =====================================
    logic rx;
    logic tx;

    // =====================================
    // Bit period
    // =====================================
    localparam time BIT_PERIOD = 1s / BAUDRATE;

    // =====================================
    // Initial UART state
    // =====================================
    initial begin
        rx = 1'b1;
    end

    // =====================================
    // Send byte to DUT
    //
    // UART 8N1:
    // start
    // 8 data bits, LSB first
    // stop
    // =====================================
    task automatic send_byte
    (
        input logic [7:0] data
    );
        rx = 1'b0;
        #(BIT_PERIOD);

        for (int i = 0; i < 8; i++) begin
            rx = data[i];
            #(BIT_PERIOD);
        end

        rx = 1'b1;
        #(BIT_PERIOD);
    endtask


    // =====================================
    // Receive byte from DUT
    // =====================================
    task automatic receive_byte
    (
        output logic [7:0] data
    );
        @(negedge tx);
        #(BIT_PERIOD + BIT_PERIOD / 2);

        for (int i = 0; i < 8; i++) begin
            data[i] = tx;
            #(BIT_PERIOD);
        end

        if (tx !== 1'b1) begin
            $display(
                "UART ERROR: invalid stop bit at time %0t",
                $time
            );
        end

    endtask

endinterface
