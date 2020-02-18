----------------------------------------------------------------------------------
-- Company: SES, VT
-- Engineer: Chinmay
-- 
-- Create Date:    12:09:41 10/29/2015 
-- Design Name: 
-- Module Name:    canary - Structural 
-- Project Name: Canary_sakura
-- Target Devices: Sakura
-- Tool versions: 
-- Description: 
--
-- Dependencies: ff.vhd
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity canary is
	generic (
		N : integer := 20
	);
    Port ( 
    	clk : in  STD_LOGIC;
    	rstn : in  STD_LOGIC;
        alarm : out STD_LOGIC
     );
end canary;

architecture Structural of canary is
	
	component ff port (
		clk : in std_logic;
		rstn : in std_logic;
		d : in std_logic;
		q : out std_logic
	);
	end component;
	
	signal d_toggle : std_logic;
	signal q_toggle : std_logic := '0';
	signal d_main : std_logic;
	signal q_main : std_logic;
	signal d_shadow : std_logic;
	signal q_shadow : std_logic;
	type inv_array_type is array(N downto 0) of std_logic;
	signal N_net : inv_array_type;
	
	attribute keep : string;
	attribute keep of d_toggle : signal is "true";
	attribute keep of q_toggle : signal is "true";
	attribute keep of d_main : signal is "true";
	attribute keep of d_shadow : signal is "true";
	attribute keep of q_main : signal is "true";
	attribute keep of q_shadow : signal is "true";
	attribute keep of N_net : signal is "true";
	
begin

	toggle_ff : ff port map (
		clk => clk,
		rstn => rstn,
		d => d_toggle,
		q => q_toggle
	);

	main_ff : ff port map (
		clk => clk,
		rstn => rstn,
		d => d_main,
		q => q_main
	);
	
	shadow_ff : ff port map (
		clk => clk,
		rstn => rstn,
		d => d_shadow,
		q => q_shadow
	);		
	
	d_toggle <= not (q_toggle);
	d_main <= q_toggle;
	N_net(0) <= not (q_toggle);
	inv : for i in 1 to N generate
		N_net(i) <= not N_net(i-1);
	end generate inv;
	d_shadow <= not(N_net(N));
	
	alarm <= q_shadow xor q_main;
end Structural;

