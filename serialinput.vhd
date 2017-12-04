----------------------------------------------------------------------------------
-- Company:        JWC
-- Engineer:       JWC
-- 
-- Create Date:    22:49:29 09/16/2010 
-- Design Name:    seven segment led controller tester
-- Module Name:    sevseg_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    start serial communication with board (9600 baud, odd
--                 parity, 1 stop bit) and then enter two bytes (MSB, LSB)
--                 containing the 16 bit value you want to show on the display
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

entity sevseg_top is
    port ( clk	: in  std_logic;
           rst	: in  std_logic;
           an	: out  std_logic_vector (3 downto 0);
           seg	: out  std_logic_vector (6 downto 0);
           dp	: out  std_logic;
           tx	: out std_logic;
           rx	: in  std_logic);
end sevseg_top;

architecture Behavioral of sevseg_top is

	component Rs232RefComp
		Port ( 
			TXD 	: out std_logic  	:= '1';
			RXD 	: in  std_logic;					
			CLK 	: in  std_logic;
			DBIN 	: in  std_logic_vector (7 downto 0);
			DBOUT	: out std_logic_vector (7 downto 0);
			RDA		: inout std_logic;
			TBE		: inout std_logic 	:= '1';
			RD		: in  std_logic;
			WR		: in  std_logic;
			PE		: out std_logic;
			FE		: out std_logic;
			OE		: out std_logic;
			RST		: in  std_logic	:= '0');
	end component;

	component sevseg
		Port (
			clk	 	: in  std_logic;
			rst	 	: in  std_logic;
			val	 	: in  std_logic_vector (15 downto 0);
			seg0	: in  std_logic_vector (3 downto 0) := "0000";
			seg1	: in  std_logic_vector (3 downto 0) := "0000";
			seg2	: in  std_logic_vector (3 downto 0) := "0000";
			seg3	: in  std_logic_vector (3 downto 0) := "0000";
			dp		: in  std_logic_vector (3 downto 0) := "0000";
			wen		: in  std_logic := '0';
			wendp	: in  std_logic_vector (3 downto 0) := "0000";
			wenseg	: in  std_logic_vector (3 downto 0) := "0000";
			useseg	: in  std_logic := '0';
			anout	: out std_logic_vector (3 downto 0);
			ctout	: out std_logic_vector (7 downto 0));
	end component;

	signal sig_ser_dataout		: std_logic_vector(7 downto 0);	-- data from serial
	signal sig_ser_rda			: std_logic;
	signal sig_ser_rd			: std_logic;
	signal sig_ser_wr			: std_logic;
	signal sig_ser_datain		: std_logic_vector(7 downto 0);
	signal sig_ser_tbe			: std_logic := '1';
	signal sig_ser_pe			: std_logic;
	signal sig_ser_fe			: std_logic;
	signal sig_ser_oe			: std_logic;

	signal sig_data				: std_logic_vector (15 downto 0);
	signal sig_wen				: std_logic := '0';

	signal sig_top_an			: std_logic_vector (3 downto 0);
	signal sig_top_ct			: std_logic_vector (7 downto 0);

	type sm_read is (
		st_dataA,
		st_dataB,
		st_dataA_done,
		st_dataB_done
	);

	signal sm_read_cur			: sm_read := st_dataA;
	signal sm_read_nxt			: sm_read;

begin

	UART: RS232RefComp port map (	TXD 	=> tx,
									RXD 	=> rx,
									CLK 	=> clk,
									DBIN 	=> sig_ser_datain,
									DBOUT	=> sig_ser_dataout,
									RDA		=> sig_ser_rda,
									TBE		=> sig_ser_tbe,	
									RD		=> sig_ser_rd,
									WR		=> sig_ser_wr,
									PE		=> sig_ser_pe,
									FE		=> sig_ser_fe,
									OE		=> sig_ser_oe,
									RST 	=> rst);

	SS: sevseg port map (
		clk => clk,
		rst => rst,
		val => sig_data,
		seg0 => open,
		seg1 => open,
		seg2 => open,
		seg3 => open,
		dp => open,
		wen => sig_wen,
		wendp => open,
		wenseg => open,
		useseg => '0',
		anout => sig_top_an,
		ctout => sig_top_ct
	);

	dp <= sig_top_ct(7);
	seg <= sig_top_ct(6 downto 0);
	an <= sig_top_an;

	process (clk,rst)
	begin
		if (rising_edge(clk)) then
			if rst='1' then
				sm_read_cur <= st_dataA;
			else
				sm_read_cur <= sm_read_nxt;
			end if;
		end if;
	end process;

	process (sm_read_cur, sig_ser_rda, sig_ser_dataout)
	begin
		case sm_read_cur is
			when st_dataA =>
				sig_ser_rd <= '0';
				sig_ser_wr <= '0';
				sig_wen <= '0';
				
				if sig_ser_rda = '1' then
					sig_data(15 downto 8) <= sig_ser_dataout;
					sm_read_nxt <= st_dataA_done;
				else
					sm_read_nxt <= st_dataA;
				end if;

			when st_dataA_done =>
				sig_ser_rd <= '1';
				sm_read_nxt <= st_dataB;

			when st_dataB =>
				sig_ser_rd <= '0';
				sig_ser_wr <= '0';

				if sig_ser_rda = '1' then
					sig_data(7 downto 0) <= sig_ser_dataout;
					sig_wen <= '1';
					sm_read_nxt <= st_dataB_done;
				else
					sig_wen <= '0';
					sm_read_nxt <= st_dataB;
				end if;

			when st_dataB_done =>
				sig_ser_rd <= '1';
				sm_read_nxt <= st_dataA;
		end case;
	end process;

end Behavioral;

