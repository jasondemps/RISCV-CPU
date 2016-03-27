library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.declares.all;

entity Branch_Predict is
  port (
    clock         : in  std_logic;
    mem_addr      : in  word_unsigned;
    instr         : in  word_unsigned;
    pbranch_value : out word_unsigned   -- Take = value, Not Take = 0
    );
end Branch_Predict;

architecture Sim_Branch_Predict of Branch_Predict is
  type branch_slot is record
    tag    : unsigned(10 downto 0);
    state  : unsigned(1 downto 0);
    target : unsigned(18 downto 0);
  end record;

  type branch_mem_t is array(0 to 1023) of branch_slot;
  signal mem : branch_mem_t := (state => "00", target => (others => '0'));
  --signal num_entries : integer := 0;

  signal slot : branch_slot;
begin

  process (clock)
  begin
    if rising_edge(clock) then
      slot <= mem(to_integer(mem_addr));
    end if;

    pbranch_value <= (others => '0');

    -- Check if it's actually a branch type instr && Check for a found slot
    if (instr(6 downto 0) = "1100011") then
      if (slot.tag /= (mem'range => '0')) then
        -- If we found something, do something I guess.
        -- FOR NOW: We'll always assume NOT TAKE (as per RISCV manual).
        pbranch_value <= (others => '0');
      else
        -- We didn't find the slot, we need to add it..
        mem(to_integer(mem_addr)) <= (
          tag => instr(31 downto 20),
          state => "00",
          target => (instr(31) & instr(7) & instr(30 downto 25) & instr(11 downto 8))
          );

      end if;
    end if;

  end process;

end Sim_Branch_Predict;
