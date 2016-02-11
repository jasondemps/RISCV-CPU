library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

package declares is
  constant word : integer := 32;

  type word_vector is std_logic_vector(word-1 downto 0);
  type word_unsigned is unsigned(word-1 downto 0);
  type word_signed is signed(word-1 downto 0);

  constant NOP  : word_unsigned := (others => "0");

end declares;
