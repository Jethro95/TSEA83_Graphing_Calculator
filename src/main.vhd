library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

entity main is
    port(
        clk: in std_logic;
        rst: in std_logic;
        -- VGA
        Hsync	                : out std_logic;                        -- horizontal sync
        Vsync	                : out std_logic;                        -- vertical sync
        vgaRed	                : out	std_logic_vector(2 downto 0);   -- VGA red
        vgaGreen               : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue	        : out std_logic_vector(2 downto 1)     -- VGA blue
    );
end main;


architecture Behavioral of main is
    component cpu
        port(
            clk: in std_logic;
            rst: in std_logic
        );
    end component;


    -- picture memory component
    component PICT_MEM
      port ( clk			: in std_logic;                         -- system clock
 --  	 -- port 1 (No input yet)
    --          we1		        : in std_logic;                         -- write enable
    --          data_in1	        : in std_logic_vector(7 downto 0);      -- data in
    --          data_out1	        : out std_logic_vector(7 downto 0);     -- data out
    --          addr1	        : in unsigned(10 downto 0);             -- address
  	 -- port 2
             we2			: in std_logic;                         -- write enable
             data_in2	        : in std_logic_vector(7 downto 0);      -- data in
             data_out2	        : out std_logic_vector(7 downto 0);     -- data out
             addr2		: in unsigned(10 downto 0));            -- address
    end component;

    -- VGA motor component
    component VGA_MOTOR
      port ( clk			: in std_logic;                         -- system clock
             rst			: in std_logic;                         -- reset
             data			: in std_logic_vector(7 downto 0);      -- data
             addr			: out unsigned(10 downto 0);            -- address
             vgaRed		: out std_logic_vector(2 downto 0);     -- VGA red
             vgaGreen	        : out std_logic_vector(2 downto 0);     -- VGA green
             vgaBlue		: out std_logic_vector(2 downto 1);     -- VGA blue
             Hsync		: out std_logic;                        -- horizontal sync
             Vsync		: out std_logic);                       -- vertical sync
    end component;

    -- intermediate signals between PICT_MEM and VGA_MOTOR
    signal	data_out2_s     : std_logic_vector(7 downto 0);         -- data
    signal	addr2_s		: unsigned(10 downto 0);                -- address


begin

    CPU_UNIT     : cpu port map (clk, rst);

    -- picture memory component connection
    PIC_MEM_UNIT : PICT_MEM port map(clk=>clk, we2=>'0', data_in2=>"00000000", data_out2=>data_out2_s, addr2=>addr2_s);

    -- VGA motor component connection
    VGA_UNIT     : VGA_MOTOR port map(clk=>clk, rst=>rst, data=>data_out2_s, addr=>addr2_s, vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync);

end Behavioral;
