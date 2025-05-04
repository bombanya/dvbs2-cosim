# Based on script from https://github.com/rick-heig/zynq7-cosim

# Script to compile the CoSimulation files

# Compile C files (not SystemC) for libremote-port
sccom -x c -fPIC -g ./libsystemctlm-soc/libremote-port/safeio.c
# The following file was patched to solve issues (maybe a flag would have fixed them too) TODO : Check this out
sccom -x c -fPIC -g ./libsystemctlm-soc/libremote-port/remote-port-proto.c
# The following file was patched to solve issues
sccom -x c -fPIC -g ./libsystemctlm-soc/libremote-port/remote-port-sk.c

# Lib Remote Port (RP) SystemC files
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm-memory-master.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm-memory-slave.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm-wires.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm-memory-master.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./libsystemctlm-soc/libremote-port/remote-port-tlm-memory-slave.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ ./questa/scrambler.cc
sccom -g -I./libsystemctlm-soc/libremote-port/ -I./libsystemctlm-soc/ -I./libsystemctlm-soc/tlm-bridges/ ./questa/stream_adapter.cc

# Link (systemc.so)
sccom -link 

vlog ./questa/dvbs_top.v
