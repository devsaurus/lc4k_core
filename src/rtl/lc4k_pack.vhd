-- ----------------------------------------------------------------------------
--
-- LC4K Core
--
-- Copyright 2026, Arnim Laeuger (devsaurus@users.noreply.github.com)
--
-- ----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package lc4k_pack is

  constant num_mcs : natural := 16;
  constant num_gis : natural := 36;
  constant num_pts : natural := 83;

  subtype f_t  is std_logic;
  subtype fv_t is std_logic_vector;

  type io_cell_r is record
    oe_source       : fv_t(0 to 2);
    drive_type      : f_t;
    slew_rate       : f_t;
    input_threshold : f_t;
  end record;

  type macrocell_r is record
    init_state          : f_t;
    init_source         : f_t;
    async_source        : f_t;
    input_bypass        : f_t;
    invert              : f_t;
    clock_enable_source : fv_t(0 to 1);
    clock_source        : fv_t(0 to 2);
    macrocell_function  : fv_t(0 to 1);
  end record;
  --
  type macrocells_t is array (natural range 0 to num_mcs-1) of macrocell_r;

  type ela_r is record
    cluster_routing     : fv_t(0 to 1);
    wide_routing        : f_t;
    pt0_xor             : f_t;           -- remove PT0
    clock_source        : fv_t(0 to 2);  -- remove PT1
    clock_enable_source : fv_t(0 to 1);  -- remove PT2
    async_source        : f_t;           -- remove PT2
    init_source         : f_t;           -- remove PT3
    pt4_output_enable   : f_t;           -- remove PT4
  end record;
  --
  type elas_t is array (natural range 0 to num_mcs-1) of ela_r;

  type pterm_r is record
    normal : fv_t(0 to num_gis-1);
    invert : fv_t(0 to num_gis-1);
  end record;
  --
  type pterms_t is array (natural range 0 to num_pts-1) of pterm_r;

  type glb_r is record
    bclk01_polarity : fv_t(0 to 1);
    bclk23_polarity : fv_t(0 to 1);
    shared_pt_clk_polarity  : f_t;
    shared_pt_init_polarity : f_t;
  end record;

  type osctimer_r is record
    timer_div : fv_t(0 to 1);
  end record;

  -- pragma translate_off
  constant c_debug_enabled : boolean := false;
  function to_string (a : std_logic_vector) return string;
  -- pragma translate_on

end;

package body lc4k_pack is

  -- pragma translate_off
  function to_string (a : std_logic_vector) return string is
    variable b : string (1 to a'length) := (others => NUL);
    variable stri : integer := 1; 
  begin
    for i in a'range loop
      b(stri) := std_logic'image(a((i)))(2);
      stri := stri+1;
    end loop;
    return b;
  end function;
  -- pragma translate_on

end;
