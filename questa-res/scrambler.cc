/*
 * Copyright (c) 2025 Nikita Proshkin
 * All rights reserved.
 */

#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "scrambler.hh"

#include <inttypes.h>
#include "tlm-extensions/genattr.h"

scrambler::scrambler(sc_module_name name,
                     sc_core::sc_time byte_delay) : sc_module(name),
                                                    t_sk("target_socket"),
                                                    i_sk("init_socket"),
                                                    byte_delay(byte_delay)
{
    t_sk.register_b_transport(this, &scrambler::b_transport);
    t_sk.register_transport_dbg(this, &scrambler::transport_dbg);
}

void scrambler::scramble_byte(uint8_t &byte)
{
    uint8_t res = 0;
    for (int i = 0; i < 8; i++)
    {
        res <<= 1;
        res |= (shift_reg & 0x1) ^ ((shift_reg >> 1) & 0x1) ^ (byte >> 7);
        byte <<= 1;
        shift_reg |= ((shift_reg & 0x1) ^ ((shift_reg >> 1) & 0x1)) << 15;
        shift_reg >>= 1;
    }
    byte = res;
}

void scrambler::b_transport(tlm::tlm_generic_payload &trans,
                            sc_time &delay)
{
    uint8_t *data = trans.get_data_ptr();
    size_t len = trans.get_data_length();
    genattr_extension *genattr;

    for (size_t i = 0; i < len; i++)
    {
        scramble_byte(data[i]);
        delay += byte_delay;
    }

    bytes_cnt += len;

    trans.get_extension(genattr);
    if (genattr)
    {
        genattr->set_eop(bytes_cnt == Kbch);
    }

    if (bytes_cnt == Kbch)
    {
        bytes_cnt = 0;
        shift_reg = init_seq;
    }

    i_sk->b_transport(trans, delay);
}

unsigned int scrambler::transport_dbg(tlm::tlm_generic_payload &trans)
{
    return 0;
}
