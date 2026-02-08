
library ieee;
use ieee.std_logic_1164.all;

entity initialization is

  port (
    i_clk     : in  std_logic;
    i_async_a : in  std_logic;
    i_async_b : in  std_logic;
    i_din     : in  std_logic_vector(15 downto 0);
    o_dout    : out std_logic_vector(15 downto 0)
  );

end;

architecture rtl of initialization is

  signal async : std_logic;

begin

  async <= i_async_a and i_async_b;

  process (i_clk, async)
  begin
    if async = '1' then
      -- set/reset
      for idx in o_dout'range loop
        if idx mod 2 = 0 then
          o_dout(idx) <= '0';
        else
          o_dout(idx) <= '1';
        end if;
      end loop;

    elsif rising_edge(i_clk) then
      o_dout <= i_din;

    end if;
  end process;

end;
