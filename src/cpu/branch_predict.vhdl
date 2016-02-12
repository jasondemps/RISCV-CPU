library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.declares.all;

entity Branch_Predict is
  port (
    clock         : in  std_logic;
    mem_addr      : in  word_unsigned;
    pbranch_value : out word_unsigned
    );
end Branch_Predict;

architecture Sim_Branch_Predict of Branch_Predict is
  type branch_slot is record
    tag    : unsigned(10 downto 0);
    state  : unsigned(1 downto 0);
    target : unsigned(18 downto 0);
  end record;

  type branch_mem_t is array(0 to 1023) of branch_slot;
  signal mem : branch_mem_t;
begin

  process (clock)

  begin
    if rising_edge(clock) then
      <= mem(to_integer(mem_addr));
    end if;

  end process;

end Sim_Branch_Predict;
