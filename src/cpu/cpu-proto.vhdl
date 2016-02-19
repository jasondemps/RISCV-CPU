library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.all;

use work.declares.all;
use work.Utility.all;
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
    -- Immediates based on Instruction Type
    variable imm11 : signed(11 downto 0);
    variable shamt : unsigned(4 downto 0);
    variable offI  : unsigned(11 downto 0);
    variable offS  : unsigned(11 downto 0);
    variable immUJ : unsigned(19 downto 0);
    variable immU  : unsigned(18 downto 0);

    -- Branch stuff
    variable take_branch : std_logic;

  begin
    take_branch := '0';

    imm11 := exec_instr(31 downto 20);
    shamt := exec_instr(4 downto 0);
    offI  := exec_instr(31 downto 20);
    offS  := exec_instr(31 downto 25) & exec_instr(11 downto 7);
    immUJ := exec_instr(31) & exec_instr(19 downto 12) & exec_instr(20) & exec_instr(30 downto 21);
    immU  := exec_instr(31 downto 12);

    -- Check for stall also?
    if exec_instr \= NOP and load_stall = '0' then
      case? mem_instr(6 downto 0) is
        when "0110111" =>               -- LUI
          reg_data3 <= to_unsigned(exec_instr(31 downto 12), 32);

        when "0010111" =>               -- AUIPC
          reg_data3 <= to_unsigned(exec_instr(31 downto 12), 32) + pc;

        when "1101111" =>               -- JAL
          reg_data3 <= pc + 4;
          pc        <= immUJ;

        when "1100111" =>               -- JALR
          reg_data3 <= pc + 4;
          pc        <= immU + reg_data1;

        -- Branch
        when "1100011" =>
          case mem_instr(14 downto 12) is
            when "000" =>               -- BEQ
              take_branch <= reg_data1 = reg_data2;
            when "001" =>               -- BNE
              take_branch <= reg_data1 \= reg_data2;
            when "100" =>               -- BLT
              take_branch <= signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2));
            when "101" =>               -- BGE
              take_branch <= signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2));
            when "110" =>               -- BLTU
              take_branch <= reg_data1 < reg_data2;
            when "111" =>               -- BGEU
              take_branch <= reg_data1 >= reg_data2;
            when others =>              -- Undefined...
              take_branch := '0';
          end case;
        -- Load
        when "0000011" =>
          case mem_instr(14 downto 12) is
            when "000"  =>              -- LB
            when "001"  =>              -- LH
            when "010"  =>              -- LW
            when "100"  =>              -- LBU
            when "101"  =>              -- LHU
            when others =>              -- Undefined
          end case;
        -- Store
        when "0100011" =>
          case mem_instr(14 downto 12) is
            when "000"  =>              -- SB
            when "001"  =>              -- SH
            when "010"  =>              -- SW
            when others =>              -- Undefined
          end case;

        -- Arith Imm
        when "0010011" =>
          case mem_instr(14 downto 12) is
            when "000" =>                   -- ADDI
              reg_data3 <= to_unsigned(signed(std_logic_vector(reg_data1) + signed(std_logic_vector(reg_data1));
            when "001" =>                   -- SLLI
              reg_data3 <= reg_data1 sll shamt;
            when "010" =>                   -- SLTI
              reg_data3 <= to_unsigned(signed(std_logic_vector(reg_data1) < imm11);
            when "011" =>                   -- SLTIU
              reg_data3 <= to_unsigned(reg_data1 < imm11);
            when "100" =>                   -- XORI
              reg_data3 <= to_unsigned(reg_data1 xor imm11);
            when "101" =>                   -- SRLI / SRAI
              if exec_instr(30) = '0' then  -- SRLI
                reg_data3 <= to_unsigned(reg_data1 srl imm11);
              else                          -- SRAI
                reg_data3 <= to_unsigned(reg_data1 sla imm11);
              end if;
            when "111" =>                   -- ANDI
              reg_data3 <= to_unsigned(reg_data and imm11);
          end case;
        -- Arith Regs
        when "0110011" =>
          case mem_instr(14 downto 12) is
            when "000" =>                   -- ADD / SUB
              if exec_instr(30) = '0' then  -- ADD
                reg_data3 <= reg_data1 + reg_data2;
              else                          -- SUB
                reg_data3 <= reg_data1 - reg_data2;
              end if;
            when "001" =>                   -- SLL
              reg_data3 <= reg_data1 sll to_integer(reg_data2);
            when "010" =>                   -- SLT
              reg_data3 <= to_unsigned(signed(std_logic_vector(reg_data1) < signed(std_logic_vector(reg_data2));
            when "011" =>                   -- SLTU
              reg_data3 <= reg_data1 < reg_data2;
            when "100" =>                   -- XOR
              reg_data3 <= reg_data1 xor reg_data2;
            when "101" =>                   -- SRL / SRA
              if exec_instr(0) then         -- SRL
                reg_data3 <= reg_data1 srl to_integer(reg_data2(4 downto 0));
              else                          -- SRA
                reg_data3 <= reg_data1 sra to_integer(reg_data2(4 downto 0));
              end if;
            when "110" =>                   -- OR
              reg_data3 <= reg_data1 or reg_data2;
            when "111" =>                   -- AND
              reg_data3 <= reg_data1 and reg_data2;
          end case;
        -- Arith Mult Regs
        when "0111011" =>
          case mem_instr(14 downto 12) is
            when "000" =>                   -- MUL
              reg_data3 <= to_unsigned((signed(std_logic_vector(reg_data1) * signed(std_logic_vector(reg_data2))(31 downto 0));
            when "001" =>                   -- MULH
              reg_data3 <= to_unsigned((signed(std_logic_vector(reg_data1) * signed(std_logic_vector(reg_data2))(63 downto 32));
            when "010" =>                   -- MULHSU
              reg_data3 <= to_unsigned((signed(std_logic_vector(reg_data1) * reg_data2)(63 downto 32));
            when "011" =>                   -- MULHU
              reg_data3 <= (reg_data1 * reg_data2)(63 downto 32);
            when "100" =>                   -- DIV
              reg_data3 <= to_unsigned(signed(std_logic_vector(reg_data1) / signed(std_logic_vector(reg_data2));
            when "101" =>                   -- DIVU
              reg_data3 <= reg_data1 / reg_data2;
            when "110" =>                   -- REM
            when "111" =>                   -- REMU
          end case;
      end case?;
    end if
  end process;


end Sim_CPU;
