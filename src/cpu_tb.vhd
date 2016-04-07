LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY cpu_tb IS
END cpu_tb;

ARCHITECTURE behavior OF cpu_tb IS
	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT cpu
	PORT(
		clk : IN std_logic;
		rst : IN std_logic
	);
	END COMPONENT;

	--Inputs
	signal clk : std_logic := '0';
	signal rst : std_logic := '0';
	-- Clock period definitions
	constant clk_period : time := 1 us;

	BEGIN
	    -- Instantiate the Unit Under Test (UUT)
	    uut: cpu PORT MAP (
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

