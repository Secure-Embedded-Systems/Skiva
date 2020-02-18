----------------------------------------------------------------------------------
-- Company: SES, VT
-- Engineer: Chinmay
-- 
-- Create Date:    12:02:54 10/29/2015 
-- Design Name: 
-- Module Name:    ff - Behavioral 
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ff is
    Port ( clk : in  STD_LOGIC;
		   rstn : in  STD_LOGIC;
           d : in  STD_LOGIC;
           q : out  STD_LOGIC := '0');
end ff;

architecture Behavioral of ff is
	--signal count : std_logic;
begin
	process (clk)
	begin
		if rising_edge(clk) then
			if (rstn = '0') then
				q <= '0';
			else
				q <= d;
			end if;
		end if;
	end process;
end Behavioral;
