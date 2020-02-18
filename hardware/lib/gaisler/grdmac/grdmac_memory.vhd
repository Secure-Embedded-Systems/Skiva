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
use dare.sram8x32;
-- pragma translate_on

entity grdmac_memory is
  generic ( abits : integer := 8; dbits : integer := 32);
  port (
    clk      : in std_ulogic;
    address  : in std_logic_vector(abits -1 downto 0);
    datain   : in std_logic_vector(dbits -1 downto 0);
    dataout  : out std_logic_vector(dbits -1 downto 0);
    enable   : in std_logic_vector (3 downto 0);
    write    : in std_logic_vector (3 downto 0)
  );
end;

architecture rtl of grdmac_memory is

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


  signal d, q, gnd : std_logic_vector(dbits downto 0);
  signal a : std_logic_vector(abits downto 0);
  signal vcc, csn, wen : std_ulogic;
  --constant synopsys_bug : std_logic_vector(31 downto 0) := (others => '0');
  -- bilgiday for 128K and 64K ahbram ----------------------------
-----------------------------------------------------------
  
begin

  csn <= not (enable(0) and enable(1) and enable(2) and enable(3)); 
wen <= not (write(0) or write(1) or write(2) or write(3));
  gnd <= (others => '0'); vcc <= '1';

  
  a(abits -1 downto 0) <= address;
  d(dbits -1 downto 0) <= datain(dbits -1 downto 0);
  
  dma_memory : if ( (abits = 8) and (dbits = 32) ) generate
      dma_mem0 : sram8x32 port map (CLK => clk, CEN => csn, WEN => wen, A => a(7 downto 0), D => d(31 downto 0), OEN => gnd(0),  Q => q(31 downto 0));
  end generate;
 
    -- bilgiday for 64KB and 128KB ahbram (using 13x8 mems as building blocks)
  dataout <= q(dbits -1 downto 0);



end;



