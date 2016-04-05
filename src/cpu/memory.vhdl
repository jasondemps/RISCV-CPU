library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Encompasses both Cache and Main Memory modules
-- One, unified interface to access data.
-- We could queue this with a FIFO and use an FSM.
entity Memory is
  port(
    clk : in std_logic
    );
end Memory;

architecture Memory_test of Memory is

begin

  process(clk)
  begin

  end process;

end Memory_test;
