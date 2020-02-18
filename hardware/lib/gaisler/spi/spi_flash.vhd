------------------------------------------------------------------------------
--  This file is a part of the GRLIB VHDL IP LIBRARY
--  Copyright (C) 2003 - 2008, Gaisler Research
--  Copyright (C) 2008 - 2014, Aeroflex Gaisler
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
-------------------------------------------------------------------------------
-- Entity: spi_flash
-- File:   spi_flash.vhd
-- Author: Jan Andersson - Aeroflex Gaisler AB
--         jan@gaisler.com
--
-- Description: 
--
--     SPI flash simulation models.
--
--     +--------------------------------------------------------+
--     | ftype  |  Memory device                                |
--     +--------+-----------------------------------------------+
--     | 1      |  SD card                                      |
--     +--------+-----------------------------------------------+
--     | 3      |  Simple SPI                                   |
--     +--------+-----------------------------------------------+
--     | 4      |  SPI memory device                            |
--     +--------+-----------------------------------------------+
--
-- For ftype => 4, the memoffset generic can be used to specify an address
-- offset that till be automatically be removed by the memory model. For
-- instance, memoffset => 16#1000# and an access to 0x1000 will read the
-- internal memory array at offset 0x0. This is a quick hack to support booting
-- from SPIMCTRL that has an offset specified and not having to modify the
-- SREC.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

library grlib, gaisler;
use grlib.stdlib.all;
use grlib.stdio.all;
--use gaisler.sim.all;

entity spi_flash is
  
  generic (
    ftype      : integer := 0;               -- Flash type
    debug      : integer := 0;               -- Debug output
    fname      : string  := "prom.srec";     -- File to read from
    readcmd    : integer := 16#0B#;          -- SPI memory device read command
    dummybyte  : integer := 1;
    dualoutput : integer := 0;
    memoffset  : integer := 0);              -- Addr. offset automatically removed
                                             -- by Flash model
  port (
    sck : in    std_ulogic;
    di  : in std_logic;
    do  : out std_logic;
    csn : in std_logic;
    -- Test control inputs
    sd_cmd_timeout  : in std_ulogic := '0';
    sd_data_timeout : in std_ulogic := '0'
    );

end spi_flash;

architecture sim of spi_flash is

  -- Description: Simple, incomplete, model of SD card

  -- purpose: Simple, incomplete, model of SPI Flash device
   -- purpose: SPI memory device that reads input from prom.srec
  procedure spi_memory_model (
    constant dbg        : in    integer;
    constant readcmd    : in    integer;
    constant dummybyte  : in    boolean;
    constant dualoutput : in    boolean;
    signal   sck        : in    std_ulogic;
    signal   di         : in std_ulogic;
    signal   do         : out std_ulogic;
    signal   csn        : in    std_ulogic) is

    constant readinst : std_logic_vector(7 downto 0) :=
      conv_std_logic_vector(readcmd, 8);
    
    variable received_command : std_ulogic := '0';
    variable respond          : std_ulogic := '0';

    variable response         : std_logic_vector(31 downto 0);
    variable address          : std_logic_vector(23 downto 0);
    variable indata           : std_logic_vector(7 downto 0);
    variable command          : std_logic_vector(39 downto 0);
    variable index            : integer;

    file fload : text open read_mode is fname;
    variable fline : line;
    variable fchar : character; 
    variable rtype : std_logic_vector(3 downto 0);
    variable raddr : std_logic_vector(31 downto 0);
    variable rlen  : std_logic_vector(7 downto 0);
    variable rdata : std_logic_vector(0 to 127);

    variable wordaddr : integer;
    
    type mem_type is array (0 to 8388607) of std_logic_vector(31 downto 0);
    variable mem : mem_type := (others => (others => '1'));
    
  begin  -- spi_memory_model
    --di <= 'Z'; 
    do <= 'Z';

    -- Load memory data from file
    while not endfile(fload) loop
      readline(fload, fline);
      read(fline, fchar);
      if fchar /= 'S' or fchar /= 's' then
        hread(fline, rtype);
        hread(fline, rlen);
        raddr := (others => '0');
        case rtype is 
          when "0001" =>
            hread(fline, raddr(15 downto 0));
          when "0010" =>
            hread(fline, raddr(23 downto 0));
          when "0011" =>
            hread(fline, raddr);
            raddr(31 downto 24) := (others => '0');
          when others => next;
        end case;

        hread(fline, rdata);
        for i in 0 to 3 loop
          mem(conv_integer(raddr(31 downto 2)+i)) :=
              rdata(i*32 to i*32+31);
        end loop;
      end if;
    end loop;
    
    loop 
      if csn /= '0' then wait until csn = '0'; end if;

      index := 0; command := (others => '0');
      while received_command = '0' and csn = '0' loop
        wait until rising_edge(sck);
        indata := indata(6 downto 0) & di;
        index := index + 1;
        if index = 8 then
          command := command(31 downto 0) & indata;
          if dbg /= 0 then
          --    Print(time'image(now) & ": spi_memory_model: received byte: " &
            --      tost(indata));
          end if;
          if ((dummybyte and command(39 downto 32) = readinst) or
              (not dummybyte and command(31 downto 24) = readinst)) then
            received_command := '1';
          end if;
          index := 0;
        end if;
      end loop;

      if received_command = '1' then
        response := (others => '0');
        if dummybyte then
          address := command(31 downto 8);
        else
          address := command(23 downto 0);
        end if;

        if dbg /= 0 then
         -- Print(time'image(now) & ": spi_memory_model: received address: " &
           --     tost(address));
          if memoffset /= 0 then
            --Print(time'image(now) & ": spi_memory_model: address after removed offset " &
             --   tost(address-memoffset));
          end if;
        end if;

        if memoffset /= 0 then
          address := address - memoffset;
        end if;
        
        index := 31 - conv_integer(address(1 downto 0)) * 8;
        while csn = '0' loop
          response := mem(conv_integer(address(23 downto 2)));
          if dbg /= 0 then
            --Print(time'image(now) & ": spi_memory_model: responding with data: " &
              --    tost(response(index downto 0)));
          end if;
          while index >= 0 and csn = '0' loop
            wait until falling_edge(sck) or csn = '1';
            if dualoutput then
              do <= response(index);
             --di <= 'Z';
              index := index - 2;
            else
              do <= response(index);
              index := index - 1;
            end if;
          end loop;
          index := 31;
          address := address + 4;
        end loop;
        if dualoutput then
         -- di <= 'Z';
           -- do <= '1';
        end if;
        do <= 'Z';
        received_command := '0';
      else
        do <= 'Z';
      end if;
    end loop;
  end spi_memory_model;
  
  signal vdd : std_ulogic := '1';
  signal gnd : std_ulogic := '0';
  
begin  -- sim

--   ftype0: if ftype = 0 generate
--     csn <= 'Z';
--     di <= 'Z';
--     flash0 : s25fl064a
--       generic map (tdevice_PU => 1 us,
--                    TimingChecksOn => true,
--                    MsgOn => debug = 1,
--                    UserPreLoad => true)
--       port map (SCK => sck, SI => di, CSNeg => csn, HOLDNeg => vdd,
--                 WNeg => vdd, SO => do);
--   end generate ftype0;

--  ftype1: if ftype = 1 generate
   -- csn <= 'H';
   -- di <= 'Z';
--    simple_sd_model(debug, sck, di, do, csn, sd_cmd_timeout, sd_data_timeout);
--  end generate ftype1;

--   ftype2: if ftype = 2 generate
--     csn <= 'Z';
--     di <= 'Z';
--     flash0 : m25p80
--       generic map (TimingChecksOn => false,
--                    MsgOn => debug = 1,
--                    UserPreLoad => true)
--       port map (C => sck, D => di, SNeg => csn, HOLDNeg => vdd,
--                 WNeg => vdd, Q => do);
--   end generate ftype2;

 -- ftype3: if ftype = 3 generate
   -- csn <= 'Z';
 --   simple_spi_flash_model (
--      dbg        => debug,
--      readcmd    => readcmd,
--      dummybyte  => dummybyte /= 0,
--      dualoutput => dualoutput /= 0,
--      sck        => sck,
--      di         => di,
--      do         => do,
--      csn        => csn);
--  end generate ftype3;

  --ftype4: if ftype = 4 generate
    spi_memory_model (
      dbg        => debug,
      readcmd    => readcmd,
      dummybyte  => dummybyte /= 0,
      dualoutput =>  dualoutput /= 0,
      sck        => sck,
      di         => di,
      do         => do,
      csn        => csn);
    --csn <= 'Z';
  -- end generate ftype4;
  
  notsupported: if ftype > 4 generate
    assert false report "spi_flash: no model" severity failure;
  end generate notsupported;
  
end sim;
