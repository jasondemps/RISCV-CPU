library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.helpers.all;

entity Fetch is
  port(
    clock        : in     std_logic;
    -- take_branch : in 
    branch_value : in     signed(31 downto 0); --signed(11 downto 1);
    stall        : in     std_logic;
    im_addr      : buffer unsigned(31 downto 0);
    pc           : buffer unsigned(31 downto 0) := (others => '0')
    );
end Fetch;

architecture Fetch of Fetch is
  --branch_cntrl <= or_reduce(std_logic_vector(pbranch_value)); --pred_branch);

  --with branch_cntrl select branch_mux <=
  --  pbranch_value when '0',
  --  branch_target when '1';

  --with or_reduce(std_logic_vector(branch_mux)) select pc_val <=
  --  pc_incr    when '0',
  --  branch_mux when '1';

  ---- This will need to multiplex, eventually, as we need to access memory at
  ---- different stages within the pipeline.
  --mem_addr <= pc;

  --process(clock)
  --begin
  --  if rising_edge(clock) then
  --    pc <= pc_val;
  --  end if;

  --  pc_incr <= pc + 4;
  --end process;

   signal pc_tmp : unsigned(31 downto 0) := (others => '0');
begin
  -- pc <= pc_tmp;

  --im_addr <= unsigned(signed(pc) + branch_value);
  with stall select im_addr <=
    unsigned(signed(pc) + branch_value) when '0',
    unsigned(signed(pc))                when others;

  --im_addr <= pc_tmp;

  process(clock)
  begin
    if rising_edge(clock) then
      pc <= im_addr;
    --if stall = '0' then
    --  pc_tmp <= unsigned(signed(pc_tmp) + branch_value);
    --end if;
    end if;
  end process;

end Fetch;
