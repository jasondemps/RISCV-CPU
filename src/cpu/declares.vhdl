library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package declares is
  constant word : integer := 32;

  type word_vector is array (0 to word-1) of std_logic; --std_logic_vector(word-1 downto 0);
  subtype word_unsigned is unsigned(word-1 downto 0);
  subtype word_signed is signed(word-1 downto 0);

  constant NOP  : word_unsigned := to_unsigned(0, word);

end declares;
