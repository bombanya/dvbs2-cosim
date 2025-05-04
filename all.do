# Main script for QuestaSim
do questa/compile_cosim.do
do questa/compile_vhdl.do
vsim -gui -vopt -voptargs=+acc dvbs_top
