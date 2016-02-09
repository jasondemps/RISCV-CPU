library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.declares.all;

entity rfile is
  port(
    clock                        : in  std_logic;
    data_wren                    : in  std_logic;
    addr_wr                      : in  unsigned(3 downto 0);
    data_wr                      : in  word_vector;
    addr_rd1, addr_rd2, addr_rd3 : in  unsigned(3 downto 0);
    data_rd1, data_rd2, data_rd3 : out word_vector
    );
end rfile;

architecture rfile of rfile is
  type reg_t is array(0 to 32) of word_vector;
  signal regs1, regs2, regs3        : reg_t := (others => x"00000000");
  signal fwd1, fwd2, fwd3           : boolean;
  signal bypass_data, rd1, rd2, rd3 : word_vector;

begin
  process(clock)

  begin
    if rising_edge(clock) then
      rd1 <= regs1(to_integer(addr_rd1));
      rd2 <= regs2(to_integer(addr_rd2));
      rd3 <= regs3(to_integer(addr_rd3));

      fwd1 <= false;
      fwd2 <= false;
      fwd3 <= false;

      if data_wren = '1' then
        regs1(to_integer(wadr)) <= data_wr;
        regs2(to_integer(wadr)) <= data_wr;
        regs3(to_integer(wadr)) <= data_wr;

        fwd1 <= (addr_wr = addr_rd1);
        fwd2 <= (addr_wr = addr_rd2);
        fwd3 <= (addr_wr = addr_rd3);

        bypass_data <= data_wr;
      end if;

    end if;
  end process;

  data_rd1 <= bypass_data when fwd1 else rd1;
  data_rd2 <= bypass_data when fwd2 else rd2;
  data_rd3 <= bypass_data when fwd3 else rd3;
end rfile;


