
library ieee;
use ieee.std_logic_1164.all;

entity input_ff is

  port (
    i_clk  : in  std_logic;
    i_res  : in  std_logic;
    i_din  : in  std_logic;
    o_dout : out std_logic
  );

end;

architecture rtl of input_ff is

  signal buried : std_logic;

begin

  process (i_res, i_clk)
  begin
    if i_res = '1' then
      buried <= '0';
      o_dout <= '0';
    elsif rising_edge(i_clk) then
      buried <= i_din;
      o_dout <= buried;
    end if;
  end process;

end;
