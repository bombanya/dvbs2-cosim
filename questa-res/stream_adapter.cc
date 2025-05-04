/*
 * Copyright (c) 2025 Nikita Proshkin
 * All rights reserved.
 */

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <inttypes.h>
#include <stdio.h>
#include <signal.h>
#include <unistd.h>

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"
#include "tlm_utils/tlm_quantumkeeper.h"
#include "remote-port-tlm.h"
#include "remote-port-tlm-memory-master.h"

using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "soc/interconnect/iconnect.h"
#include "tlm-bridges/tlm2axis-bridge.h"
#include "soc/xilinx/zynq/xilinx-zynq.h"
#include "scrambler.hh"

#define NR_MASTERS 1
#define NR_DEVICES 1

SC_MODULE(stream_adapter)
{
public:
    const char *socket_path = "unix:/tmp/qemu-rport-_cosim@0";

    // Module ifc
    sc_out<bool> axis_dvbs_tvalid;
    sc_out<sc_bv<8>> axis_dvbs_tdata;
    sc_out<bool> axis_dvbs_tlast;
    sc_in<bool> axis_dvbs_tready;

    sc_out<bool> rst_o;
    sc_out<bool> clk;
    //

    remoteport_tlm rp;
    remoteport_tlm_memory_master rp_m_dvbs;
    tlm2axis_bridge<8> tlm2axis_dvbs;
    scrambler scrambl;

    iconnect<NR_MASTERS, NR_DEVICES> bus;
    sc_clock *clk_gen;
    sc_signal<bool> rst;
    sc_signal<bool> rstn;
    sc_signal<bool> tuser;
    sc_signal<sc_bv<1>> tstrb;

    sc_time quantum = sc_time(1000000, SC_NS);

    SC_HAS_PROCESS(stream_adapter);

    void pull_reset(void)
    {
        /* Pull the reset signal. */
        rst.write(true);
        rstn.write(false);
        wait(100, SC_US);
        rst.write(false);
        rstn.write(true);
    }

    void clk_assign()
    {
        clk.write(clk_gen->read());
    }

    void gen_rsts(void)
    {
        rst_o.write(rst.read());
    }

    stream_adapter(sc_module_name name) : rp("rp", -1, socket_path),
                                          rp_m_dvbs("rp_m_dvbs"),
                                          tlm2axis_dvbs("tlm2axis-dvbs-bridge"),
                                          scrambl("scrambler", sc_time(10, SC_NS)),
                                          bus("bus"),
                                          rst("rst"),
                                          rstn("rstn"),
                                          tuser("tuser"),
                                          tstrb("tstrb")
    {
        m_qk.set_global_quantum(quantum);
        clk_gen = new sc_clock("clk", sc_time(1, SC_US));

        rp.rst(rst);

        bus.memmap(0x40001000ULL, 4,
                   ADDRMODE_RELATIVE, -1, scrambl.t_sk);
        scrambl.i_sk.bind(tlm2axis_dvbs.tgt_socket);
        tlm2axis_dvbs.clk(*clk_gen);
        tlm2axis_dvbs.resetn(rstn);
        tlm2axis_dvbs.tvalid(axis_dvbs_tvalid);
        tlm2axis_dvbs.tready(axis_dvbs_tready);
        tlm2axis_dvbs.tdata(axis_dvbs_tdata);
        tlm2axis_dvbs.tlast(axis_dvbs_tlast);
        tlm2axis_dvbs.tuser(tuser);
        tlm2axis_dvbs.tstrb(tstrb);

        rp.register_dev(7, &rp_m_dvbs);
        rp_m_dvbs.sk.bind(*(bus.t_sk[0]));

        SC_METHOD(clk_assign);
        sensitive << *clk_gen;
        dont_initialize();

        SC_METHOD(gen_rsts);
        sensitive << rst;

        SC_THREAD(pull_reset);
    }

private:
    tlm_utils::tlm_quantumkeeper m_qk;
};

SC_MODULE_EXPORT(stream_adapter);
