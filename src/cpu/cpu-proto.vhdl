library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.declares.all;

-- Try to keep a generic interface for interacting with the cache/memory mechanism
-- I'll probably have an external memory controller on the outside to
-- facilitate cache + SDRAM/main memory stuff

-- Stalling comes from: Memory interface and Decode for load/store
entity CPU is
  port(
    clock     : in  std_logic;
    -- Memory Interface
    mem_addr  : out unsigned(word-1 downto 0);
    mem_data  : in  unsigned(word-1 downto 0);
    mem_stall : in  std_logic;

    );
end CPU;

architecture Sim_CPU of CPU is
  signal pc     : unsigned(word-1 downto 0) := (others => "0");
  signal pc_val : unsigned(word-1 downto 0);

  -- Branch Signals
  signal pred_branch   : unsigned(word-1 downto 0);
  signal branch_target : unsigned(word-1 downto 0);

  signal branch_mux   : unsigned(word-1 downto 0);
  signal branch_cntrl : std_logic;

  signal mem_addr : unsigned(word-1 downto 0);
  signal mem_data : unsigned(word-1 downto 0);

begin

  -- FETCH
  branch_cntrl <= or_reduce(pred_branch);

  with branch_ctrl select branch_mux <=
    pred_branch   when '0',
    branch_target when '1';

  with or_reduce(branch_mux) select pc_val <=
    pc + 4     when '0',
    branch_mux when '1';

  -- This will need to multiplex, eventually, as we need to access memory at
  -- different stages within the pipeline.
  mem_addr <= pc;

  process(clock)
  begin
    if rising_edge(clock) then
      pc <= pc_val;
    end if;
  end process;

  -- DECODE
  process(mem_data)
  begin
    -- TODO: Handle Stall
    case? mem_data(6 downto 0) is
      -- Branch
      when "1100011" =>

      -- Load
      when "0000011" =>

      -- Store
      when "0100011" =>

      -- Arith Imm
      when "0010011" =>

      -- Arith Regs
      when "0110011" =>

    end process;


  end Sim_CPU;
