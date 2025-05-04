-- Copyright (c) 2025 Nikita Proshkin
-- All rights reserved.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library fpga_cores;
use fpga_cores.common_pkg.all;

use work.dvb_utils_pkg.all;
use work.dvbs2_encoder_regs_pkg.all;

entity fec_encoder is
    port (
      -- Usual ports
      clk             : in  std_logic;
      rst             : in  std_logic;
  
      -- AXI input
      s_tvalid        : in  std_logic;
      s_tdata         : in  std_logic_vector(7 downto 0);
      s_tkeep         : in  std_logic_vector(7 downto 0);
      s_tlast         : in  std_logic;
      s_tready        : out std_logic;
      -- AXI output
      m_tready        : in  std_logic;
      m_tvalid        : out std_logic;
      m_tlast         : out std_logic;
      m_tdata         : out std_logic_vector(7 downto 0));
  end fec_encoder;

architecture fec_encoder of fec_encoder is

  type data_and_config_t is record
    tdata  : std_logic_vector;
    tid    : std_logic_vector(ENCODED_CONFIG_WIDTH - 1 downto 0);
    tvalid : std_logic;
    tlast  : std_logic;
    tready : std_logic;
  end record;

  signal s_tid                    : std_logic_vector(ENCODED_CONFIG_WIDTH - 1 downto 0);
  signal s_constellation          : constellation_t;
  signal s_frame_type             : frame_type_t;
  signal s_code_rate              : code_rate_t;
  signal s_pilots                 : std_logic;

  signal bch_encoder              : data_and_config_t(tdata(7 downto 0));
  signal ldpc_encoder             : data_and_config_t(tdata(7 downto 0));

begin

  s_frame_type <= fecframe_normal;
  s_code_rate <= C9_10;
  s_pilots <= '0';
  s_constellation <= mod_8psk;

  s_tid <= encode((frame_type    => s_frame_type,
                   constellation => s_constellation,
                   code_rate     => s_code_rate,
                   pilots        => s_pilots));

  bch_encoder_u : entity work.axi_bch_encoder
    generic map (
      TID_WIDTH   => ENCODED_CONFIG_WIDTH
    )
    port map (
      -- Usual ports
      clk          => clk,
      rst          => rst,
      -- AXI input
      s_frame_type => decode(s_tid).frame_type,
      s_code_rate  => decode(s_tid).code_rate,
      s_tvalid     => s_tvalid,
      s_tlast      => s_tlast,
      s_tready     => s_tready,
      s_tdata      => s_tdata,
      s_tid        => s_tid,
      -- AXI output
      m_tready     => bch_encoder.tready,
      m_tvalid     => bch_encoder.tvalid,
      m_tlast      => bch_encoder.tlast,
      m_tdata      => bch_encoder.tdata,
      m_tid        => bch_encoder.tid);

  ldpc_encoder_u : entity work.axi_ldpc_encoder
    generic map ( TID_WIDTH   => ENCODED_CONFIG_WIDTH )
    port map (
      -- Usual ports
      clk             => clk,
      rst             => rst,
      -- Per frame config input
      -- AXI input
      s_frame_type    => decode(bch_encoder.tid).frame_type,
      s_code_rate     => decode(bch_encoder.tid).code_rate,
      s_constellation => decode(bch_encoder.tid).constellation,
      s_tready        => bch_encoder.tready,
      s_tvalid        => bch_encoder.tvalid,
      s_tlast         => bch_encoder.tlast,
      s_tdata         => bch_encoder.tdata,
      s_tid           => bch_encoder.tid,
      -- AXI output
      m_tready        => ldpc_encoder.tready,
      m_tvalid        => ldpc_encoder.tvalid,
      m_tlast         => ldpc_encoder.tlast,
      m_tdata         => ldpc_encoder.tdata,
      m_tid           => ldpc_encoder.tid);

  bit_interleaver_u : entity work.axi_bit_interleaver
    generic map (
      TDATA_WIDTH => 8,
      TID_WIDTH   => ENCODED_CONFIG_WIDTH
    )
    port map (
      -- Usual ports
      clk             => clk,
      rst             => rst,
      -- AXI input
      s_frame_type    => decode(ldpc_encoder.tid).frame_type,
      s_constellation => decode(ldpc_encoder.tid).constellation,
      s_code_rate     => decode(ldpc_encoder.tid).code_rate,
      s_tready        => ldpc_encoder.tready,
      s_tvalid        => ldpc_encoder.tvalid,
      s_tlast         => ldpc_encoder.tlast,
      s_tdata         => ldpc_encoder.tdata,
      s_tid           => ldpc_encoder.tid,
      -- AXI output
      m_tready        => m_tready,
      m_tvalid        => m_tvalid,
      m_tlast         => m_tlast,
      m_tdata         => m_tdata
      -- m_tid           => bit_interleaver.tid
      );

end fec_encoder;
