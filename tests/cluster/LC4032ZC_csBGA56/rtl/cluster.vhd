
library ieee;
use ieee.std_logic_1164.all;

entity cluster is

  port (
    i_in  : in  std_logic_vector(15 downto 0);
    o_out : out std_logic
  );

end;

architecture rtl of cluster is

begin

  process (i_in)
    variable res : std_logic;
  begin
    res := '0';

    for idx in 0 to i_in'length/2 - 1 loop
      res := res or (i_in(idx) xor i_in(idx + i_in'length/2));
    end loop;

    o_out <= res;

  end process;

end;
