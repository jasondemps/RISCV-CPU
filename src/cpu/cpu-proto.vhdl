library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.declares.all;

entity CPU is
  port(
    clock : in std_logic;

    );
end CPU;

architecture Sim_CPU of CPU is
  signal pc : unsigned(word-1 downto 0) := (others => "0");
  signal pc_val : unsigned(word-1 downto 0);

  -- Branch Signals
  signal pred_branch : unsigned(word-1 downto 0);
  signal branch_target : unsigned(word-1 downto 0);

  signal branch_mux : unsigned(word-1 downto 0);
  signal branch_cntrl : std_logic;
begin

  -- FETCH
  branch_cntrl <= or_reduce(pred_branch);

  with branch_ctrl select branch_mux <=
    pred_branch when '0',
    branch_target when '1';

  with or_reduce(branch_mux) select pc_val <=
    pc + 4 when '0',
    branch_mux when '1';

  process(clock)
  begin
    if rising_edge(clock) then
      pc <= pc_val;
    end if;
  end process;


end Sim_CPU;
