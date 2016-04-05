library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
  generic (bits : integer);
  port (address    : in  unsigned(31 downto 0);
        data       : out unsigned(31 downto 0);
        clock      : in  std_logic;
        hits, miss : out integer);
end cache;

-- 2-way strategy
architecture two_way_strat of cache is
  type cache_t is array(0 to 2**bits-1) of unsigned(31 downto bits+2);
  type lra_t is array(0 to 2**bits-1) of std_logic;
  signal cache0, cache1 : cache_t := (others => to_unsigned(0, 30-bits));
  signal lra            : lra_t   := (others => '0');
begin
  process(clock)
    variable addr         : integer;
    variable vhits, vmiss : integer := 0;
    variable msbits       : unsigned(31 downto bits+2);
  begin
    if(rising_edge(clock)) then
      addr   := to_integer(address(bits+1 downto 2));
      msbits := address(31 downto bits+2);
      if cache0(addr) = msbits then
        vhits     := vhits + 1;
        lra(addr) <= '0';
      elsif cache1(addr) = msbits then
        vhits     := vhits + 1;
        lra(addr) <= '1';
      else                              -- miss
        vmiss := vmiss + 1;
        if lra(addr) = '1' then
          cache0(addr) <= msbits;
          lra(addr)    <= '0';
        else
          cache1(addr) <= msbits;
          lra(addr)    <= '1';
        end if;
      end if;
    end if;
    hits <= vhits;
    miss <= vmiss;
  end process;
end two_way_strat;
