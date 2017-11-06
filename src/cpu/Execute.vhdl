library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;

--use work.helpers.all;
use work.declares.all;
--use work.instr_set.all;

entity Execute is
  port(
    clock                           : in     std_logic;
    instr                           : in     unsigned(31 downto 0);
    reg_data1, reg_data2, reg_data3 : in     unsigned(31 downto 0);
    pc                              : in     unsigned(31 downto 0);
    pc_out                          : buffer signed(31 downto 0);
    defer_load                      : out    std_logic;
    take_branch                     : buffer boolean;  --std_logic;
    --branch_value                    : out    signed(10 downto 0);
    wadr                            : out    unsigned(4 downto 0);
    wdata                           : out    unsigned(31 downto 0);
    rf_wr                           : out    std_logic;
    dm_addr                         : out    unsigned(31 downto 2);
    dm_data_wr                      : out    unsigned(31 downto 0);
    dm_we                           : out    std_logic
    );
end Execute;

architecture Execute of Execute is
  signal pc_tmp : signed(31 downto 0);

  attribute multstyle            : string;
  attribute multstyle of Execute : architecture is "dsp";
begin

-- EXECUTE
  -- Perform operation based on opcode, also determine actual branch target.
  process(instr, pc, reg_data1, reg_data2, reg_data3)
    -- Immediates based on Instruction Type
    variable imm12 : signed(11 downto 0);
    variable shamt : unsigned(4 downto 0);
    variable offI  : unsigned(11 downto 0);
    variable offS  : unsigned(11 downto 0);
    variable offSB : unsigned(11 downto 0);
    variable immUJ : unsigned(19 downto 0);
    variable immU  : unsigned(19 downto 0);

    -- Destination Reg.
    variable rd : unsigned(11 downto 7);

    -- Branch stuff
    --variable take_branch : std_logic;

    -- Memory Stuff
    --variable mem_addr  : word_unsigned;
    --variable mem_data  : word_unsigned;
    --variable mem_write : std_logic;
    --variable mem_instr : unsigned(2 downto 0);

    --variable pc_var : unsigned(31 downto 0);

  begin
    take_branch <= false;               --'0';
    defer_load  <= '0';

    imm12 := to_signed(to_integer(instr(31 downto 20)), imm12'length);
    shamt := instr(4 downto 0);
    offI  := instr(31 downto 20);
    offS  := instr(31 downto 25) & instr(11 downto 7);
    offSB := instr(12) & instr(7) & instr(30 downto 25) & instr(11 downto 8);
    immUJ := instr(31) & instr(19 downto 12) & instr(20) & instr(30 downto 21);
    immU  := instr(31 downto 12);

    rd := instr(11 downto 7);

    --mem_addr  := (others => '0');
    --mem_data  := (others => '0');
    --mem_instr := (others => '0');
    --mem_write := '0';

    wadr       <= (others => '0');
    wdata      <= (others => '0');
    rf_wr      <= '0';
    dm_addr    <= (others => '0');
    dm_data_wr <= (others => '0');
    dm_we      <= '0';

    pc_tmp <= (others => '0');          --pc;

    -- Check for stall also?
    if instr /= NOP then
      if xor_reduce(std_logic_vector(instr)) /= 'U' and xor_reduce(std_logic_vector(instr)) /= 'X' then
        case? instr(6 downto 0) is
          when "0110111" =>             -- LUI
            wadr  <= rd;
            wdata <= immU & resize("0", 12);  --to_unsigned(instr(31 downto 12), 32);

          when "0010111" =>             -- AUIPC
            wadr  <= rd;
            wdata <= (immU & resize("0", 12)) + pc;

          when "1101111" =>             -- JAL
            wadr   <= rd;
            wdata  <= pc + 4;
            pc_tmp <= to_signed(to_integer(pc), pc'length) + to_signed(to_integer(immUJ), immUJ'length);

          when "1100111" =>             -- JALR
            wadr   <= rd;
            wdata  <= pc + 4;
            pc_tmp <= (to_signed(to_integer(immU), immU'length) + to_signed(to_integer(reg_data1), reg_data1'length)) and X"FFFFE";

          -- Branch
          when "1100011" =>
            case instr(14 downto 12) is
              when "000" =>             -- BEQ
                take_branch <= (reg_data1 = reg_data2);
              when "001" =>             -- BNE
                take_branch <= reg_data1 /= reg_data2;
              when "100" =>             -- BLT
                take_branch <= signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2));
              when "101" =>             -- BGE
                take_branch <= signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2));
              when "110" =>             -- BLTU
                take_branch <= reg_data1 < reg_data2;
              when "111" =>             -- BGEU
                take_branch <= reg_data1 >= reg_data2;
              when others =>            -- Undefined...
                take_branch <= false;   --'0';
            end case;

          -- Load
          when "0000011" =>
            case instr(14 downto 12) is
              when "000" | "001" | "010" | "100" | "101" =>
                dm_addr    <= to_unsigned(to_integer(to_signed(to_integer(instr(19 downto 15)), instr(19 downto 15)'length) + imm12), dm_addr'length);
                dm_we      <= '0';
                dm_data_wr <= resize(rd, dm_data_wr'length);
                defer_load <= '1';
              when others =>            -- Undefined
            end case;

          -- Store
          when "0100011" =>
            case instr(14 downto 12) is
              when "000" | "001" | "010" =>  -- SB / SH / SW
                dm_addr    <= resize(instr(19 downto 15) + offS, dm_addr'length);  --resize(reg_data2 + reg_data3, dm_addr'length);
                dm_we      <= '1';
                dm_data_wr <= reg_data2;
              when others =>            -- Undefined
            end case;

          -- Arith Imm
          when "0010011" =>
            wadr <= rd;
            rf_wr <= '1';

            case instr(14 downto 12) is
              when "000" =>              -- ADDI
                wdata <= unsigned(signed(std_logic_vector(reg_data1)) + imm12);
              when "001" =>              -- SLLI
                wdata <= reg_data1 sll to_integer(shamt);
              when "010" =>              -- SLTI
                if signed(std_logic_vector(reg_data1)) < imm12 then
                  wdata <= to_unsigned(1, wdata'length);
                else
                  wdata <= to_unsigned(0, wdata'length);
                end if;
              when "011" =>              -- SLTIU
                if unsigned(std_logic_vector(reg_data1)) < to_unsigned(to_integer(imm12), imm12'length) then
                  wdata <= to_unsigned(1, wdata'length);
                else
                  wdata <= to_unsigned(0, wdata'length);
                end if;
              when "100" =>              -- XORI
                wdata <= unsigned(signed(std_logic_vector(reg_data1)) xor imm12);
              when "101" =>              -- SRLI / SRAI
                if instr(30) = '0' then  -- SRLI
                  wdata <= unsigned(signed(std_logic_vector(reg_data1)) srl to_integer(imm12));
                --else                     -- SRAI
                --  wdata <= unsigned(signed(std_logic_vector(reg_data1)) sla to_integer(imm12));
                end if;
              when "111" =>              -- ANDI
                wdata <= unsigned(signed(std_logic_vector(reg_data1)) and imm12);
              when others =>
            end case;

          -- Arith Regs
          when "0110011" =>
            wadr <= rd;
            rf_wr <= '1';

            case instr(14 downto 12) is
              when "000" =>              -- ADD / SUB
                if instr(30) = '0' then  -- ADD
                  wdata <= reg_data1 + reg_data2;
                else                     -- SUB
                  wdata <= reg_data1 - reg_data2;
                end if;
              when "001" =>              -- SLL
                wdata <= reg_data1 sll to_integer(reg_data2);
              when "010" =>              -- SLT
                if signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2)) then
                  wdata <= to_unsigned(1, wdata'length);
                else
                  wdata <= to_unsigned(0, wdata'length);
                end if;

              --wdata <= unsigned(signed(std_logic_vector(reg_data1)) < signed(std_logic_vector(reg_data2)));
              when "011" =>             -- SLTU
                if unsigned(std_logic_vector(reg_data1)) < unsigned(std_logic_vector(reg_data2)) then
                  wdata <= to_unsigned(1, wdata'length);
                else
                  wdata <= to_unsigned(0, wdata'length);
                end if;

--                wdata <= reg_data1 < reg_data2;
              when "100" =>             -- XOR
                wdata <= reg_data1 xor reg_data2;
              when "101" =>             -- SRL / SRA
                if instr(0) then        -- SRL
                  wdata <= reg_data1 srl to_integer(reg_data2(4 downto 0));
                --else                    -- SRA
                --  wdata <= reg_data1 sra to_integer(reg_data2(4 downto 0));
                end if;
              when "110" =>             -- OR
                wdata <= reg_data1 or reg_data2;
              when "111" =>             -- AND
                wdata <= reg_data1 and reg_data2;
              when others =>
            end case;
                                        -- Arith Mult Regs
          when "0111011" =>
            rf_wr <= '1';

            case instr(14 downto 12) is
              when "000" =>             -- MUL
                wdata <= unsigned(signed(std_logic_vector(reg_data1(15 downto 0))) * signed(std_logic_vector(reg_data2(15 downto 0))));
              when "001" =>             -- MULH
                wdata <= unsigned(signed(std_logic_vector(reg_data1(31 downto 16))) * signed(std_logic_vector(reg_data2(31 downto 16))));
              when "010" =>             -- MULHSU
                wdata <= unsigned(signed(std_logic_vector(reg_data1(31 downto 16))) * signed(std_logic_vector(reg_data2(31 downto 16))));
              when "011" =>             -- MULHU
                wdata <= reg_data1(31 downto 16) * reg_data2(31 downto 16);
              when "100" =>             -- DIV
                wdata <= reg_data1 / reg_data2;  --unsigned(signed(std_logic_vector(reg_data1)) / signed(std_logic_vector(reg_data2)));
              when "101" =>             -- DIVU
                wdata <= reg_data1 / reg_data2;
              when "110" =>             -- REM
                wdata <= reg_data1 mod reg_data2;
              when "111" =>             -- REMU
                wdata <= reg_data1 mod reg_data2;
              when others =>
            end case;

          when others =>
        end case?;

        -- If we're branching, let's do it.
        if take_branch then
          pc_tmp <= to_signed(to_integer(offSB), pc_tmp'length);
        end if;
      end if;
    end if;
  end process;

  process (pc_tmp)
  begin
    pc_out <= pc_tmp;  --to_unsigned(to_integer(pc_tmp), pc_tmp'length);
  end process;

end Execute;
