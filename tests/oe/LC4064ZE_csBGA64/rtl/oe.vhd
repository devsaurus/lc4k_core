
library ieee;
use ieee.std_logic_1164.all;

entity oe is

  port (
    i_clk : in  std_logic;
    i_res : in  std_logic;
    i_oe  : in  std_logic;
    i_d   : in  std_logic_vector(7 downto 0);
    o_d   : out std_logic_vector(7 downto 0)
  );

end;

architecture rtl of oe is

  signal data : std_logic_vector(i_d'range);

begin

  process (i_clk, i_res)
  begin
    if i_res = '1' then
      data <= (others => '0');
    elsif rising_edge(i_clk) then
      data <= i_d;
    end if;
  end process;

  process (data, i_oe)
  begin
    if i_oe = '1' then
      o_d(3 downto 0) <= data(3 downto 0);
    else
      o_d(3 downto 0) <= (others => 'Z');
    end if;

    for idx in 4 to 7 loop
      if data(idx-4) = '1' then
        o_d(idx) <= data(idx);
      else
        o_d(idx) <= 'Z';
      end if;
    end loop;
  end process;

end;
