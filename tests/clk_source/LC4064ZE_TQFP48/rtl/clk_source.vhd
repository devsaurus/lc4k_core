
library ieee;
use ieee.std_logic_1164.all;

entity res_ff is

  port (
    i_clk : in  std_logic;
    i_res : in  std_logic;
    i_d   : in  std_logic;
    o_d   : out std_logic
  );

end;

architecture rtl of res_ff is

begin

  process (i_clk, i_res)
  begin
    if i_res = '1' then
      o_d <= '0';
    elsif rising_edge(i_clk) then
      o_d <= i_d;
    end if;
  end process;

end;

library ieee;
use ieee.std_logic_1164.all;

entity clk_source is

  port (
    i_clk_0 : in  std_logic;
    i_clk_1 : in  std_logic;
    i_clk_2 : in  std_logic;
    i_clk_3 : in  std_logic;
    i_clk_4 : in  std_logic;
    i_clk_5 : in  std_logic;
    i_clk_6 : in  std_logic;
    i_clk_7 : in  std_logic;
    i_res   : in  std_logic;
    i_din   : in  std_logic_vector(5 downto 0);
    o_dout  : out std_logic_vector(5 downto 0)
  );

end;

architecture rtl of clk_source is

  signal clk_and, clk_or : std_logic;

begin

  clk_and <= i_clk_4 and i_clk_5;
  clk_or  <= i_clk_6 or  i_clk_7;

  ff0_b : entity work.res_ff
    port map (
      i_clk => i_clk_0,
      i_res => i_res,
      i_d   => i_din(0),
      o_d   => o_dout(0)
    );

  ff1_b : entity work.res_ff
    port map (
      i_clk => i_clk_1,
      i_res => i_res,
      i_d   => i_din(1),
      o_d   => o_dout(1)
    );

  ff2_b : entity work.res_ff
    port map (
      i_clk => i_clk_2,
      i_res => i_res,
      i_d   => i_din(2),
      o_d   => o_dout(2)
    );

  ff3_b : entity work.res_ff
    port map (
      i_clk => i_clk_3,
      i_res => i_res,
      i_d   => i_din(3),
      o_d   => o_dout(3)
    );

  ff4_b : entity work.res_ff
    port map (
      i_clk => clk_and,
      i_res => i_res,
      i_d   => i_din(4),
      o_d   => o_dout(4)
    );

  ff5_b : entity work.res_ff
    port map (
      i_clk => clk_or,
      i_res => i_res,
      i_d   => i_din(5),
      o_d   => o_dout(5)
    );

end;
