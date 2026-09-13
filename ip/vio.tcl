# ============================================================
# VIO
# ============================================================

set PROJECT_DIR "$env(VIVADO_FOLDER)/Neural_Processor"
set BUILD_DIR   "$PROJECT_DIR/build"

create_ip \
    -name vio \
    -vendor xilinx.com \
    -library ip \
    -version 3.0 \
    -module_name vio_0


set_property -dict [list \
    CONFIG.C_NUM_PROBE_IN         {0} \
    CONFIG.C_NUM_PROBE_OUT        {1} \
    CONFIG.C_PROBE_OUT0_WIDTH     {1} \
    CONFIG.C_PROBE_OUT0_INIT_VAL  {0x1} \
] [get_ips vio_0]


set VIO_XCI \
    "$BUILD_DIR/local_project.srcs/sources_1/ip/vio_0/vio_0.xci"


# ============================================================
# Generate IP
# ============================================================

generate_target all [get_files "$VIO_XCI"]

update_compile_order -fileset sources_1


# ============================================================
# IP synthesis
# ============================================================

catch {
    config_ip_cache -export [get_ips vio_0]
}

export_ip_user_files \
    -of_objects [get_files "$VIO_XCI"] \
    -no_script \
    -sync \
    -force \
    -quiet

create_ip_run [get_files "$VIO_XCI"]

launch_runs vio_0_synth_1 -jobs 6


# ============================================================
# Simulation files
# ============================================================

export_simulation \
    -of_objects [get_files "$VIO_XCI"] \
    -directory "$BUILD_DIR/local_project.ip_user_files/sim_scripts" \
    -ip_user_files_dir "$BUILD_DIR/local_project.ip_user_files" \
    -ipstatic_source_dir "$BUILD_DIR/local_project.ip_user_files/ipstatic" \
    -lib_map_path [list \
        "modelsim=$BUILD_DIR/local_project.cache/compile_simlib/modelsim" \
        "questa=$BUILD_DIR/local_project.cache/compile_simlib/questa" \
        "riviera=$BUILD_DIR/local_project.cache/compile_simlib/riviera" \
        "activehdl=$BUILD_DIR/local_project.cache/compile_simlib/activehdl" \
    ] \
    -use_ip_compiled_libs \
    -force \
    -quiet
