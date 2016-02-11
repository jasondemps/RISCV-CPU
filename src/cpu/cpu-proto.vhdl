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
    clock         : in  std_logic;
    -- Memory Interface
    mem_addr      : out word_unsigned;
    mem_data      : in  word_unsigned;
    mem_stall     : in  std_logic
    -- Branch Prediction Interface
    pbranch_addr  : out word_unsigned;
    pbranch_value : in  word_unsigned
    );
end CPU;

architecture Sim_CPU of CPU is
  signal pc     : word_unsigned := (others => "0");
  signal pc_val : word_unsigned;

  -- Branch Signals
  signal branch_target : word_unsigned;

  signal branch_mux   : word_unsigned;
  signal branch_cntrl : std_logic;

  signal mem_addr : word_unsigned;
  signal mem_data : word_unsigned;

  signal pc_incr : word_unsigned;

  -- Registers
  signal reg_addr1 : word_unsigned;
  signal reg_addr2 : word_unsigned;

  signal exec_instr : word_unsigned;
begin

  -- FETCH
  branch_cntrl <= or_reduce(pred_branch);

  with branch_ctrl select branch_mux <=
    pbranch_value when '0',
    branch_target when '1';

  with or_reduce(branch_mux) select pc_val <=
    pc_incr    when '0',
    branch_mux when '1';

  -- This will need to multiplex, eventually, as we need to access memory at
  -- different stages within the pipeline.
  mem_addr <= pc;

  process(clock)
  begin
    if rising_edge(clock) then
      pc <= pc_val;
    end if;

    pc_incr <= pc + 4;
  end process;

  -- DECODE
  -- Perform stall and prime the register file.
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

    -- EXECUTE
    -- Perform operation based on opcode, also determine actual branch target.
    process(exec_instr, reg_data1, reg_data2)

    begin

    end process;


  end Sim_CPU;
