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
    port (  clk		  : in std_logic;
		    rst		  : in std_logic;
            we1       : in std_logic;
            data_in1  : in std_logic_vector(7 downto 0);
            save_at   : in integer range 0 to 1200;
            data_out2 : out std_logic_vector(7 downto 0);
            addr2     : in unsigned(12 downto 0));

end PICT_MEM;


-- architecture
architecture Behavioral of PICT_MEM is

    -- picture memory type
    type ram_t is array (0 to 2500) of std_logic_vector(7 downto 0);
    -- initiate picture memory to one cursor ("1F") followed by spaces ("00")
 signal pictMem : ram_t := (0 => x"01",1=>x"02", others => (others => '0'));


begin
    process(clk)
    begin
        if rising_edge(clk) then
            if rst='1' then
		        data_out2 <= pictMem(0);
            elsif (we1 ='1') then
                pictMem(save_at) <= data_in1;
	        else
	            data_out2 <= pictMem(to_integer(addr2));
	        end if;
        end if;
    end process;

end Behavioral;
