-- Based on http://www.isy.liu.se/edu/kurs/TSEA83/laboration/lab_vga.html

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

entity main is
    port(
        clk         : in std_logic;                         -- clock signal
        rst         : in std_logic;                         -- reset signal
        -- VGA
        Hsync       : out std_logic;                        -- horizontal sync
        Vsync       : out std_logic;                        -- vertical sync
        vgaRed      : out  std_logic_vector(2 downto 0);    -- VGA red
        vgaGreen    : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue     : out std_logic_vector(2 downto 1);     -- VGA blue
        -- KB
        PS2KeyboardClk    : in std_logic;                   -- PS2 clock
        PS2KeyboardData   : in std_logic                    -- PS2 data
    );
end main;


architecture Behavioral of main is
    component cpu
    port(
        clk             : in std_logic;                          -- clock signal
        rst             : in std_logic;                          -- reset signal
        wep             : out std_logic;                         -- write enable for picMem
        data_out_picmem : out std_logic_vector(7 downto 0);      -- data out to picMem
        save_at_p       : out integer range 0 to 1200;           -- picMem adress to save data_out_picmem at
        save_at_b       : out integer range 0 to 153600;         -- bitmapMem adress to save data_out_bitmap at
        kb_data         : in std_logic_vector(7 downto 0);       -- Next 
        read_confirm    : out std_logic;                         -- tells keyboard encoder that we have read the last input and are ready for the next
        web             : out std_logic;                         -- write enable for bitmapMem
        data_out_bitmap : out std_logic                          -- data out to bitmapMem
    );
    end component;


    -- picture memory component
    component PICT_MEM
    port (  rst       : in std_logic;                       -- reset signal
            clk       : in std_logic;                       -- clock signal
            wep       : in std_logic;                       -- write enable for picMem
            web       : in std_logic;                       -- write enable for bitmapMem
            data_in_b  : in std_logic;                      -- data in to bitmapMem
            data_in_p  : in std_logic_vector(7 downto 0);   -- data in to picMem
            save_at_p   : in integer range 0 to 1200;       -- picMem adress to save data_in_p at
            save_at_b   : in integer range 0 to 153600;     -- bitmapMem adress to save data_in_b at
            picmem_out : out std_logic_vector(7 downto 0);  -- Tile number for (Xpixel,Ypixel) when on the rights side of the display
            bitmem_out : out std_logic;                     -- Pixel value for (Xpixel,Ypixel) when on the left side of the display
            Xpixel   : in unsigned(9 downto 0);             -- Horizontal pixel counter
            Ypixel   : in unsigned(9 downto 0));            -- Vertical pixel counter
    end component;

    -- VGA motor component
    component VGA_MOTOR
    port ( clk    : in std_logic;                           -- clock signal
         rst      : in std_logic;                           -- reset signal
         vgaRed   : out std_logic_vector(2 downto 0);       -- VGA Red
         vgaGreen : out std_logic_vector(2 downto 0);       -- VGA Green
         vgaBlue  : out std_logic_vector(2 downto 1);       -- VGA Blue
         Hsync    : out std_logic;                          -- Horizontal sync signal for VGA output
         Vsync    : out std_logic;                          -- Vertical sync signal for VGA output
         picmem_in: in std_logic_vector(7 downto 0);        -- Tile number for (Xpixel,Ypixel) when on the rights side of the display
         bitmem_in: in std_logic;                           -- Pixel value for (Xpixel,Ypixel) when on the left side of the display
         Xpixel   : buffer unsigned(9 downto 0);            -- Horizontal pixel counter
         Ypixel   : buffer unsigned(9 downto 0)             -- Vertical pixel counter
         );
      end component;

    -- PS2 keyboard encoder component
    component KBD_ENC
        port(
            clk             : in std_logic;                     -- system clock
            rst             : in std_logic;                     -- reset signal
            PS2KeyboardCLK  : in std_logic;                     -- PS2 clock
            PS2KeyboardData : in std_logic;                     -- PS2 data
            data            : out std_logic_vector(7 downto 0); -- tile data
	        read_confirm    : in std_logic                      -- tells keyboard encoder that we have read the last input and are ready for the next
        );
    end component;

    -- intermediate signals between PICT_MEM and CPU
    signal data_s_p    : std_logic_vector(7 downto 0);        -- data pictmem (sync)
    signal wep_s      : std_logic;                            -- write enable pictmem (sync)
    signal web_s      : std_logic;                            -- write enable bitmapmem (sync)
    signal data_s_b    : std_logic;                           -- data bitmapmem (sync)
    signal save_at_p_s : integer range 0 to 1200;             -- picMem adress to save data_in_p at (sync)
    signal save_at_b_s : integer range 0 to 153600;           -- bitmapMem adress to save data_in_b at (sync)

    -- intermediate signals between PICT_MEM and VGA_MOTOR
    signal	picmem_out_s : std_logic_vector(7 downto 0);      -- Tile number for (Xpixel,Ypixel) when on the rights side of the display (sync)
    signal	bitmem_out_s : std_logic;                         -- Pixel value for (Xpixel,Ypixel) when on the left side of the display (sync)
    signal	Xpixel_s     : unsigned(9 downto 0);              -- Horizontal pixel counter (sync)
    signal	Ypixel_s     : unsigned(9 downto 0);              -- Vertical pixel counter (sync)

    -- intermediate signals between KBD_ENC and CPU
    signal data_cpu_kb  : std_logic_vector(7 downto 0);     -- data (sync)
	signal rc	: std_logic;                                -- read confirm (sync)


    begin

    -- cpu component connection
    CPU_UNIT        : cpu port map (clk, rst, wep=>wep_s, data_out_picmem=>data_s_p, save_at_p=>save_at_p_s, kb_data=>data_cpu_kb, read_confirm=>rc,web=>web_s,data_out_bitmap=>data_s_b, save_at_b=>save_at_b_s);

    -- picture memory component connection
    PIC_MEM_UNIT    : PICT_MEM port map(rst=>rst, wep=>wep_s, data_in_p=>data_s_p, save_at_p=>save_at_p_s, clk=>clk, bitmem_out=>bitmem_out_s, picmem_out=>picmem_out_s, Xpixel=>Xpixel_s, Ypixel=>Ypixel_s, web=>web_s, data_in_b=>data_s_b, save_at_b=>save_at_b_s);

    -- VGA driver component connection
    VGA_UNIT        : VGA_MOTOR port map(clk=>clk, rst=>rst, vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync, Xpixel=>Xpixel_s, Ypixel=>Ypixel_s, bitmem_in=>bitmem_out_s, picmem_in =>picmem_out_s);

    -- keyboard encoder component connection
    KBD_ENC_UNIT    : KBD_ENC port map(clk=>clk, rst=>rst, PS2KeyboardCLK=>PS2KeyboardClk, PS2KeyboardData=>PS2KeyboardData, data=>data_cpu_kb, read_confirm=>rc);

end Behavioral;
