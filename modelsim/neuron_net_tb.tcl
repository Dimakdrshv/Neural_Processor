# =======================================================================
# Neural Processor simulation
# source $env(VIVADO_FOLDER)/Neural_Processor/modelsim/neuron_net_tb.tcl
# =======================================================================

set PR_DIR "$env(VIVADO_FOLDER)"

# Компиляция RTL
vlog -sv "$env(VIVADO_FOLDER)/Neural_Processor/files/sources/neuron_net.sv"

# Компиляция testbench
vlog -sv "$env(VIVADO_FOLDER)/Neural_Processor/files/simulations/neuron_net_tb.sv"

# Передача параметров в Modelsim
vsim -gPR_DIR="$PR_DIR" work.neuron_net_tb

# Запуск симуляции
vsim work.neuron_net_tb

# Добавление сигналов DUT в waveform
add wave -position end sim:/neuron_net_tb/dut/*

# Запуск до $finish
run -all
