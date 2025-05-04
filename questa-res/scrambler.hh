/*
 * Copyright (c) 2025 Nikita Proshkin
 * All rights reserved.
 */

#ifndef SCRAMBLER_HH_
#define SCRAMBLER_HH_

#include "systemc.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

class scrambler
    : public sc_core::sc_module
{
public:
    tlm_utils::simple_target_socket<scrambler> t_sk;
    tlm_utils::simple_initiator_socket<scrambler> i_sk;

    scrambler(sc_core::sc_module_name name, sc_core::sc_time byte_delay);
    virtual void b_transport(tlm::tlm_generic_payload &trans,
                             sc_time &delay);
    virtual unsigned int transport_dbg(tlm::tlm_generic_payload &trans);

private:
    void scramble_byte(uint8_t &byte);

    const uint32_t Kbch = 7274; // bytes 
    const uint16_t init_seq = 0x4A80;

    uint32_t bytes_cnt = 0;
    uint16_t shift_reg = init_seq;

    sc_core::sc_time byte_delay;
};

#endif
