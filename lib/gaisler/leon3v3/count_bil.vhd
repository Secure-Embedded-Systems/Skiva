library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity count_bil is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           en : in  STD_LOGIC;
           cnt : out  STD_LOGIC
			  );
end count_bil;

architecture Behavioral of count_bil is
    signal temp : STD_LOGIC;

begin
    --process (clk, en, temp, rst) is
    process (clk) is
    begin
        if rising_edge(clk) then  
            if (rst='0') then   
                temp <= '0';
            elsif (en='1') then
                temp <= not temp;
            end if;
        end if;
    end process;
    cnt <= temp;
end architecture Behavioral;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY count_trig IS
    PORT
    (
        clk       : IN  STD_LOGIC;
        rstn       : IN  STD_LOGIC;
        clear     : IN  STD_LOGIC;
        enable    : IN  STD_LOGIC;
        qa        : OUT STD_LOGIC_VECTOR(7 downto 0)
);

      END count_trig;
ARCHITECTURE a OF count_trig IS
SIGNAL   cnt         : STD_LOGIC_VECTOR(7 downto 0);
BEGIN
       -- An enable counter
    
    PROCESS (clk)
    BEGIN
        IF (clk'EVENT AND clk = '1') THEN
            IF rstn = '0' THEN
                cnt <= (others => '0');
            ELSIF clear = '1' THEN
                cnt <= (others => '0');
            ELSIF enable = '1' THEN
                cnt <= cnt + 1;
            END IF;
        END IF;
        qa <= cnt;
    END PROCESS;
END a;
