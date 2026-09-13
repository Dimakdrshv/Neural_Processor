`timescale 1ns/1ps

module neuron_net_tb
#(
    parameter string PR_DIR = "D:/Projects/Vivado_Projects"
);

    //==========================================================
    // Параметры
    //==========================================================
    localparam int DATASET_SIZE = 360; // Изменять
    localparam int IMAGE_SIZE   = 64;

    // ========================================================
    // DUT signals
    // ========================================================
    logic             i_clk;
    logic             i_rst;
    logic [63:0][4:0] i_x;
    logic             i_valid;
    logic [3:0]       o_y;
    logic             o_done;

    // ========================================================
    // DUT
    // ========================================================
    neuron_net
    #(
        .PR_DIR(PR_DIR)
    )
    dut
    (
        .i_clk   (i_clk),
        .i_rst   (i_rst),
        .i_x     (i_x),
        .i_valid (i_valid),
        .o_y     (o_y),
        .o_done  (o_done)
    );

    //==========================================================
    // Dataset
    // Все изображения хранятся одним плоским массивом.
    //==========================================================
    logic [4:0] dataset_x [DATASET_SIZE*IMAGE_SIZE];
    logic [3:0] dataset_y [DATASET_SIZE];

    initial begin
        $readmemh($sformatf("%s/Neural_Processor/files/simulations/digits_x.mem", PR_DIR), dataset_x);
        $readmemh($sformatf("%s/Neural_Processor/files/simulations/digits_y.mem", PR_DIR), dataset_y);
    end

    //==========================================================
    // Clock
    //==========================================================
    initial begin
        i_clk = 1'b0;
        forever
            #5 i_clk = ~i_clk;
    end

    //==========================================================
    // Переменные теста
    //==========================================================
    int image;
    int pixel;
    int correct;
    int errors;
    real accuracy;

    //==========================================================
    // Test
    //==========================================================
    initial begin
        i_rst   = 1'b1;
        i_valid = 1'b0;
        i_x     = '0;
        correct = 0;
        errors  = 0;

        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------
        repeat (5)
            @(posedge i_clk);

        @(negedge i_clk);
        i_rst = 1'b0;

        // -----------------------------------------------------
        // Проходим по всему датасету
        // -----------------------------------------------------
        for (image = 0; image < DATASET_SIZE; image++) begin
            // -------------------------------------------------
            // Загружаем 64 пикселя изображения
            // -------------------------------------------------
            for (pixel = 0; pixel < IMAGE_SIZE; pixel++) begin
                i_x[pixel] =
                    dataset_x[
                        image * IMAGE_SIZE + pixel
                    ];
            end
            // -------------------------------------------------
            // Запускаем нейросеть
            // -------------------------------------------------
            @(negedge i_clk);
            i_valid = 1'b1;
            @(negedge i_clk);
            i_valid = 1'b0;

            // -------------------------------------------------
            // Ждём окончания inference
            // -------------------------------------------------
            wait (o_done === 1'b1);

            // -------------------------------------------------
            // Проверяем результат
            // -------------------------------------------------
            if (o_y == dataset_y[image]) begin
                correct = correct + 1;
            end else begin
                errors = errors + 1;
            end

            // -------------------------------------------------
            // Progress
            // -------------------------------------------------
            if (((image + 1) % 100) == 0) begin
                $display(
                    "Processed %0d / %0d",
                    image + 1,
                    DATASET_SIZE
                );
            end
            @(posedge i_clk);
        end

        //======================================================
        // Итоговая accuracy
        //======================================================
        accuracy = 100.0 * correct / DATASET_SIZE;
        $display("");
        $display("========================================");
        $display("RTL NEURAL NETWORK TEST");
        $display("========================================");
        $display("Images:   %0d", DATASET_SIZE);
        $display("Correct:  %0d", correct);
        $display("Errors:   %0d", errors);
        $display("Accuracy: %.4f%%", accuracy);
        $display("========================================");
        $finish;
    end



endmodule
