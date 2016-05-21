-- Based on http://www.isy.liu.se/edu/kurs/TSEA83/laboration/lab_vga.html

-- library declaration
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;            -- basic IEEE library
use IEEE.NUMERIC_STD.ALL;               -- IEEE library for the unsigned type

-- entity
entity PICT_MEM is
    port (  rst       : in std_logic;                       -- reset signal
            clk		  : in std_logic;                       -- clock signal
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
end PICT_MEM;


-- architecture
architecture Behavioral of PICT_MEM is

    type bitmap_t is array (0 to 153600) of std_logic;
    signal bitmapMem : bitmap_t := (others => '1');

    -- picture memory type
    type ram_t is array (0 to 1200) of std_logic_vector(7 downto 0);
    -- initiate picture memory to one cursor ("1F") followed by spaces ("00")
    signal pictMem : ram_t := (others => (x"2F"));
    signal bitmapAddr : integer range 0 to 153600;



begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Write input to its memory. 
            -- Note that we is newer reset. We will continue writing this data until reboot or a new save_at/data_in comes in.
            if (wep ='1') then
                pictMem(save_at_p) <= data_in_p;
            end if;
            if (web ='1') then
                bitmapMem(save_at_b) <= data_in_b;
            end if;

            if Xpixel>320 and Xpixel<640 and Ypixel<480 then -- We are in the tilememory half of the display. Load the tile for our current pixel
                picmem_out <= pictMem(to_integer(to_unsigned(40, 8) * Ypixel(8 downto 4) + Xpixel(9 downto 3)-40));
            elsif Xpixel<320 and Ypixel<480 then -- This is the bitmap half. Load the pixel value for the current pixel
                bitmem_out <= bitmapMem(to_integer(Ypixel*to_unsigned(320,10)+Xpixel));
            end if;

        end if;
    end process;

end Behavioral;
