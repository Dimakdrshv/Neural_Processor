`timescale 1ns/1ps

module neuron_net
#(
    parameter string PR_DIR = "D:/Projects/Vivado_Projects"
)
(
    // Системные сигналы
    input  logic             i_clk      ,
    input  logic             i_rst      ,

    //Сигналы взаимодействия с другими модулями системы
    input  logic [63:0][4:0] i_x        , // Входные значения для нейрона
    input  logic             i_valid    , // Валидность входных данных
    output logic [3:0]       o_y        , // Выходное число (ответ системы)
    output logic             o_done       // Валидность выходных даных
);

    //======================================
    // Дополнительные параметры модуля
    //======================================
    localparam int unsigned FIRST_LAYER_NEURONS  = 8;
    localparam int unsigned SECOND_LAYER_NEURONS = 10;

    localparam int unsigned FIRST_LAYER_INPUTS   = 64;
    localparam int unsigned SECOND_LAYER_INPUTS  = 8;

    localparam int unsigned H_SHIFT = 7;

    //======================================
    // Дополнительные регистры модуля
    //======================================
    logic [63:0][4:0] x;
    logic signed [7:0] h [FIRST_LAYER_NEURONS];

    logic signed [7:0] h_selected;

    logic [5:0] x_idx;   // 0...63
    logic [2:0] h_idx;   // 0...7

    logic signed [31:0] layer2_out [SECOND_LAYER_NEURONS];

    logic signed [31:0] max_value;
    logic        [3:0]  argmax;
    logic        [3:0]  argmax_idx;

    //======================================
    // FSM Регистры
    //======================================
    logic [2:0] state;
    localparam ST_IDLE     = 0,
               ST_LAYER1   = 1,
               ST_L1_OUT   = 2,
               ST_L2_LOAD  = 3,
               ST_LAYER2   = 4,
               ST_ARGMAX   = 5,
               ST_RESULT   = 6;

    //======================================
    // Функция relu с квантизацией
    //======================================
    function automatic logic signed [7:0] requant_relu(input logic signed [31:0] value);
        logic signed [31:0] scaled;
        begin
            if (value <= 0) begin
                requant_relu = 8'sd0;
            end else begin
                scaled = (value + 32'sd64) >>> H_SHIFT;
                if (scaled > 127)
                    requant_relu = 8'sd127;
                else
                    requant_relu = scaled[7:0];
            end
        end
    endfunction

    //======================================
    // Генерация первого слоя
    //======================================
    genvar i;
    generate
        for (i = 0; i < FIRST_LAYER_NEURONS; i++) begin : gen_l1
            logic signed [7:0] w1 [FIRST_LAYER_INPUTS];
            logic signed [31:0] b1 [1];
            (* use_dsp = "yes" *) logic signed [31:0] acc1;
            logic signed [7:0] h1;

            initial begin
                $readmemh($sformatf("%s/Neural_Processor/files/sources/W1_%0d.mem", PR_DIR, i), w1);
                $readmemh($sformatf("%s/Neural_Processor/files/sources/B1_%0d.mem", PR_DIR, i), b1);
            end

            assign h[i] = h1;

            always_ff @(posedge i_clk) begin
                if (i_rst) begin
                    acc1 <= '0;
                    h1   <= '0;
                end else begin
                    if ((state == ST_IDLE) && i_valid) begin
                        acc1 <= b1[0];
                    end else if (state == ST_LAYER1) begin
                        acc1 <=
                            acc1
                            +
                            $signed({1'b0, x[x_idx]})
                            *
                            $signed(w1[x_idx]);
                    end else if (state == ST_L1_OUT) begin
                        h1 <= requant_relu(acc1);
                    end
                end
            end
        end
    endgenerate

    //======================================
    // Генерация второго слоя
    //======================================
    generate
        for (i = 0; i < SECOND_LAYER_NEURONS; i++) begin : gen_l2
            logic signed [7:0]  w2 [SECOND_LAYER_INPUTS];
            logic signed [31:0] b2 [1];

            logic signed [7:0]  w2_selected;
            logic        [2:0]  w_idx;

            (* use_dsp = "yes" *) logic signed [31:0] acc2;
            logic signed [31:0] y2;

            initial begin
                $readmemh($sformatf("%s/Neural_Processor/files/sources/W2_%0d.mem", PR_DIR, i), w2);
                $readmemh($sformatf("%s/Neural_Processor/files/sources/B2_%0d.mem", PR_DIR, i), b2);
            end

            assign layer2_out[i] = y2;

            always_ff @(posedge i_clk) begin
                if (i_rst) begin
                    acc2 <= '0;
                    y2   <= '0;
                end else begin
                    if (state == ST_L1_OUT) begin
                        acc2 <= b2[0];
                        w_idx <= '0;
                    end else if (state == ST_L2_LOAD) begin
                        w2_selected <= w2[w_idx];
                    end else if (state == ST_LAYER2) begin
                        if (h_idx == SECOND_LAYER_INPUTS-1) begin
                            y2 <=
                                acc2
                                +
                                $signed(h_selected)
                                *
                                $signed(w2_selected);
                        end else begin
                            acc2 <=
                                acc2
                                +
                                $signed(h_selected)
                                *
                                $signed(w2_selected);

                            w_idx <= w_idx + 1'b1;
                        end
                    end
                end
            end
        end
    endgenerate

    //======================================
    // Регистрация h
    //======================================
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            h_selected <= '0;
        end
        else if (state == ST_L2_LOAD) begin
            h_selected <= h[h_idx];
        end
    end

    //======================================
    // Управляющая FSM
    //======================================
    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            state <= ST_IDLE;
            x  <= '0;
            x_idx <= '0;
            h_idx <= '0;
            max_value <= '0;
            argmax <= '0;
            argmax_idx <= '0;
            o_y <= '0;
            o_done <= '0;
        end else begin
            o_done <= 1'b0;

            case (state)
                // ------------------------------------------------
                // Ожидание нового изображения
                // ------------------------------------------------
                ST_IDLE: begin
                    if (i_valid) begin
                        x <= i_x;
                        x_idx <= '0;
                        state <= ST_LAYER1;
                    end
                end

                // ------------------------------------------------
                // Первый слой
                // ------------------------------------------------
                ST_LAYER1: begin
                    if (x_idx == FIRST_LAYER_INPUTS-1) begin
                        state <= ST_L1_OUT;
                    end else begin
                        x_idx <= x_idx + 1'b1;
                    end
                end

                // ------------------------------------------------
                // Выход первого слоя
                // ------------------------------------------------
                ST_L1_OUT: begin
                    h_idx <= '0;
                    state <= ST_L2_LOAD;
                end

                // ------------------------------------------------
                // Загрузка второго слоя
                // ------------------------------------------------
                ST_L2_LOAD: begin
                    state <= ST_LAYER2;
                end

                // ------------------------------------------------
                // Второй слой
                // ------------------------------------------------
                ST_LAYER2: begin
                    if (h_idx == SECOND_LAYER_INPUTS-1) begin
                        argmax_idx <= '0;
                        state <= ST_ARGMAX;
                    end else begin
                        h_idx <= h_idx + 1'b1;
                        state <= ST_L2_LOAD;
                    end
                end

                // ------------------------------------------------
                // Argmax
                // ------------------------------------------------
                ST_ARGMAX: begin
                    if (argmax_idx == 0) begin
                        max_value <= layer2_out[0];
                        argmax <= 4'd0;
                        argmax_idx <= 4'd1;
                    end else begin
                        if (layer2_out[argmax_idx] > max_value) begin
                            max_value <= layer2_out[argmax_idx];
                            argmax    <= argmax_idx;
                        end
                        if (argmax_idx == SECOND_LAYER_NEURONS-1) begin
                            state <= ST_RESULT;
                        end else begin
                            argmax_idx <= argmax_idx + 1'b1;
                        end
                    end
                end

                // ------------------------------------------------
                // Result
                // ------------------------------------------------
                ST_RESULT: begin
                    o_y    <= argmax;
                    o_done <= 1'b1;
                    state  <= ST_IDLE;
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
