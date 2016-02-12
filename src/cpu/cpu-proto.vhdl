library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.declares.all;

use work.instrset.all;

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

  signal mem_addr  : word_unsigned;
  signal mem_instr : word_unsigned;

  signal pc_incr : word_unsigned;

  -- Registers
  signal reg_addr1 : word_unsigned;     -- Reg Source 1
  signal reg_addr2 : word_unsigned;     -- Reg Source 2
  signal reg_addr3 : word_unsigned;     -- Reg Destination

  signal exec_instr : word_unsigned;

  type stall_state is (idle, init, done);
  signal load_stall : unsigned(1 downto 0);
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
  process(mem_instr)
  begin
    -- TODO: Handle Stall
    case? mem_instr(6 downto 0) is
      -- Branch
      when "1100011" =>
        reg_addr1 <= mem_instr(19 downto 15);
        reg_addr2 <= mem_instr(24 downto 20);

      -- Load
      when "0000011" =>
        -- Stall?
        load_stall <= 1;

      -- Store
      when "0100011" =>
        reg_addr2 <= mem_instr(24 downto 20);

      -- Arith Imm
      when "0010011" =>
        reg_addr1 <= mem_instr(19 downto 15);
        reg_addr3 <= mem_instr(11 downto 7);

      -- Arith Regs + Mult Regs
      when "011-011" =>
        reg_addr1 <= mem_instr(19 downto 15);
        reg_addr2 <= mem_instr(24 downto 20);
        reg_addr3 <= mem_instr(11 downto 7);

    end case?;
  end process;

  -- Stall FSM
  process(load_stall)

  begin
    case (load_stall) is
      when idle =>
      when init =>
      when done =>
    end case;
  end process;

  -- EXECUTE
  -- Perform operation based on opcode, also determine actual branch target.
  process(exec_instr, reg_data1, reg_data2, reg_data3)

  begin
    if ~(exec_instr = NOP) then
      case? mem_instr(6 downto 0) is
        -- Branch
        when "1100011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when "011" =>
            when "100" =>
            when "101" =>
            when "110" =>
            when "111" =>
          end case;
        -- Load
        when "0000011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when "011" =>
            when "100" =>
            when "101" =>
            when others =>
          end case;
        -- Store
        when "0100011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when others =>
          end case;

        -- Arith Imm
        when "0010011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when "011" =>
            when "100" =>
            when "101" =>
            when others =>
          end case;
        -- Arith Regs
        when "0110011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when "011" =>
            when "100" =>
            when "101" =>
            when "110" =>
            when "111" =>
          end case;
        -- Arith Mult Regs
        when "0111011" =>
          case mem_instr(14 downto 12) is
            when "000" =>
            when "001" =>
            when "010" =>
            when "011" =>
            when "100" =>
            when "101" =>
            when "110" =>
            when "111" =>
          end case;
      end case?;
    end if
  end process;


end Sim_CPU;
