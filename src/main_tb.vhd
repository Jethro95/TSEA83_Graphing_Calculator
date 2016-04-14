LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY main_tb IS
END main_tb;

ARCHITECTURE behavior OF main_tb IS
	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT main
	PORT(
		clk            : IN std_logic;
		rst            : IN std_logic;
        -- VGA
        Hsync    : out std_logic;                        -- horizontal sync
        Vsync    : out std_logic;                        -- vertical sync
        vgaRed   : out	std_logic_vector(2 downto 0);   -- VGA red
        vgaGreen : out std_logic_vector(2 downto 0);     -- VGA green
        vgaBlue  : out std_logic_vector(2 downto 1)     -- VGA blue
	);
	END COMPONENT;

	--Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	-- Clock period definitions
	constant clk_period : time := 1 us;

	BEGIN
	    -- Instantiate the Unit Under Test (UUT)
	    uut: main PORT MAP (
	        clk => clk,
	        rst => rst
	    );
	    -- Clock process definitions
	    clk_process :process
	    begin
	        clk <= '0';
	        wait for clk_period/2;
	        clk <= '1';
	        wait for clk_period/2;
	    end process;
	    rst <= '1', '0' after 1.5 us;
    END;
