------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
--  Copyright (C) 2015 - 2016, Cobham Gaisler
--
--  This program is free software; you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation; either version 2 of the License, or
--  (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
--  You should have received a copy of the GNU General Public License
--  along with this program; if not, write to the Free Software
--  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA 
-----------------------------------------------------------------------------
-- Entity:      dare memories 
-- File:        memory_dare.vhd
-- Author:      Chinmay Deshpande 
-- Description: Memory generators for dare
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library dare;
use dare.sram12x8;
use dare.sram13x8;
use dare.sram6x32;
use dare.sram6x26;
use dare.sram8x32;
use dare.sram7x25;
use dare.sram8x25;
use dare.sram9x32;
-- pragma translate_on

entity dare_syncram is
  generic ( abits : integer := 10; dbits : integer := 8);
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector(abits -1 downto 0);
    datain   : in std_logic_vector(dbits -1 downto 0);
    dataout  : out std_logic_vector(dbits -1 downto 0);
    enable   : in std_ulogic;
    write    : in std_ulogic
  );
end;

architecture rtl of dare_syncram is
  component sram12x8 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(11 downto 0);
	D: in std_logic_vector(7 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(7 downto 0)
    );
end component;

component sram13x8 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(12 downto 0);
	D: in std_logic_vector(7 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(7 downto 0)
    );
end component;

component sram6x26 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(5 downto 0);
	D: in std_logic_vector(25 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(25 downto 0)
    );
end component;

component sram6x32 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(5 downto 0);
	D: in std_logic_vector(31 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(31 downto 0)
    );
end component;

component sram8x32 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(7 downto 0);
	D: in std_logic_vector(31 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(31 downto 0)
    );
end component;

component sram8x25 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(7 downto 0);
	D: in std_logic_vector(24 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(24 downto 0)
    );
end component;

component sram7x25 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(6 downto 0);
	D: in std_logic_vector(24 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(24 downto 0)
    );
end component;

component sram9x32 is
    port ( 
	CLK: in std_logic;
	CEN: in std_logic;
	WEN: in std_logic;
	A: in std_logic_vector(8 downto 0);
	D: in std_logic_vector(31 downto 0);
	OEN: in std_logic;
	Q: out std_logic_vector(31 downto 0)
    );
end component;

  signal d, q, gnd : std_logic_vector(48 downto 0);
  signal a : std_logic_vector(17 downto 0);
  signal vcc, csn, wen : std_ulogic;
  --constant synopsys_bug : std_logic_vector(31 downto 0) := (others => '0');
  -- bilgiday for 128K and 64K ahbram ----------------------------
  signal a0, a1, a2, a3 : std_logic_vector(17 downto 0);
  signal d0, d1, d2, d3: std_logic_vector(48 downto 0);
  signal q0, q1, q2, q3 : std_logic_vector(48 downto 0);
  signal csn0, csn1, csn2, csn3 : std_ulogic;
  signal tmp0, tmp1, tmp2, tmp3 : std_ulogic;
  signal tmp0r, tmp1r, tmp2r, tmp3r : std_ulogic;
  signal wen0, wen1, wen2, wen3 : std_ulogic;
-----------------------------------------------------------
  
begin

  csn <= not enable; wen <= not write;
  gnd <= (others => '0'); vcc <= '1';

  a(17 downto abits) <= (others => '0');
  d(48 downto dbits) <= (others => '0');
  
  a(abits -1 downto 0) <= address;
  d(dbits -1 downto 0) <= datain(dbits -1 downto 0);
  
  -- bilgiday for 64KB and 128KB ahbram (using 13x8 mems as building blocks)
  tmp0 <= ((not a(14)) and (not a(13))) when ((abits = 15) or (abits = 14)) else gnd(0);
  tmp1 <= ((not a(14)) and (a(13))) when ((abits = 15) or (abits = 14)) else gnd(0);
  tmp2 <= ((a(14)) and (not a(13))) when ((abits = 15) or (abits = 14)) else gnd(0);
  tmp3 <= ((a(14)) and (a(13))) when ((abits = 15) or (abits = 14)) else gnd(0);
  
  csn0 <= csn when tmp0 = '1' else '1';
  csn1 <= csn when tmp1 = '1' else '1';
  csn2 <= csn when tmp2 = '1' else '1';
  csn3 <= csn when tmp3 = '1' else '1';
  
  wen0 <= wen when tmp0 = '1' else '1';
  wen1 <= wen when tmp1 = '1' else '1';
  wen2 <= wen when tmp2 = '1' else '1';
  wen3 <= wen when tmp3 = '1' else '1';
  ----------------------------------------------------------------------------------
  

  ahbram_16 : if (abits = 12) generate
      id0 : sram12x8 port map (CLK => clk, CEN => csn, WEN => wen, A => a(11 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q(7 downto 0));
  end generate;

  ahbram_32 : if (abits = 13) generate
      id0 : sram13x8 port map (CLK => clk, CEN => csn, WEN => wen, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q(7 downto 0));
  end generate;
  
   -- bilgiday for 64KB and 128KB ahbram (using 13x8 mems as building blocks) -----------------
  ahbram_64 : if (abits = 14) generate
      id0 : sram13x8 port map (CLK => clk, CEN => csn0, WEN => wen0, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q0(7 downto 0));
	  id1 : sram13x8 port map (CLK => clk, CEN => csn1, WEN => wen1, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q1(7 downto 0));
  end generate;
  
  ahbram_128 : if (abits = 15) generate
      id0 : sram13x8 port map (CLK => clk, CEN => csn0, WEN => wen0, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q0(7 downto 0));
	  id1 : sram13x8 port map (CLK => clk, CEN => csn1, WEN => wen1, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q1(7 downto 0));
	  id2 : sram13x8 port map (CLK => clk, CEN => csn2, WEN => wen2, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q2(7 downto 0));
	  id3 : sram13x8 port map (CLK => clk, CEN => csn3, WEN => wen3, A => a(12 downto 0), D => d(7 downto 0), OEN => gnd(0),  Q => q3(7 downto 0));
  end generate;
----------------------------------------------------------------------------------

  itags : if ( (abits = 6) and (dbits = 26) ) generate
      id0 : sram6x26 port map (CLK => clk, CEN => csn, WEN => wen, A => a(5 downto 0), D => d(25 downto 0), OEN => gnd(0),  Q => q(25 downto 0));
  end generate;
 
  idata : if ( (abits = 8) and (dbits = 32) ) generate
      id0 : sram8x32 port map (CLK => clk, CEN => csn, WEN => wen, A => a(7 downto 0), D => d(31 downto 0), OEN => gnd(0),  Q => q(31 downto 0));
  end generate;
 
  dtags : if ( (abits = 8) and (dbits = 25) ) generate
      id0 : sram8x25 port map (CLK => clk, CEN => csn, WEN => wen, A => a(7 downto 0), D => d(24 downto 0), OEN => gnd(0),  Q => q(24 downto 0));
  end generate;
  
  dtags2 : if ( (abits = 7) and (dbits = 25) ) generate
      id0 : sram7x25 port map (CLK => clk, CEN => csn, WEN => wen, A => (a(6 downto 0)), D => d(24 downto 0), OEN => gnd(0),  Q => q(24 downto 0));
  end generate;
 
  ddata : if ( (abits = 9) and (dbits = 32) ) generate
      id0 : sram9x32 port map (CLK => clk, CEN => csn, WEN => wen, A => a(8 downto 0), D => d(31 downto 0), OEN => gnd(0),  Q => q(31 downto 0));
  end generate;
 
  tbmem : if ( (abits = 6) and (dbits = 32) ) generate
      id0 : sram6x32 port map (CLK => clk, CEN => csn, WEN => wen, A => a(5 downto 0), D => d(31 downto 0), OEN => gnd(0),  Q => q(31 downto 0));
  end generate;

    -- bilgiday for 64KB and 128KB ahbram (using 13x8 mems as building blocks)
  dataout <= q3(dbits -1 downto 0) when tmp3r = '1' else
	   q2(dbits -1 downto 0) when tmp2r = '1' else
	   q1(dbits -1 downto 0) when tmp1r = '1' else
	   q0(dbits -1 downto 0) when tmp0r = '1' else
	   q(dbits -1 downto 0);

   process (clk) is
   begin
      if rising_edge(clk) then  
         tmp0r <= tmp0;
         tmp1r <= tmp1;
         tmp2r <= tmp2;
         tmp3r <= tmp3;
      end if;
   end process;
---- pragma translate_off
  --a_to_high : if (abits > 10) or (dbits > 32) generate
    --x : process
    --begin
      --assert false
      --report  "Unsupported memory size (dare)"
      --severity failure;
      --wait;
    --end process;
  --end generate;
---- pragma translate_on


end;


library ieee;
use ieee.std_logic_1164.all;
-- pragma translate_off
library dare;
use dare.sram2p8x32;
-- pragma translate_on

entity dare_syncram_2p is
  generic ( abits : integer := 8; dbits : integer := 32; sepclk : integer := 0);
  port (
    rclk  : in std_ulogic;
    rena  : in std_ulogic;
    raddr : in std_logic_vector (abits -1 downto 0);
    dout  : out std_logic_vector (dbits -1 downto 0);
    wclk  : in std_ulogic;
    waddr : in std_logic_vector (abits -1 downto 0);
    din   : in std_logic_vector (dbits -1 downto 0);
    write : in std_ulogic);
end;


architecture rtl of dare_syncram_2p is

 -- component sram2p8x32
-- port ( 
	-- CLKA: in std_logic;
	-- CENA: in std_logic;
	-- WENA: in std_logic;
	-- AA: in std_logic_vector(7 downto 0);
	-- DA: in std_logic_vector(31 downto 0);
	-- OENA: in std_logic;
	-- QA: out std_logic_vector(31 downto 0);
	-- CLKB: in std_logic;
	-- CENB: in std_logic;
	-- WENB: in std_logic;
	-- AB: in std_logic_vector(7 downto 0);
	-- DB: in std_logic_vector(31 downto 0);
	-- OENB: in std_logic;
	-- QB: out std_logic_vector(31 downto 0)
    -- );
 -- end component; 
 
 component sram2p8x32 
 port (
   QA: out std_logic_vector(31 downto 0);
   AA: in std_logic_vector(7 downto 0);
   CLKA: in std_logic;
   CENA: in std_logic;
   AB: in std_logic_vector(7 downto 0);
   DB: in std_logic_vector(31 downto 0);
   CLKB: in std_logic;
   CENB: in std_logic
);
end component;

  signal vcc, wen, csn, gnd : std_ulogic;
  signal d2, q1: std_logic_vector(31 downto 0);
  signal a1, a2: std_logic_vector(31 downto 0);
begin

  csn <= not rena; wen <= not write;
  vcc <= '1'; gnd <=  '0';
  d2(dbits-1 downto 0) <= din; d2(31 downto dbits) <= (others => '0');
  a2(abits-1 downto 0) <= waddr; a2(31 downto abits) <= (others => '0');
  a1(abits-1 downto 0) <= raddr; a1(31 downto abits) <= (others => '0');
  dout <= q1(dbits-1 downto 0);

    id0 :sram2p8x32 -- Port1: A (Read port),   Port2: B (Write port)
      port map (
    QA => q1(31 downto 0),
	AA => a1(7 downto 0),
	CLKA => rclk,  
    CENA => csn, 
    AB => a2(7 downto 0),
    DB => d2(31 downto 0),  
	CLKB => wclk, 
	CENB => wen
    );
    

end;

