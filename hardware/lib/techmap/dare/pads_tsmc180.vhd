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
-- Package:     tsmc180pads
-- File:        pads_tsmc180.vhd
-- Author:      Chinmay Deshpande 
-- Description: tsmc180 pad wrappers
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
package darepads is
  -- input pad

    component PDIDGZ port (PAD: in std_logic; C : out std_logic); end component;

  -- input pad with pull-down 

    component PDDSDGZ port (PAD: in std_logic; C : out std_logic); end component;
        
  -- input pad with pull-up 

    component PDUDGZ port (PAD: in std_logic; C : out std_logic); end component;

  -- schmitt input pad

    component PDISDGZ port (PAD: in std_logic; C : out std_logic); end component;

  -- output pads

    component PDO04CDG port(I : in std_logic; PAD : out std_logic);end component; 
    component PDO12CDG port(I : in std_logic; PAD : out std_logic);end component;
    component PDO16CDG port(I : in std_logic; PAD : out std_logic);end component;

  -- bidirectional pads (and tri-state output pads)

    component PDD04DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD12DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD16DGsd port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;

end;

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library work;
use work.all;

-- pragma translate_off
library dare;
use dare.PDIDGZ;
use dare.PDDSDGZ;
use dare.PDISDGZ;
use dare.PDUDGZ;
-- pragma translate_on

entity dare_inpad is
  generic (level : integer := 0; voltage : integer := 0; filter : integer := 0);
  port (pad : in std_logic; o : out std_logic);
end; 
architecture rtl of dare_inpad is

    component PDIDGZ port (PAD: in std_logic; C : out std_logic); end component;
    component PDUDGZ port (PAD: in std_logic; C : out std_logic); end component;
    component PDDSDGZ port (PAD: in std_logic; C : out std_logic); end component;
    component PDISDGZ port (PAD: in std_logic; C : out std_logic); end component;

  signal localout,localpad : std_logic;

begin
  norm : if filter = 0 generate
    ip : PDIDGZ port map (PAD => localpad, C => localout);
  end generate;
  pu : if filter = pullup generate
    ip : PDUDGZ port map (PAD => localpad, C => localout);
  end generate;
  pd : if filter = pulldown generate
    ip : PDDSDGZ port map (PAD => localpad, C => localout);
  end generate;
  sch : if filter = schmitt generate
    ip : PDISDGZ port map (PAD => localpad, C => localout);
  end generate;
  
  o <= localout;
  localpad <= pad;
  
end;

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library work;
use work.all;

-- pragma translate_off
library dare;
use dare.PDD04DGZ;
use dare.PDD12DGZ;
use dare.PDD16DGZ;
-- pragma translate_on

entity dare_iopad  is
  generic (level : integer := 0; slew : integer := 0;
     voltage : integer := 0; strength : integer := 0);
  port (pad : inout std_logic; i, en : in std_logic; o : out std_logic);
end ;
architecture rtl of dare_iopad is
    component PDD04DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD12DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD16DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;

  signal localen : std_logic;
  signal localout,localpad : std_logic;

begin

  localen <= not en;

  f4 : if (strength <= 4)  generate
      op : PDD04DGZ port map (I => i, PAD => pad, C => o, OEN => en);
  end generate;
  f12 : if (strength > 4)  and (strength <= 12)  generate
      op : PDD12DGZ port map (I => i, PAD => pad, C => o, OEN => en);
  end generate;
  f16 : if (strength > 12)  generate
      op : PDD16DGZ port map (I => i, PAD => pad, C => o, OEN => en);
  end generate;

end;

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library work;
use work.all;

-- pragma translate_off
library dare;
use dare.PDO04CDG;
use dare.PDO12CDG;
use dare.PDO16CDG;
-- pragma translate_on

entity dare_outpad  is
  generic (level : integer := 0; slew : integer := 0;
     voltage : integer := 0; strength : integer := 0);
  port (pad : out std_logic; i : in std_logic);
end ;
architecture rtl of dare_outpad is

    component PDO04CDG port(I : in std_logic; PAD : out std_logic);end component;  
      component PDO12CDG port(I : in std_logic; PAD : out std_logic);end component;
      component PDO16CDG port(I : in std_logic; PAD : out std_logic);end component;

  signal localout,localpad : std_logic;

begin
  f4 : if (strength <= 4)  generate
      op : PDO04CDG port map (I => i, PAD => localpad);
  end generate;
  f12 : if (strength > 4) and (strength <= 12)  generate
      op : PDO12CDG port map (I => i, PAD => localpad);
  end generate;
  f16 : if (strength > 12) generate
      op : PDO16CDG port map (I => i, PAD => localpad);
  end generate;

  pad <= localpad;

end;

library ieee;
use ieee.std_logic_1164.all;
library techmap;
use techmap.gencomp.all;
library work;
use work.all;

-- pragma translate_off
library dare;
use dare.PDD04DGZ;
use dare.PDD12DGZ;
use dare.PDD16DGZ;
-- pragma translate_on

entity dare_toutpad  is
  generic (level : integer := 0; slew : integer := 0;
     voltage : integer := 0; strength : integer := 0);
  port (pad : out std_logic; i, en : in std_logic);
end ;
architecture rtl of dare_toutpad is

    component PDD04DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD12DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;
    component PDD16DGZ port(I : in std_logic; OEN : in std_logic; PAD : inout std_logic; C : out std_logic); end component;

  signal localpad : std_logic;
  signal en_bar : std_logic;
begin
 
  en_bar <= not en;
  f4 : if (strength <= 4)  generate
      op : PDD04DGZ port map (I => i, PAD => localpad, C => OPEN, OEN => en_bar);
  end generate;
  f12 : if (strength > 4)  and (strength <= 12)  generate
      op : PDD12DGZ port map (I => i, PAD => localpad, C => OPEN, OEN => en_bar);
  end generate;
  f16 : if (strength > 12)  generate
      op : PDD16DGZ port map (I => i, PAD => localpad, C => OPEN, OEN => en_bar);
  end generate;

  pad <= localpad;

end;

