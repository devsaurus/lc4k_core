
library ieee;
use ieee.std_logic_1164.all;

entity reg_pipe is

  generic (
    g_num_internal : natural := 4
  );
  port (
    i_clk : in  std_logic;
    i_ce  : in  std_logic;
    i_res : in  std_logic;
    i_d   : in  std_logic_vector(7 downto 0);
    o_d   : out std_logic_vector(7 downto 0);
    o_or  : out std_logic
  );

end;

architecture rtl of reg_pipe is

  subtype reg_t is std_logic_vector(i_d'range);
  type reg_pipe_t is array (natural range 0 to g_num_internal+1) of reg_t;
  signal reg_pipe_q : reg_pipe_t;

begin

  reg_p : process (i_clk, i_res)
  begin
    if i_res = '1' then
      reg_pipe_q <= (others => (others => '0'));

    elsif rising_edge(i_clk) then
      if i_ce = '1' then
        reg_pipe_q(0) <= i_d;

        for stage in 1 to reg_pipe_q'high loop
          reg_pipe_q(stage) <= reg_pipe_q(stage-1);
        end loop;
      end if;

    end if;
  end process;


  or_p : process (reg_pipe_q)
    variable or_vec : reg_t;
    variable or_v : std_logic;
  begin
    or_vec := (others => '0');
    for stage in reg_pipe_q'range loop
      or_vec := or_vec or reg_pipe_q(stage);
    end loop;

    or_v := '0';
    for idx in reg_t'range loop
      or_v := or_v or or_vec(idx);
    end loop;

    o_or <= or_v;
  end process;

  o_d <= reg_pipe_q(reg_pipe_q'high);

end;
