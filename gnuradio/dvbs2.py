#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#
# SPDX-License-Identifier: GPL-3.0
#
# GNU Radio Python Flow Graph
# Title: Not titled yet
# GNU Radio version: 3.10.7.0

from gnuradio import blocks
import pmt
from gnuradio import dtv
from gnuradio import gr
from gnuradio.filter import firdes
from gnuradio.fft import window
import sys
import signal
from argparse import ArgumentParser
from gnuradio.eng_arg import eng_float, intx
from gnuradio import eng_notation




class bbheaders(gr.top_block):

    def __init__(self):
        gr.top_block.__init__(self, "Not titled yet", catch_exceptions=True)

        ##################################################
        # Variables
        ##################################################
        self.samp_rate = samp_rate = 32000

        ##################################################
        # Blocks
        ##################################################

        self.dtv_dvb_ldpc_bb_0 = dtv.dvb_ldpc_bb(
            dtv.STANDARD_DVBS2,
            dtv.FECFRAME_NORMAL,
            dtv.C9_10,
            dtv.MOD_OTHER)
        self.dtv_dvb_bch_bb_0 = dtv.dvb_bch_bb(
            dtv.STANDARD_DVBS2,
            dtv.FECFRAME_NORMAL,
            dtv.C9_10
            )
        self.dtv_dvb_bbscrambler_bb_0 = dtv.dvb_bbscrambler_bb(
            dtv.STANDARD_DVBS2,
            dtv.FECFRAME_NORMAL,
            dtv.C9_10
            )
        self.dtv_dvb_bbheader_bb_0 = dtv.dvb_bbheader_bb(
        dtv.STANDARD_DVBS2,
        dtv.FECFRAME_NORMAL,
        dtv.C9_10,
        dtv.RO_0_35,
        dtv.INPUTMODE_NORMAL,
        dtv.INBAND_OFF,
        168,
        4000000)
        self.blocks_repack_bits_bb_0_0 = blocks.repack_bits_bb(1, 8, "", False, gr.GR_MSB_FIRST)
        self.blocks_file_source_0 = blocks.file_source(gr.sizeof_char*1, sys.argv[1], False, 0, 0)
        self.blocks_file_source_0.set_begin_tag(pmt.PMT_NIL)
        self.blocks_file_sink_1 = blocks.file_sink(gr.sizeof_char*1, sys.argv[2], False)
        self.blocks_file_sink_1.set_unbuffered(False)


        ##################################################
        # Connections
        ##################################################
        self.connect((self.blocks_file_source_0, 0), (self.dtv_dvb_bbheader_bb_0, 0))
        self.connect((self.blocks_repack_bits_bb_0_0, 0), (self.blocks_file_sink_1, 0))
        self.connect((self.dtv_dvb_bbheader_bb_0, 0), (self.dtv_dvb_bbscrambler_bb_0, 0))
        self.connect((self.dtv_dvb_bbscrambler_bb_0, 0), (self.dtv_dvb_bch_bb_0, 0))
        self.connect((self.dtv_dvb_bch_bb_0, 0), (self.dtv_dvb_ldpc_bb_0, 0))
        self.connect((self.dtv_dvb_ldpc_bb_0, 0), (self.blocks_repack_bits_bb_0_0, 0))


    def get_samp_rate(self):
        return self.samp_rate

    def set_samp_rate(self, samp_rate):
        self.samp_rate = samp_rate




def main(top_block_cls=bbheaders, options=None):
    tb = top_block_cls()

    def sig_handler(sig=None, frame=None):
        tb.stop()
        tb.wait()

        sys.exit(0)

    signal.signal(signal.SIGINT, sig_handler)
    signal.signal(signal.SIGTERM, sig_handler)

    tb.start()

    try:
        input('Press Enter to quit: ')
    except EOFError:
        pass
    tb.stop()
    tb.wait()


if __name__ == '__main__':
    main()
