-- ----------------------------------------------------------------------------
--
-- LC4K Core
--
-- Copyright 2026, Arnim Laeuger (devsaurus@users.noreply.github.com)
--
-- ----------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- IO Cell
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_io_cell is
  generic (
    g_io_cell : io_cell_r
  );
  port (
    i_pin    : in  std_logic;
    o_pin    : out std_logic;
    o_pin_oe : out std_logic;
    --
    i_orm    : in  std_logic;
    i_orm_oe : in  std_logic;
    i_goe    : in  std_logic_vector(0 to 3);
    o_mc_grp : out std_logic
  );
end;

architecture rtl of lc4k_io_cell is

  signal oe : std_logic;

begin

  -- fused output enable multiplexer
  with g_io_cell.oe_source select
    oe <= i_goe(0)     when "000",
          i_goe(1)     when "100",
          i_goe(2)     when "010",
          i_goe(3)     when "110",
          i_orm_oe     when "001",
          not i_orm_oe when "101",
          '1'          when "011",
          '0'          when others;

  pp_od_p : process (i_orm, oe)
  begin
    if g_io_cell.drive_type = '1' then
      -- push pull
      o_pin    <= i_orm;
      o_pin_oe <= oe;
    else
      -- open drain
      o_pin    <= '0';
      o_pin_oe <= not i_orm;
    end if;
  end process;

  o_mc_grp <= i_pin;

end;


-------------------------------------------------------------------------------
-- ZE IO Cell
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_ze_io_cell is
  generic (
    g_bus_maintenance : fv_t(0 to 1);
    g_io_cell         : io_cell_r;
    g_pgdf            : f_t
  );
  port (
    i_pin    : in  std_logic;
    o_pin    : out std_logic;
    o_pin_oe : out std_logic;
    o_pin_pu : out std_logic;
    o_pin_pd : out std_logic;
    o_pin_kp : out std_logic;
    --
    i_orm    : in  std_logic;
    i_orm_oe : in  std_logic;
    i_goe    : in  std_logic_vector(0 to 3);
    i_bie    : in  std_logic;
    o_mc_grp : out std_logic
  );
end;

architecture rtl of lc4k_ze_io_cell is

  signal oe : std_logic;
  signal in_latch : std_logic;

begin

  process (i_pin, i_bie)
  begin
    if (i_bie or g_pgdf) = '1' then
      in_latch <= i_pin;
    end if;
  end process;

  std_io_b : entity work.lc4k_io_cell
    generic map (
      g_io_cell => g_io_cell
    )
    port map (
      i_pin    => in_latch,
      o_pin    => o_pin,
      o_pin_oe => o_pin_oe,
      --
      i_orm    => i_orm,
      i_orm_oe => i_orm_oe,
      i_goe    => i_goe,
      o_mc_grp => o_mc_grp
    );

  o_pin_pu <= '1' when g_bus_maintenance = "00" else '0';
  o_pin_pd <= '1' when g_bus_maintenance = "11" else '0';
  o_pin_kp <= '1' when g_bus_maintenance = "10" else '0';

end;


-------------------------------------------------------------------------------
-- IN Cell
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_in_cell is
  generic (
    g_input_threshold : f_t
  );
  port (
    i_pin    : in  std_logic;
    --
    o_mc_grp : out std_logic
  );
end;

architecture rtl of lc4k_in_cell is

begin

  o_mc_grp <= i_pin;

end;


-------------------------------------------------------------------------------
-- ZE IN Cell
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_ze_in_cell is
  generic (
    g_bus_maintenance : fv_t(0 to 1);
    g_input_threshold : f_t;
    g_pgdf            : f_t
  );
  port (
    i_pin    : in  std_logic;
    o_pin_pu : out std_logic;
    o_pin_pd : out std_logic;
    o_pin_kp : out std_logic;
    --
    i_bie    : in  std_logic;
    o_mc_grp : out std_logic
  );
end;

architecture rtl of lc4k_ze_in_cell is

  signal in_latch : std_logic;

begin

  process (i_pin, i_bie)
  begin
    if (i_bie or g_pgdf) = '1' then
      in_latch <= i_pin;
    end if;
  end process;

  std_in_b : entity work.lc4k_in_cell
    generic map (
      g_input_threshold => g_input_threshold
    )
    port map (
      i_pin    => in_latch,
      o_mc_grp => o_mc_grp
    );

  o_pin_pu <= '1' when g_bus_maintenance = "00" else '0';
  o_pin_pd <= '1' when g_bus_maintenance = "11" else '0';
  o_pin_kp <= '1' when g_bus_maintenance = "10" else '0';

end;


-------------------------------------------------------------------------------
-- Macrocell
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_macrocell is
  generic (
    g_config : macrocell_r;
    g_zht    : f_t
  );
  port (
    i_shared_pt_init  : in  std_logic;
    i_io_cell         : in  std_logic;
    i_logic_alloc     : in  std_logic;
    i_bclk0           : in  std_logic;
    i_bclk1           : in  std_logic;
    i_bclk2           : in  std_logic;
    i_bclk3           : in  std_logic;
    i_pt0             : in  std_logic;  -- Single PT for XOR/OR
    i_pt1             : in  std_logic;  -- Individual Clock (PT Clock)
    i_pt2             : in  std_logic;  -- Individual Initialization or Individual Clock Enable (PT Initialization/CE)
    i_pt3             : in  std_logic;  -- Individual Initialization (PT Initialization)
    i_shared_pt_clock : in  std_logic;
    o_to_orp_grp      : out std_logic
  );
end;

architecture rtl of lc4k_macrocell is

  signal reset, preset : std_logic;
  signal por_init, async_init : std_logic;
  signal shared_init : std_logic;
  --
  signal din : std_logic;
  signal clk : std_logic;
  signal ce  : std_logic;
  signal reg : std_logic := not g_config.init_state;

begin

  -- build preset and reset
  shared_init <= i_shared_pt_init when g_config.init_source = '1' else i_pt3;
  por_init    <= '0' xor shared_init;   -- TODO: inject POR
  --
  async_init <= i_pt2 when g_config.async_source = '0' else '0';
  --
  preset <= por_init when g_config.init_state = '0' else async_init;
  reset  <= por_init when g_config.init_state = '1' else async_init;

  -- build din
  process (i_io_cell, i_logic_alloc, i_pt0)
    variable delay_mux_v : std_logic;
    variable din_xor_v   : std_logic;
    variable single_pt_v : std_logic;
  begin
    delay_mux_v := i_io_cell;           -- ignored zero hold time setting
    single_pt_v := i_pt0 xor g_config.invert;
    din_xor_v   := i_logic_alloc xor single_pt_v;
    if g_config.input_bypass = '0' then
      din       <= delay_mux_v;
    else
      din       <= din_xor_v;
    end if;    
  end process;

  -- build clock enable
  with g_config.clock_enable_source select ce <=
    i_shared_pt_clock when "00",
    not i_pt2         when "10",
    i_pt2             when "01",
    '1'               when others;

  -- build clock
  with g_config.clock_source select clk <=
    i_bclk0           when "000",
    i_bclk1           when "100",
    i_bclk2           when "010",
    i_bclk3           when "110",
    i_pt1             when "001",
    not i_pt1         when "101",
    i_shared_pt_clock when "011",
    '0'               when others;

  -- macrocell function
  comb : if g_config.macrocell_function = "00" generate
    reg <= din;
  end generate comb;
  --
  latch : if g_config.macrocell_function = "10" generate
    process (preset, reset, clk, ce, din)
    begin
      if reset = '1' then
        reg <= '0';
      elsif preset = '1' then
        reg <= '1';
      elsif (clk and ce) = '1' then
        reg <= din;
      end if;
    end process;
  end generate latch;
  --
  tff : if g_config.macrocell_function = "01" generate
    process (preset, reset, clk)
    begin
      if reset = '1' then
        reg <= '0';
      elsif preset = '1' then
        reg <= '1';
      elsif rising_edge(clk) then
        if ce = '1' and din = '1' then
          reg <= not reg;
        end if;
      end if;
    end process;
  end generate tff;
  --
  dff : if g_config.macrocell_function = "11" generate
    process (preset, reset, clk)
    begin
      if reset = '1' then
        reg <= '0';
      elsif preset = '1' then
        reg <= '1';
      elsif rising_edge(clk) then
        if ce = '1' then
          reg <= din;
        end if;
      end if;
    end process;
  end generate dff;

  o_to_orp_grp <= reg;

  -- pragma translate_off
  debug_block : block
  begin
    mc_p : process
      variable function_str : string (1 to 5);
      variable clk_str : string (1 to 9);
      variable init_source_str : string (1 to 6);
      variable init_state_str : string (1 to 6);
    begin
      if c_debug_enabled then

        if g_config.clock_source /= "111" then

          if g_config.macrocell_function = "10" then
            function_str := "latch";
          elsif g_config.macrocell_function = "01" then
            function_str := "tff  ";
          elsif g_config.macrocell_function = "11" then
            function_str := "dff  ";
          end if;
          report lc4k_macrocell'path_name & " is a " & function_str;

          if g_config.clock_source = "000" then
            clk_str := "bclk0    ";
          elsif g_config.clock_source = "100" then
            clk_str := "bclk1    ";
          elsif g_config.clock_source = "010" then
            clk_str := "bclk2    ";
          elsif g_config.clock_source = "110" then
            clk_str := "bclk3    ";
          elsif g_config.clock_source = "001" then
            clk_str := "pt       ";
          elsif g_config.clock_source = "101" then
            clk_str := "inv_pt   ";
          elsif g_config.clock_source = "011" then
            clk_str := "shared_pt";
          elsif g_config.clock_source = "111" then
            clk_str := "gnd      ";
          end if;
          report " MC clock is " & clk_str;

          if g_config.invert = '1' then
            report " It has single PT invert";
          else
            report " It doesn't have single PT invert";
          end if;

          if g_config.async_source = '0' then
            report " It has async source";
          end if;

          if g_config.init_source = '1' then
            init_source_str := "shared";
          else
            init_source_str := "pt3   ";
          end if;
          if g_config.init_state = '0' then
            init_state_str := "preset";
          else
            init_state_str := "reset ";
          end if;
          report " It uses " & init_source_str & " init for " & init_state_str;

          if g_config.input_bypass = '0' then
            report " It has input bypass";
          end if;

        end if;

      end if;
      wait;
    end process;
  end block;
  -- pragma translate_on

end;


-------------------------------------------------------------------------------
-- Enhanced Logic Allocator
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_ela is
  generic (
    g_config : ela_r
  );
  port (
    i_cluster : in  std_logic_vector(0 to 4);
    o_to_m2   : out std_logic;
    o_to_m1   : out std_logic;
    o_to_p1   : out std_logic;
    i_from_m4 : in  std_logic;
    i_from_m1 : in  std_logic;
    i_from_p2 : in  std_logic;
    i_from_p1 : in  std_logic;
    o_to_p4   : out std_logic;
    o_5pt     : out std_logic;
    o_mc      : out std_logic;
    o_pt      : out std_logic_vector(0 to 4)
  );
end;

architecture rtl of lc4k_ela is

  signal cluster : std_logic_vector(i_cluster'range);
  signal sum, self, ca : std_logic;

begin

  -----------------------------------------------------------------------------
  -- Determine which product terms are used for the OR
  --
  process (i_cluster)
  begin
    -- PT0 used for XOR in macrocell?
    if g_config.pt0_xor = '0' then
      cluster(0) <= '0';
      o_pt(0)    <= i_cluster(0);
    else
      cluster(0) <= i_cluster(0);
      o_pt(0)    <= '0';
    end if;
    -- PT1 used as clock in macrocell?
    if g_config.clock_source(1 to 2) = "01" then
      cluster(1) <= '0';
      o_pt(1)    <= i_cluster(1);
    else
      cluster(1) <= i_cluster(1);
      o_pt(1)    <= '0';
    end if;
    -- PT2 used as clock enable source or as async source?
    if g_config.clock_enable_source(1) = '0' or g_config.async_source = '0' then
      cluster(2) <= '0';
      o_pt(2)    <= i_cluster(2);
    else
      cluster(2) <= i_cluster(2);
      o_pt(2)    <= '0';
    end if;
    -- PT3 used as init source?
    if g_config.init_source = '0' then
      cluster(3) <= '0';
      o_pt(3)    <= i_cluster(3);
    else
      cluster(3) <= i_cluster(3);
      o_pt(3)    <= '0';
    end if;
    -- PT4 used as output enable?
    if g_config.pt4_output_enable = '0' then
      cluster(4) <= '0';
      o_pt(4)    <= i_cluster(4);
    else
      cluster(4) <= i_cluster(4);
      o_pt(4)    <= '0';
    end if;
  end process;
  --
  sum   <= cluster(0) or cluster(1) or cluster(2) or cluster(3) or cluster(4);
  o_5pt <= sum;

  -----------------------------------------------------------------------------
  -- Cluster allocator
  --
  o_to_m2 <= sum when g_config.cluster_routing = "00" else '0';
  self    <= sum when g_config.cluster_routing = "10" else '0';
  o_to_p1 <= sum when g_config.cluster_routing = "01" else '0';
  o_to_m1 <= sum when g_config.cluster_routing = "11" else '0';
  --
  ca <= i_from_m4 or i_from_m1 or self or i_from_p2 or i_from_p1;

  -----------------------------------------------------------------------------
  -- Wide routing
  --
  o_mc    <= ca when g_config.wide_routing = '1' else '0';
  o_to_p4 <= ca when g_config.wide_routing = '0' else '0';

  -- pragma translate_off
  debug_block : block
  begin
    ca_p : process
      variable cluster_str : string (1 to 2) := "??";
    begin
      if c_debug_enabled then

        if g_config.cluster_routing /= "10" then
          if g_config.cluster_routing = "00" then
            cluster_str := "m2";
          elsif g_config.cluster_routing = "01" then
            cluster_str := "p1";
          elsif g_config.cluster_routing = "11" then
            cluster_str := "m1";
          end if;
          report lc4k_ela'path_name & " cluster " & cluster_str;
        end if;
        --
        if g_config.wide_routing = '0' then
          report lc4k_ela'path_name & " wide routing";
        end if;

      end if;
      wait;
    end process;
  end block;
  -- pragma translate_on

end;


-------------------------------------------------------------------------------
-- Generic Logic Block
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

use work.lc4k_pack.all;

entity lc4k_glb is
  generic (
    g_config : glb_r;
    g_pts    : pterms_t;
    g_mcs    : macrocells_t;
    g_elas   : elas_t;
    g_zht    : f_t
  );
  port (
    i_clk0  : in  std_logic;
    i_clk1  : in  std_logic;
    i_clk2  : in  std_logic;
    i_clk3  : in  std_logic;
    i_grp   : in  std_logic_vector(0 to num_gis-1);
    i_ios   : in  std_logic_vector(0 to num_mcs-1);
    o_mcs   : out std_logic_vector(0 to num_mcs-1);
    o_5pts  : out std_logic_vector(0 to num_mcs-1);
    o_ptoes : out std_logic_vector(0 to num_mcs-1);
    o_shared_ptoe : out std_logic
  );
end;

architecture rtl of lc4k_glb is

  signal bclk0, bclk1, bclk2, bclk3 : std_logic;

  signal shared_pt_init, shared_pt_clock : std_logic;

  signal pterms : std_logic_vector(0 to num_pts-1);

  type ela_conn_r is record
    to_m1, to_m2  : std_logic;
    to_p1, to_p4  : std_logic;
    from_m4       : std_logic;
    to_mc         : std_logic;
    pt            : std_logic_vector(0 to 4);
  end record;
  constant ela_conn_z : ela_conn_r := ('0', '0', '0', '0', '0', '0', (others => '0'));
  type ela_conns_t is array (integer range -1 to num_mcs+1) of ela_conn_r;
  signal ela_conns : ela_conns_t;

begin

  -----------------------------------------------------------------------------
  -- GLB Clock Generator
  --
  bclk0 <= i_clk0 when g_config.bclk01_polarity(0) = '1' else not i_clk1;
  bclk1 <= i_clk1 when g_config.bclk01_polarity(1) = '1' else not i_clk0;
  bclk2 <= i_clk2 when g_config.bclk23_polarity(0) = '1' else not i_clk3;
  bclk3 <= i_clk3 when g_config.bclk23_polarity(1) = '1' else not i_clk2;


  -----------------------------------------------------------------------------
  -- Product Terms
  --
  process (i_grp)
    variable pt_v : std_logic;
  begin
    for pt in 0 to num_pts-1 loop
      pt_v := '1';
      for gi in 0 to num_gis-1 loop
        pt_v :=     pt_v
                and (    i_grp(gi) or g_pts(pt).normal(gi))
                and (not i_grp(gi) or g_pts(pt).invert(gi));
      end loop;

      pterms(pt) <= pt_v;
    end loop;
  end process;
  --
  shared_pt_clock <= pterms(80) when g_config.shared_pt_clk_polarity  = '1' else not pterms(80);
  shared_pt_init  <= pterms(81) when g_config.shared_pt_init_polarity = '1' else not pterms(81);
  o_shared_ptoe   <= pterms(82);


  -----------------------------------------------------------------------------
  -- Enhanced Logic Allocators
  --
  -- initialize unused ela connections
  ela_conns(-1)         <= ela_conn_z;
  ela_conns(num_mcs)    <= ela_conn_z;
  ela_conns(num_mcs+1)  <= ela_conn_z;
  --
  slice_gen : for idx in 0 to num_mcs-1 generate
    ela_b : entity work.lc4k_ela
      generic map (
        g_config => g_elas(idx)
      )
      port map (
        i_cluster => pterms(idx*5 to idx*5+4),
        o_to_m2   => ela_conns(idx).to_m2,
        o_to_m1   => ela_conns(idx).to_m1,
        o_to_p1   => ela_conns(idx).to_p1,
        i_from_m4 => ela_conns(idx).from_m4,
        i_from_m1 => ela_conns(idx-1).to_p1,
        i_from_p2 => ela_conns(idx+2).to_m2,
        i_from_p1 => ela_conns(idx+1).to_m1,
        o_to_p4   => ela_conns(idx).to_p4,
        o_5pt     => o_5pts(idx),
        o_mc      => ela_conns(idx).to_mc,
        o_pt      => ela_conns(idx).pt
      );
    -- wire up wide routing
    ela_conns((idx + 4) mod num_mcs).from_m4 <= ela_conns(idx).to_p4;
    -- provide individual PT OEs
    o_ptoes(idx) <= ela_conns(idx).pt(4);

    macrocell_b : entity work.lc4k_macrocell
      generic map (
        g_config => g_mcs(idx),
        g_zht    => g_zht
      )
      port map (
        i_shared_pt_init  => shared_pt_init,
        i_io_cell         => i_ios(idx),
        i_logic_alloc     => ela_conns(idx).to_mc,
        i_bclk0           => bclk0,
        i_bclk1           => bclk1,
        i_bclk2           => bclk2,
        i_bclk3           => bclk3,
        i_pt0             => ela_conns(idx).pt(0),
        i_pt1             => ela_conns(idx).pt(1),
        i_pt2             => ela_conns(idx).pt(2),
        i_pt3             => ela_conns(idx).pt(3),
        i_shared_pt_clock => shared_pt_clock,
        o_to_orp_grp      => o_mcs(idx)
      );

  end generate;

end;


-------------------------------------------------------------------------------
-- On-Chip Oscillator and Timer
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.lc4k_pack.all;

entity lc4k_osctimer is
  generic (
    g_config : osctimer_r
  );
  port (
    i_oscclk2x  : in  std_logic;
    i_dynoscdis : in  std_logic;
    i_timerres  : in  std_logic;
    o_oscout    : out std_logic;
    o_timerout  : out std_logic
  );
end;

architecture rtl of lc4k_osctimer is

  signal oscclk : std_logic := '0';
  signal timer : unsigned(19 downto 0);

  constant c_reload : unsigned(timer'range) :=
    ( 6 => g_config.timer_div(0) nand g_config.timer_div(1),
      9 => g_config.timer_div(1),
     19 => g_config.timer_div(0),
     others => '0');

begin

  oscclk_p : process (i_oscclk2x)
  begin
    if rising_edge(i_oscclk2x) then
      if i_dynoscdis = '1' then
        oscclk <= '0';
      else
        oscclk <= not oscclk;
      end if;
    end if;
  end process;
  --
  o_oscout <= oscclk;

  timer_p : process (i_oscclk2x)
  begin
    if rising_edge(i_oscclk2x) then
      if i_dynoscdis = '1' or i_timerres = '1' then
        timer <= c_reload;

      elsif oscclk = '0' then
        if timer > 0 then
          timer <= timer - 1;
        else
          timer <= c_reload;
        end if;
      end if;
    end if;
  end process;
  --
  with g_config.timer_div select o_timerout <=
    timer( 9) when "01",
    timer(19) when "10",
    timer( 6) when others;

end;
