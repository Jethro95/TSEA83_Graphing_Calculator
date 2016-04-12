library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

entity main is
    port(
        clk: in std_logic;
        rst: in std_logic
    );
end main;


architecture Behavioral of main is
    component cpu
        port(
            clk: in std_logic;
            rst: in std_logic
        );
    end component;

begin

cpu_unit : cpu port map (clk, rst);

end Behavioral;

