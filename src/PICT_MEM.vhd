--------------------------------------------------------------------------------
-- PICT MEM
-- Anders Nilsson
-- 16-feb-2016
-- Version 1.1


-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type


-- entity
entity PICT_MEM is
  port ( clk		: in std_logic;
    -- port 1
      we1		: in std_logic;
      data_in1	: in std_logic_vector(7 downto 0);
    --  data_out1	: out std_logic_vector(7 downto 0);
    --  addr1		: in unsigned(10 downto 0);
    -- port 2
    we2		: in std_logic;
    data_in2	: in std_logic_vector(7 downto 0);
    data_out2	: out std_logic_vector(7 downto 0);
    addr2		: in unsigned(10 downto 0));
    
end PICT_MEM;


-- architecture
architecture Behavioral of PICT_MEM is

  -- picture memory type
  type ram_t is array (0 to 2047) of std_logic_vector(7 downto 0);
  -- initiate picture memory to one cursor ("1F") followed by spaces ("00")
  signal pictMem : ram_t := (0 => x"01", others => (others => '0'));


begin

  process(clk)
  begin
    if rising_edge(clk) then
       if (we1 = '1') then
         pictMem(0) <= data_in1;
       end if;
--       data_out1 <= pictMem(0);

      if (we2 = '1') then
        pictMem(to_integer(addr2)) <= data_in2;
      end if;
      data_out2 <= pictMem(to_integer(addr2));
    end if;
  end process;


end Behavioral;
