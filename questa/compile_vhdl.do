vmap fpga_cores work

# Compile VHDL files
vcom -2008 -work fpga_cores \
    rtl-lib/third_party/fpga_cores/src/common_pkg.vhd \
    rtl-lib/third_party/fpga_cores/src/interface_types_pkg.vhd \
    rtl-lib/third_party/fpga_cores/src/synchronizer.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_pkg.vhd \
    rtl-lib/third_party/fpga_cores/src/sr_delay.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_flow_control.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_debug.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_frame_slicer.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_frame_padder.vhd \
    rtl-lib/third_party/fpga_cores/src/skidbuffer.vhd \
    rtl-lib/third_party/fpga_cores/src/ram_inference_dport.vhd \
    rtl-lib/third_party/fpga_cores/src/ram_inference.vhd \
    rtl-lib/third_party/fpga_cores/src/rom_inference.vhd \
    rtl-lib/third_party/fpga_cores/src/pipeline_context_ram.vhd \
    rtl-lib/third_party/fpga_cores/src/edge_detector.vhd \
    rtl-lib/third_party/fpga_cores/src/pulse_sync.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_delay.vhd \
    rtl-lib/third_party/fpga_cores/src/sync_fifo.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_credit.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_ram.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_master_adapter.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_replicate.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_fifo.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_frame_fifo.vhd \
    rtl-lib/third_party/fpga_cores/src/async_fifo.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_width_converter.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_mux.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_demux.vhd \
    rtl-lib/third_party/fpga_cores/src/axi_stream_arbiter.vhd 

vmap str_format work

vcom -2008 -work str_format \
    rtl-lib/third_party/hdl_string_format/src/str_format_pkg.vhd \

vcom -2008 -work work \
    rtl-lib/third_party/airhdl/dvbs2_encoder_regs_pkg.vhd \
    rtl-lib/third_party/airhdl/dvbs2_encoder_regs.vhd \
    rtl-lib/third_party/bch_generated/*.vhd \
    rtl-lib/rtl/dvb_utils_pkg.vhd \
    rtl-lib/rtl/ldpc/ldpc_tables_pkg.vhd \
    rtl-lib/rtl/ldpc/ldpc_pkg.vhd \
    rtl-lib/rtl/ldpc/ldpc_input_sync.vhd \
    rtl-lib/rtl/bch_encoder_mux.vhd \
    rtl-lib/rtl/constellation_mapper_pkg.vhd \
    rtl-lib/rtl/axi_ldpc_table.vhd \
    rtl-lib/rtl/axi_ldpc_encoder_core.vhd \
    rtl-lib/rtl/plframe_header_pkg.vhd \
    rtl-lib/rtl/axi_physical_layer_pilots.vhd \
    rtl-lib/rtl/axi_physical_layer_header.vhd \
    rtl-lib/rtl/dummy_frame_generator.vhd \
    rtl-lib/rtl/axi_physical_layer_scrambler.vhd \
    rtl-lib/rtl/*.vhd \
    questa/*.vhd
