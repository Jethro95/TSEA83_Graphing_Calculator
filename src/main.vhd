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
        PS2KeyboardClk    : in std_logic;                   -- PS2 clock
        PS2KeyboardData   : in std_logic                    -- PS2 data
    );
end main;


architecture Behavioral of main is
    component cpu
        port(
            clk             : in std_logic;
            rst             : in std_logic;
            wep             : out std_logic;                         -- write enable
            data_out_picmem : out std_logic_vector(7 downto 0);      -- data in
            save_at_p         : out integer range 0 to 1200;           -- save data_in_p on adress
            save_at_b   : out integer range 0 to 153600;
	        kb_data         : in std_logic_vector(7 downto 0);
        	read_confirm    : out std_logic;
            web             : out std_logic;
            data_out_bitmap : out std_logic
        );
    end component;


    -- picture memory component
    component PICT_MEM
    port (  rst       : in std_logic;
            clk		  : in std_logic;
            wep       : in std_logic;
            web       : in std_logic;
            data_in_b  : in std_logic;
            data_in_p  : in std_logic_vector(7 downto 0);
            save_at_p   : in integer range 0 to 1200;
            save_at_b   : in integer range 0 to 153600;
            picmem_out : out std_logic_vector(7 downto 0);
            bitmem_out : out std_logic;
            Xpixel   : in unsigned(9 downto 0);         -- Horizontal pixel counter
            Ypixel   : in unsigned(9 downto 0));      
    end component;

    -- VGA motor component
    component VGA_MOTOR
    port ( clk	  : in std_logic;
    	 rst      : in std_logic;
    	 vgaRed   : out std_logic_vector(2 downto 0);
    	 vgaGreen : out std_logic_vector(2 downto 0);
    	 vgaBlue  : out std_logic_vector(2 downto 1);
    	 Hsync    : out std_logic;
    	 Vsync    : out std_logic;
         picmem_in      : in std_logic_vector(7 downto 0);      -- data
         bitmem_in      : in std_logic;      -- data
         Xpixel   : buffer unsigned(9 downto 0);         -- Horizontal pixel counter
         Ypixel   : buffer unsigned(9 downto 0)
         );
      end component;

    -- PS2 keyboard encoder component
    component KBD_ENC
        port(
            clk         : in std_logic;                         -- system clock
            rst         : in std_logic;                         -- reset signal
            PS2KeyboardCLK    : in std_logic;                   -- PS2 clock
            PS2KeyboardData   : in std_logic;                   -- PS2 data
            data        : out std_logic_vector(7 downto 0);     -- tile data
	        read_confirm : in std_logic
        );
    end component;

    -- intermediate signals between PICT_MEM and CPU
    signal data_s_p    : std_logic_vector(7 downto 0);        -- data
    signal wep_s      : std_logic;                           -- write enable pictmem
    signal web_s      : std_logic;                           -- write enable bitmapmem
    signal data_s_b    : std_logic;        -- data
    signal save_at_p_s : integer range 0 to 1200;             -- write enable
    signal save_at_b_s : integer range 0 to 153600;             -- write enable

    -- intermediate signals between PICT_MEM and VGA_MOTOR
    signal	picmem_out_s : std_logic_vector(7 downto 0);         -- data
    signal	bitmem_out_s : std_logic;         -- data
    signal	Xpixel_s     : unsigned(9 downto 0);
    signal	Ypixel_s     : unsigned(9 downto 0);

    -- intermediate signals between KBD_ENC and CPU
    signal data_cpu_kb  : std_logic_vector(7 downto 0);     -- data
	signal rc	: std_logic;                                -- read confirm


    begin

    CPU_UNIT        : cpu port map (clk, rst, wep=>wep_s, data_out_picmem=>data_s_p, save_at_p=>save_at_p_s, kb_data=>data_cpu_kb, read_confirm=>rc,web=>web_s,data_out_bitmap=>data_s_b, save_at_b=>save_at_b_s);

    -- picture memory component connection
    PIC_MEM_UNIT       : PICT_MEM port map(rst=>rst, wep=>wep_s, data_in_p=>data_s_p, save_at_p=>save_at_p_s, clk=>clk, bitmem_out=>bitmem_out_s, picmem_out=>picmem_out_s, Xpixel=>Xpixel_s, Ypixel=>Ypixel_s, web=>web_s, data_in_b=>data_s_b, save_at_b=>save_at_b_s);

    -- VGA driver component connection
    VGA_UNIT           : VGA_MOTOR port map(clk=>clk, rst=>rst, vgaRed=>vgaRed, vgaGreen=>vgaGreen, vgaBlue=>vgaBlue, Hsync=>Hsync, Vsync=>Vsync, Xpixel=>Xpixel_s, Ypixel=>Ypixel_s, bitmem_in=>bitmem_out_s, picmem_in =>picmem_out_s);

    -- keyboard encoder component connection
    KBD_ENC_UNIT    : KBD_ENC port map(clk=>clk, rst=>rst, PS2KeyboardCLK=>PS2KeyboardClk, PS2KeyboardData=>PS2KeyboardData, data=>data_cpu_kb, read_confirm=>rc);

end Behavioral;
