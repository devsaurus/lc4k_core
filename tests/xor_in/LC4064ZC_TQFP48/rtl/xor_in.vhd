
library ieee;
use ieee.std_logic_1164.all;

entity xor_in is

  port (
    i_xor : in  std_logic_vector(29 downto 0);
    o_out : out std_logic
  );

end;

architecture rtl of xor_in is

begin

  process (i_xor)
    variable sig : std_logic;
  begin
    sig := '0';
    for idx in i_xor'range loop
      sig := sig xor i_xor(idx);
    end loop;
    o_out <= sig;
  end process;

end;
