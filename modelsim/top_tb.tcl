# =======================================================================
# Neural Processor TOP simulation
# source $env(VIVADO_FOLDER)/Neural_Processor/modelsim/top_tb.tcl
# =======================================================================
set PR_DIR "$env(VIVADO_FOLDER)"

# =======================================================================
# UART Controller
# =======================================================================
vlog -sv "$PR_DIR/Neural_Processor/files/sources/RX_SYNCHRONIZER.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/SAMPLE_CE_GEN.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/RX_SAMPLE_COUNTER.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/TX_SAMPLE_COUNTER.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/RX_FSM.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/TX_FSM.v"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/UART_CONTROLLER.v"

# =======================================================================
# Neural Processor RTL
# =======================================================================
vlog -sv "$PR_DIR/Neural_Processor/files/sources/pixel_collector.sv"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/result_sender.sv"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/neuron_net.sv"
vlog -sv "$PR_DIR/Neural_Processor/files/sources/top.sv"
vlog -sv +define+SIMULATION \
    "$PR_DIR/Neural_Processor/files/sources/top.sv"

# =======================================================================
# Testbench
# =======================================================================
vlog -sv "$PR_DIR/Neural_Processor/files/simulations/top_tb_pkg.sv"
vlog -sv "$PR_DIR/Neural_Processor/files/simulations/top_tb_if.sv"
vlog -sv "$PR_DIR/Neural_Processor/files/simulations/top_tb.sv"

# =======================================================================
# Запуск симуляции
# =======================================================================
vsim -gPR_DIR="$PR_DIR" work.top_tb

# =======================================================================
# Wave
# =======================================================================
add wave -position end sim:/top_tb/dut/*

# =======================================================================
# Run
# =======================================================================
run -all
