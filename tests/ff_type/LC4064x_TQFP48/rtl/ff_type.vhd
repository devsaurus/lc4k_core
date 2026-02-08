
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ff_type is

  port (
    i_clk  : in  std_logic;
    i_res  : in  std_logic;
    i_ce   : in  std_logic;
    i_din  : in  std_logic_vector(1 downto 0);
    o_dout : out std_logic_vector(2 downto 0)
  );

end;

architecture rtl of ff_type is

  signal ltch, dff : std_logic;
  signal cnt : unsigned(5 downto 0);
  signal cnt1 : std_logic;

begin

  latch_p : process (i_res, i_clk, i_ce, i_din(0))
  begin
    if i_res = '1' then
      ltch <= '0';
    elsif (i_clk and i_ce)  = '1' then
      ltch <= i_din(0);
    end if;
  end process;

  -- Note that the fitter will build counter logic on .D while it fits into the
  -- 5pt cluster. Then it will resort to .T
  tff_p : process (i_res, i_clk)
  begin
    if i_res = '1' then
      cnt <= (others => '0');
    elsif rising_edge(i_clk) then
      if i_ce = '1' then
        cnt <= cnt + 1;
      end if;
    end if;
  end process;

  dff_p : process (i_res, i_clk)
  begin
    if i_res = '1' then
      dff <= '0';
    elsif rising_edge(i_clk) then
      if i_ce = '1' then
        dff <= i_din(1);
      end if;
    end if;
  end process;

  cnt1 <= '1' when cnt = 2**(cnt'length)-1 else '0';

  o_dout <= dff & cnt1 & ltch;

end;
