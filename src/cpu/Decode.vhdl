library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

use work.helpers.all;
use work.declares.all;

entity Decode is
  port(
    clock                           : in     std_logic;
    stall                           : buffer std_logic := '0';
    im_instr                        : in     unsigned(31 downto 0);
    reg_addr1, reg_addr2, reg_addr3 : out    unsigned(4 downto 0);
    instr                           : out    unsigned(31 downto 0)
    );
end Decode;

architecture Decode of Decode is
  type stall_state_t is (Off, Init, Done);

  signal stall_state : stall_state_t := Off;
  signal stall_instr : unsigned(31 downto 0);
begin

  process(im_instr, stall_state)

  begin
    stall     <= '0';
    reg_addr1 <= (others => '0');
    reg_addr2 <= (others => '0');
    reg_addr3 <= (others => '0');

    -- State machine
    case stall_state is
      when Off =>
        stall <= '0';

        case? im_instr(6 downto 0) is
          -- Branch
          when "1100011" =>
            reg_addr1 <= im_instr(19 downto 15);
            reg_addr2 <= im_instr(24 downto 20);

          -- Load
          when "0000011" =>
            -- Stall?
            stall <= '1';

          -- Store
          when "0100011" =>
            reg_addr2 <= im_instr(24 downto 20);

          -- Arith Imm
          when "0010011" =>
            reg_addr1 <= im_instr(19 downto 15);
            reg_addr3 <= im_instr(11 downto 7);

          -- Arith Regs + Mult Regs
          when "011-011" =>
            reg_addr1 <= im_instr(19 downto 15);
            reg_addr2 <= im_instr(24 downto 20);
            reg_addr3 <= im_instr(11 downto 7);

          when others =>
        end case?;

      when Init =>
      when Done =>
        stall <= '0';

    end case;

  end process;


  process (clock)

  begin
    -- Progress the state machine
    if rising_edge(clock) then
      instr <= im_instr;

      if stall then
        instr <= NOP;

        case stall_state is
          when Off =>
            stall_state <= Init;
          when Init =>
            stall_instr <= im_instr;
            stall_state <= Done;
          when Done =>
            stall_state <= Off;
            instr       <= stall_instr;
        end case;
      else
        stall_state <= Off;
      end if;
    end if;
  end process;

end Decode;
