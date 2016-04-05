
-- TODO: Could expand this such that take in an array of signal sources.
--     : Can then determine size and create n number of buffers and outputs.
entity FIFO
  generic(
    MAX_LEN : integer;
    DATA_LEN : integer
    );
port(
signal input : )
end FIFO;

architecture FIFO_synth of FIFO is
  type fifo_t is array (0 to MAX_LEN) of unsigned(DATA_LEN downto 0);
  signal buf : fifo_t;
begin


end FIFO_synth;
