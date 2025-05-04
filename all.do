# Main script for QuestaSim
do questa-res/compile_cosim.do
do questa-res/compile_vhdl.do
vsim -gui -vopt -voptargs=+acc dvbs_top
