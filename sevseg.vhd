----------------------------------------------------------------------------------
-- Company:        JWC
-- Engineer:       JWC
-- 
-- Create Date:    16:37:10 09/16/2010 
-- Design Name:    Seven Segment LED Controller
-- Module Name:    sevseg - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sevseg is
	Port (
		clk	 	: in  std_logic;						-- standard clock input
		rst	 	: in  std_logic;						-- reset (active high)
		val	 	: in  std_logic_vector (15 downto 0);	-- 16-bit value to control all 4 displays
		seg0	: in  std_logic_vector (3 downto 0);	-- 4-bit value to control display 3
		seg1	: in  std_logic_vector (3 downto 0);	-- " 2
		seg2	: in  std_logic_vector (3 downto 0);	-- " 1
		seg3	: in  std_logic_vector (3 downto 0);	-- " 0
		dp		: in  std_logic_vector (3 downto 0);	-- mask for decimal points 3, 2, 1, and 0
		wen		: in  std_logic;						-- write enable for val
		wendp	: in  std_logic_vector (3 downto 0);	-- write enable mask for decimal points (e.g. adjust dp3 and dp1 and set wendp to "1010")
		wenseg  : in  std_logic_vector (3 downto 0);	-- write enable mask for individual segments (e.g. update seg3 and seg2 and set wenseg to "1100")
		useseg	: in  std_logic;						-- select between using val and seg{3,2,1,0}
		anout	: out std_logic_vector (3 downto 0);	-- anode output {3,2,1,0}
		ctout	: out std_logic_vector (7 downto 0));	-- cathode output {dp,cg,cf,ce,cd,cc,cb,ca}
end sevseg;

architecture Behavioral of sevseg is

	-- state machine states
	signal curan	: std_logic_vector (1 downto 0) := "11";
	signal nxtan	: std_logic_vector (1 downto 0) := "11";

	-- led registers
	signal leddp	: std_logic_vector (3 downto 0) := "0000";
	signal led0		: std_logic_vector (3 downto 0) := "0000";
	signal led1		: std_logic_vector (3 downto 0) := "0000";
	signal led2		: std_logic_vector (3 downto 0) := "0000";
	signal led3		: std_logic_vector (3 downto 0) := "0000";

	-- clock divider
	signal clk2		: std_logic;
	constant CLKDIVAMT : integer := 10000;
	signal count	: integer range 0 to CLKDIVAMT;


begin

	-- generate second clock for LED output
	process(clk)
	begin
		if (rising_edge(clk)) then
			if rst = '1' then
				count <= 0;
				clk2 <= '0';
			else
				if count = CLKDIVAMT then
					clk2 <= NOT(clk2);
					count <= 0;
				else
					count<=count+1;
				end if;
			end if;
		end if;
	end process;

	-- handle input
	process (clk, rst)
	begin
		if (rising_edge(clk)) then
			if rst = '1' then
				led0 <= "0000";
				led1 <= "0000";
				led2 <= "0000";
				led3 <= "0000";
			else
				case useseg is
					when '1' => 
						if wenseg(3) = '1' then
							led3 <= seg3;
						end if;
						if wenseg(2) = '1' then
							led2 <= seg2;
						end if;
						if wenseg(1) = '1' then
							led1 <= seg1;
						end if;
						if wenseg(0) = '1' then
							led0 <= seg0;
						end if;
					when '0' => 
						if wen = '1' then
							led3 <= val(15 downto 12);
							led2 <= val(11 downto 8);
							led1 <= val(7 downto 4);
							led0 <= val(3 downto 0);
						end if;
					when others => 
						led3 <= "0000";
						led2 <= "0000";
						led1 <= "0000";
						led0 <= "0000";
				end case;

				if wendp(3) = '1' then
					leddp(3) <= dp(3);
				end if;
				if wendp(2) = '1' then
					leddp(2) <= dp(2);
				end if;
				if wendp(1) = '1' then
					leddp(1) <= dp(1);
				end if;
				if wendp(0) = '1' then
					leddp(0) <= dp(0);
				end if;
			end if;
		end if;
	end process;

	-- handle output
	process (clk2, rst)
	begin
		if (rising_edge(clk2)) then
			if rst = '1' then
				curan <= "11";
			else
				curan <= nxtan;
			end if;
		end if;
	end process;

	-- handle output (state machine)
	process (curan)
	begin
		case curan is
			when "11" => 
				nxtan <= "10";
				anout <= "0111";

				if led3 = "0001" or led3 = "0100" or led3 = "1011" or led3 = "1100" or led3 = "1101" then
					ctout(0) <= '1';
				else
					ctout(0) <= '0';
				end if;
				if led3 = "0101" or led3 = "0110" or led3 = "1011" or led3 = "1100" or led3 = "1110" or led3 = "1111" then
					ctout(1) <= '1';
				else
					ctout(1) <= '0';
				end if;
				if led3 = "0010" or led3 = "1100" or led3 = "1110" or led3 = "1111" then
					ctout(2) <= '1';
				else
					ctout(2) <= '0';
				end if;
				if led3 = "0001" or led3 = "0100" or led3 = "0111" or led3 = "1001" or led3 = "1010" or led3 = "1111" then
					ctout(3) <= '1';
				else
					ctout(3) <= '0';
				end if;
				if led3 = "0001" or led3 = "0011" or led3 = "0100" or led3 = "0101" or led3 = "0111" or led3 = "1001" then
					ctout(4) <= '1';
				else
					ctout(4) <= '0';
				end if;
				if led3 = "0001" or led3 = "0010" or led3 = "0011" or led3 = "0111" or led3 = "1100" or led3 = "1101" then
					ctout(5) <= '1';
				else
					ctout(5) <= '0';
				end if;
				if led3 = "0000" or led3 = "0001" or led3 = "0111" then
					ctout(6) <= '1';
				else
					ctout(6) <= '0';
				end if;
				if leddp(3) = '1' then
					ctout(7) <= '0';
				else
					ctout(7) <= '1';
				end if;

			when "10" => 
				nxtan <= "01";
				anout <= "1011";
				
				if led2 = "0001" or led2 = "0100" or led2 = "1011" or led2 = "1100" or led2 = "1101" then
					ctout(0) <= '1';
				else
					ctout(0) <= '0';
				end if;
				if led2 = "0101" or led2 = "0110" or led2 = "1011" or led2 = "1100" or led2 = "1110" or led2 = "1111" then
					ctout(1) <= '1';
				else
					ctout(1) <= '0';
				end if;
				if led2 = "0010" or led2 = "1100" or led2 = "1110" or led2 = "1111" then
					ctout(2) <= '1';
				else
					ctout(2) <= '0';
				end if;
				if led2 = "0001" or led2 = "0100" or led2 = "0111" or led2 = "1001" or led2 = "1010" or led2 = "1111" then
					ctout(3) <= '1';
				else
					ctout(3) <= '0';
				end if;
				if led2 = "0001" or led2 = "0011" or led2 = "0100" or led2 = "0101" or led2 = "0111" or led2 = "1001" then
					ctout(4) <= '1';
				else
					ctout(4) <= '0';
				end if;
				if led2 = "0001" or led2 = "0010" or led2 = "0011" or led2 = "0111" or led2 = "1100" or led2 = "1101" then
					ctout(5) <= '1';
				else
					ctout(5) <= '0';
				end if;
				if led2 = "0000" or led2 = "0001" or led2 = "0111" then
					ctout(6) <= '1';
				else
					ctout(6) <= '0';
				end if;
				if leddp(2) = '1' then
					ctout(7) <= '0';
				else
					ctout(7) <= '1';
				end if;

			when "01" => 
				nxtan <= "00";
				anout <= "1101";

				if led1 = "0001" or led1 = "0100" or led1 = "1011" or led1 = "1100" or led1 = "1101" then
					ctout(0) <= '1';
				else
					ctout(0) <= '0';
				end if;
				if led1 = "0101" or led1 = "0110" or led1 = "1011" or led1 = "1100" or led1 = "1110" or led1 = "1111" then
					ctout(1) <= '1';
				else
					ctout(1) <= '0';
				end if;
				if led1 = "0010" or led1 = "1100" or led1 = "1110" or led1 = "1111" then
					ctout(2) <= '1';
				else
					ctout(2) <= '0';
				end if;
				if led1 = "0001" or led1 = "0100" or led1 = "0111" or led1 = "1001" or led1 = "1010" or led1 = "1111" then
					ctout(3) <= '1';
				else
					ctout(3) <= '0';
				end if;
				if led1 = "0001" or led1 = "0011" or led1 = "0100" or led1 = "0101" or led1 = "0111" or led1 = "1001" then
					ctout(4) <= '1';
				else
					ctout(4) <= '0';
				end if;
				if led1 = "0001" or led1 = "0010" or led1 = "0011" or led1 = "0111" or led1 = "1100" or led1 = "1101" then
					ctout(5) <= '1';
				else
					ctout(5) <= '0';
				end if;
				if led1 = "0000" or led1 = "0001" or led1 = "0111" then
					ctout(6) <= '1';
				else
					ctout(6) <= '0';
				end if;
				if leddp(1) = '1' then
					ctout(7) <= '0';
				else
					ctout(7) <= '1';
				end if;

			when "00" => 
				nxtan <= "11";
				anout <= "1110";

				if led0 = "0001" or led0 = "0100" or led0 = "1011" or led0 = "1100" or led0 = "1101" then
					ctout(0) <= '1';
				else
					ctout(0) <= '0';
				end if;
				if led0 = "0101" or led0 = "0110" or led0 = "1011" or led0 = "1100" or led0 = "1110" or led0 = "1111" then
					ctout(1) <= '1';
				else
					ctout(1) <= '0';
				end if;
				if led0 = "0010" or led0 = "1100" or led0 = "1110" or led0 = "1111" then
					ctout(2) <= '1';
				else
					ctout(2) <= '0';
				end if;
				if led0 = "0001" or led0 = "0100" or led0 = "0111" or led0 = "1001" or led0 = "1010" or led0 = "1111" then
					ctout(3) <= '1';
				else
					ctout(3) <= '0';
				end if;
				if led0 = "0001" or led0 = "0011" or led0 = "0100" or led0 = "0101" or led0 = "0111" or led0 = "1001" then
					ctout(4) <= '1';
				else
					ctout(4) <= '0';
				end if;
				if led0 = "0001" or led0 = "0010" or led0 = "0011" or led0 = "0111" or led0 = "1100" or led0 = "1101" then
					ctout(5) <= '1';
				else
					ctout(5) <= '0';
				end if;
				if led0 = "0000" or led0 = "0001" or led0 = "0111" then
					ctout(6) <= '1';
				else
					ctout(6) <= '0';
				end if;
				if leddp(0) = '1' then
					ctout(7) <= '0';
				else
					ctout(7) <= '1';
				end if;

			when others => 
				anout <= "0000";
				ctout <= "00000000";
		end case;
	end process;

end Behavioral;
