
library ieee;
use ieee.std_logic_1164.all;

entity set_res_ff is

  port (
    i_clk : in  std_logic;
    i_set : in  std_logic;
    i_res : in  std_logic;
    i_d   : in  std_logic;
    o_d   : out std_logic
  );

end;

architecture rtl of set_res_ff is

begin

  process (i_clk, i_set, i_res)
  begin
    if i_res = '1' then
      o_d <= '0';
    elsif i_set = '1' then
      o_d <= '1';
    elsif rising_edge(i_clk) then
      o_d <= i_d;
    end if;
  end process;

end;


library ieee;
use ieee.std_logic_1164.all;

entity bclk_set_res is

  port (
    i_clk_a    : in  std_logic;
    i_clk_b    : in  std_logic;
    i_setres_a : in  std_logic;
    i_setres_b : in  std_logic;
    i_setres_c : in  std_logic;
    i_setres_d : in  std_logic;
    i_din      : in  std_logic_vector(3 downto 0);
    o_dout     : out std_logic_vector(3 downto 0)
  );

end;

architecture rtl of bclk_set_res is

  signal block_init_and, block_init_or : std_logic;

begin

  block_init_and <= i_setres_a and i_setres_b;
  block_init_or  <= i_setres_a or i_setres_b;

  ff_bclk_blockand_set : block
    signal clk, set, res : std_logic;
  begin

    clk <= i_clk_a;
    set <= block_init_and;
    res <= i_setres_c and i_setres_d;

    ff_b : entity work.set_res_ff
      port map (
        i_clk => clk,
        i_set => set,
        i_res => res,
        i_d   => i_din(0),
        o_d   => o_dout(0)
      );

  end block;

  ff_bclk_blockor_set : block
    signal clk, set, res : std_logic;
  begin

    clk <= i_clk_b;
    set <= block_init_or;
    res <= i_setres_c and i_setres_d;

    ff_b : entity work.set_res_ff
      port map (
        i_clk => clk,
        i_set => set,
        i_res => res,
        i_d   => i_din(1),
        o_d   => o_dout(1)
      );

  end block;

  ff_bclk_blockand_res : block
    signal clk, set, res : std_logic;
  begin

    clk <= not i_clk_a;
    res <= block_init_and;
    set <= i_setres_c and i_setres_d;

    ff_b : entity work.set_res_ff
      port map (
        i_clk => clk,
        i_set => set,
        i_res => res,
        i_d   => i_din(2),
        o_d   => o_dout(2)
      );

  end block;

  ff_bclk_blockor_res : block
    signal clk, set, res : std_logic;
  begin

    clk <= not i_clk_b;
    res <= block_init_or;
    set <= i_setres_c and i_setres_d;

    ff_b : entity work.set_res_ff
      port map (
        i_clk => clk,
        i_set => set,
        i_res => res,
        i_d   => i_din(3),
        o_d   => o_dout(3)
      );

  end block;

end;
