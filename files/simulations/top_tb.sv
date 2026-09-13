`timescale 1ns/1ps

module top_tb;

    import top_tb_pkg::*;

    // =====================================
    // Project path
    // =====================================
    parameter string PR_DIR =
        "D:/Projects/Vivado_Projects";

    // =====================================
    // Clock
    // =====================================
    logic i_clk;

    initial begin
        i_clk = 1'b0;

        forever
            #5 i_clk = ~i_clk;
    end

    // =====================================
    // UART interface
    // =====================================
    top_tb_if
    #(
        .BAUDRATE (SIM_BAUDRATE)
    )
    uart();

    // =====================================
    // Dataset
    // =====================================
    logic [4:0] dataset_x [DATASET_SIZE*IMAGE_SIZE];
    logic [3:0] dataset_y [DATASET_SIZE];

    initial begin
        $readmemh(
            $sformatf(
                "%s/Neural_Processor/files/simulations/digits_x.mem",
                PR_DIR
            ),
            dataset_x
        );

        $readmemh(
            $sformatf(
                "%s/Neural_Processor/files/simulations/digits_y.mem",
                PR_DIR
            ),
            dataset_y
        );
    end


    // =====================================
    // DUT
    // =====================================
    top
    #(
        .FREQ       (100_000_000),

        // Быстрый UART только для simulation
        .BAUDRATE   (SIM_BAUDRATE),

        .RATIO      (8),
        .PARITY_BIT (0),
        .STOP_BIT   (0),

        .PR_DIR     (PR_DIR)
    )
    dut
    (
        .i_clk      (i_clk),

        .i_uart_rx  (uart.rx),
        .o_uart_tx  (uart.tx)
    );

    // =====================================
    // Test variables
    // =====================================
    logic [7:0] received;

    integer correct;
    integer errors;

    // =====================================
    // Test
    // =====================================
    initial begin
        correct = 0;
        errors  = 0;

        // =================================
        // Reset
        //
        // В hardware reset приходит от VIO.
        // В simulation просто принудительно
        // управляем внутренним reset.
        // =================================

        force dut.reset = 1'b1;

        repeat (10)
            @(posedge i_clk);

        force dut.reset = 1'b0;

        repeat (10)
            @(posedge i_clk);


        // =================================
        // Dataset
        // =================================
        for (
            int image = 0;
            image < DATASET_SIZE;
            image++
        ) begin

            /*
             * ВАЖНО:
             *
             * receive_byte запускаем ПАРАЛЛЕЛЬНО
             * с отправкой изображения.
             *
             * Нейросеть работает намного быстрее UART,
             * поэтому FPGA потенциально может начать
             * отправлять ответ практически сразу после
             * приёма последнего байта.
             *
             * Если начать receive_byte только ПОСЛЕ
             * send_byte(), можно пропустить start bit TX.
             */
            fork
                // -------------------------
                // TX: PC -> FPGA
                // -------------------------
                begin
                    for (
                        int pixel = 0;
                        pixel < IMAGE_SIZE;
                        pixel++
                    ) begin
                        uart.send_byte(
                            {
                                3'b000,
                                dataset_x[
                                    image * IMAGE_SIZE
                                    +
                                    pixel
                                ]
                            }
                        );
                    end
                end

                // -------------------------
                // RX: FPGA -> PC
                // -------------------------
                begin
                    uart.receive_byte(received);
                end
            join

            // =================================
            // Compare
            // =================================
            if (received[3:0] == dataset_y[image]) begin
                correct++;
                $display(
                    "[%0d/%0d] expected=%0d FPGA=%0d OK",
                    image + 1,
                    DATASET_SIZE,
                    dataset_y[image],
                    received[3:0]
                );
            end
            else begin
                errors++;
                $display(
                    "[%0d/%0d] expected=%0d FPGA=%0d ERROR",
                    image + 1,
                    DATASET_SIZE,
                    dataset_y[image],
                    received[3:0]
                );
            end
        end

        // =================================
        // Result
        // =================================
        $display("");
        $display("========================================");
        $display("FULL UART RTL TEST");
        $display("========================================");
        $display(
            "Images:   %0d",
            DATASET_SIZE
        );
        $display(
            "Correct:  %0d",
            correct
        );
        $display(
            "Errors:   %0d",
            errors
        );
        $display(
            "Accuracy: %.4f%%",
            100.0 * correct / DATASET_SIZE
        );
        $display("========================================");
        $finish;
    end

endmodule
