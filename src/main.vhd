library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

entity main is
port(
    clk         : in std_logic;
    rst         : in std_logic;
    -- VGA
    Hsync       : out std_logic;                        -- horizontal sync
    Vsync       : out std_logic;                        -- vertical sync
    vgaRed      : out  std_logic_vector(2 downto 0);    -- VGA red
    vgaGreen    : out std_logic_vector(2 downto 0);     -- VGA green
    vgaBlue     : out std_logic_vector(2 downto 1);     -- VGA blue
    -- KB
    PS2KbCLK    : in std_logic;                         -- PS2 clock
    PS2KbData   : in std_logic                          -- PS2 data
    );
end main;


architecture Behavioral of main is
    component cpu
        port(
            clk         : in std_logic;
            rst         : in std_logic;
            we1         : out std_logic;                        -- write enable
            data_in1    : out std_logic_vector(7 downto 0);     -- data in
            save_at     : out integer range 0 to 1200         	-- save data_in1 on adress
        );
    end component;


    -- picture memory component
    component PICT_MEM
        port (
            clk         : in std_logic;                         -- system clock
            we1         : in std_logic;                         -- write enable
            data_in1    : in std_logic_vector(7 downto 0);      -- data
            save_at     : in integer range 0 to 1200;           -- save data_in1 on adress
            data_out2   : out std_logic_vector(7 downto 0);     -- data out
            addr2       : in unsigned(12 downto 0)            	-- address
        );
    end component;

    -- VGA motor component
    component VGA_MOTOR
        port (
            clk         : in std_logic;                         -- system clock
            rst         : in std_logic;                         -- reset
            data        : in std_logic_vector(7 downto 0);      -- data
            addr        : out unsigned(12 downto 0);            -- address
            vgaRed      : out std_logic_vector(2 downto 0);     -- VGA red
            vgaGreen    : out std_logic_vector(2 downto 0);     -- VGA green
            vgaBlue     : out std_logic_vector(2 downto 1);     -- VGA blue
            Hsync       : out std_logic;                        -- horizontal sync
            Vsync       : out std_logic                       	-- vertical sync
        );
      end component;

    -- PS2 keyboard encoder component
    component KBD_ENC
        port (
            clk         : in std_logic;                         -- system clock
            rst         : in std_logic;                         -- reset signal
            PS2KbCLK    : in std_logic;                         -- PS2 clock
            PS2KbData   : in std_logic;                         -- PS2 data
            data        : out std_logic_vector(7 downto 0);     -- tile data
            --addr        : out unsigned(10 downto 0);            -- tile address
            we          : out std_logic                      	-- write enable
        );
    end component;

    -- intermediate signals between PICT_MEM and CPU
    signal data_s       : std_logic_vector(7 downto 0);         -- data
    signal we_s         : std_logic;                            -- write enable
    signal save_at_s    : integer range 0 to 1200;              -- write enable

    -- intermediate signals between PICT_MEM and VGA_MOTOR
    signal data_out2_s  : std_logic_vector(7 downto 0);         -- data
    signal addr2_s      : unsigned(12 downto 0);                -- address

    -- intermediate signals between KBD_ENC and CPU
    signal data_cpu_kb  : std_logic_vector(7 downto 0);         -- data
    --signal we_s         : std_logic;                            -- write enable


    begin

    CPU_UNIT        : cpu port map (clk, rst, we1=>we_s, data_in1=>data_s, save_at=>save_at_s);

    -- picture memory component connection
    PIC_MEM_UNIT    : PICT_MEM port map( we1=>we_s, data_in1=>data_s, save_at=>save_at_s, clk=>clk, data_out2=>data_out2_s, addr2=>addr2_s);

    -- VGA motor component connection
    VGA_UNIT        : VGA_MOTOR port map(clk=>clk, rst=>rst, data=>data_out2_s, addr=>addr2_s, vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync);

    -- keyboard encoder component connection
    KBD_ENC_UNIT    : KBD_ENC port map(clk=>clk, rst=>rst, PS2KbCLK=>PS2KbCLK, PS2KbData=>PS2KbData, data=>data_cpu_kb, we=>we_s);

end Behavioral;