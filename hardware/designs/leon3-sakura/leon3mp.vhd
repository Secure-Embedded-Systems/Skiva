------------------------------------------------------------------------------
--  LEON3 Demonstration design
--  Copyright (C) 2013 Aeroflex Gaisler
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
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library grlib;
use grlib.amba.all;
use grlib.stdlib.all;
use grlib.devices.all;
library techmap;
use techmap.gencomp.all;
use techmap.allclkgen.all;
library gaisler;
use gaisler.memctrl.all;
use gaisler.leon3.all;
use gaisler.uart.all;
use gaisler.misc.all;
use gaisler.jtag.all;
use gaisler.spi.all;
--pragma translate_off
use gaisler.sim.all;
--pragma translate_on
library esa;
use esa.memoryctrl.all;
use work.config.all;

entity leon3mp is
  generic (
    fabtech  : integer := CFG_FABTECH;
    memtech  : integer := CFG_MEMTECH;
    padtech  : integer := CFG_PADTECH;
    clktech  : integer := CFG_CLKTECH;
    disas    : integer := CFG_DISAS;     -- Enable disassembly to console
    dbguart  : integer := CFG_DUART;     -- Print UART on console
    pclow    : integer := CFG_PCLOW
    );
  port (
    clk             : in    std_ulogic; -- clock input
    clk48in             : in    std_ulogic; -- clock input
    clkout             : out    std_ulogic; -- output clock same as input clock
    clk24out             : out    std_ulogic; -- output clock same as input clock
   
   -- Buttons & LEDs
    btnCpuResetn    : in    std_ulogic; -- Reset button
    led             : out   std_logic_vector(1 downto 0);
    gpio             : inout   std_logic_vector(7 downto 0);
    errorn       : out std_ulogic;    -- led(7)
    
     -- RS232 APB Uart 
     rxd1 : in std_logic;
     txd1 : out std_logic;
  
    -- USB-RS232 interface
    RsRx            : in    std_logic;
    RsTx            : out   std_logic;

    -- spi memory
    spi_miso    : in  std_ulogic;
    spi_mosi    : out std_ulogic;
    spi_sck     : out std_ulogic;
    spi_csn  : out std_ulogic;

    -- changed trigger_out to 4 bits
    alarm1_emsensor: out std_ulogic;
    alarm2_aesenc: out std_ulogic;
    alarm3_aesdec: out std_ulogic;
	 triggerout: out std_logic_vector(3 downto 0);
     alarmin : in std_ulogic;
	 alarmout : out std_ulogic;
	extsave : in std_ulogic;
     boot_select: in std_ulogic
  );
end;

architecture rtl of leon3mp is
  signal vcc : std_logic;
  signal gnd : std_logic;

  signal alarm_combined : std_logic_vector(3 downto 0);
  signal alarm_sbox_em : std_ulogic;

  -- Memory controler signals
  signal memi : memory_in_type;
  signal memo : memory_out_type;
  signal wpo  : wprot_out_type;
  
  -- AMBA bus signals
  signal apbi_bridge0  : apb_slv_in_type;
  signal apbo_bridge0  : apb_slv_out_vector := (others => apb_none);
  signal apbi_bridge1  : apb_slv_in_type;
  signal apbo_bridge1  : apb_slv_out_vector := (others => apb_none);
  signal apbi_bridge2  : apb_slv_in_type;
  signal apbo_bridge2  : apb_slv_out_vector := (others => apb_none);

 
  signal ahbsi : ahb_slv_in_type;
  signal ahbso : ahb_slv_out_vector := (others => ahbs_none);
  signal ahbmi : ahb_mst_in_type;
  signal ahbmo : ahb_mst_out_vector := (others => ahbm_none);

  signal cgi : clkgen_in_type;
  signal cgo : clkgen_out_type;
  
  signal gpioi : gpio_in_type;
  signal gpioo : gpio_out_type;

  signal u1i, dui : uart_in_type;
  signal u1o, duo : uart_out_type;

  signal irqi : irq_in_vector(0 to 0);
  signal irqo : irq_out_vector(0 to 0);

  signal dbgi : l3_debug_in_vector(0 to 0);
  signal dbgo : l3_debug_out_vector(0 to 0);

  signal dsui : dsu_in_type;
  signal dsuo : dsu_out_type;
  signal ndsuact : std_ulogic;

  signal gpti : gptimer_in_type;
  signal gpto : gptimer_out_type;

  signal spmi : spimctrl_in_type;
  signal spmo : spimctrl_out_type;

  signal alarm_aes_encrypt : std_ulogic;
  signal alarm_aes_decrypt : std_ulogic;
  signal alarm_emsensor : std_ulogic;

  signal clkm, rstn, clk24out_r         : std_ulogic;
  signal tck, tms, tdi, tdo : std_ulogic;
  signal rstraw             : std_logic;
  signal lock               : std_logic;

  attribute keep                     : boolean;
  attribute keep of lock             : signal is true;
  attribute keep of clkm             : signal is true;

  constant clock_mult : integer := 20;      -- Clock multiplier
  constant clock_div  : integer := 20;      -- Clock divider
  constant BOARD_FREQ : integer := 48000;  -- CLK input frequency in KHz
  constant CPU_FREQ   : integer := BOARD_FREQ * clock_mult / clock_div;  -- CPU freq in KHz
  
begin

----------------------------------------------------------------------
---  Reset and Clock generation  -------------------------------------
----------------------------------------------------------------------
  
  vcc <= '1';
  gnd <= '0';
  clkm <= clk;
  rstn <= not btnCpuResetn;

  cgi.pllctrl <= "00";
  cgi.pllrst <= rstraw;
--  rst0 : rstgen generic map (acthigh => 1)
--    port map (btnCpuResetn, clkm, lock, rstn, rstraw);
--  lock <= cgo.clklock;

alarm_combined(0) <= '0';
alarm_combined(1) <= '0';
alarm_combined(2) <= '0';
alarm_combined(3) <= '0';
---------------------------------------------------------------------- 
---  AHB CONTROLLER --------------------------------------------------
----------------------------------------------------------------------

  ahb0 : ahbctrl
    generic map (ioen => 1, nahbm => 4, nahbs => 10)
    port map (rstn, clkm, ahbmi, ahbmo, ahbsi, ahbso);

----------------------------------------------------------------------
---  LEON3 processor and DSU -----------------------------------------
----------------------------------------------------------------------

  -- LEON3 processor
  u0 : leon3s
    generic map (hindex=>0, 
				 fabtech=>fabtech, 
				 memtech=>memtech,
				 nwindows=>8, 
				 dsu=>CFG_DSU,       
				 fpu=>0,       
				 v8=>0,        
				 cp=>0,        
				 mac=>0,       
				 pclow=>CFG_PCLOW,    
				 notag=>CFG_NOTAG,    
				 nwp=>CFG_NWP,       
				 icen=>CFG_ICEN,      
				 irepl=>CFG_IREPL,     
				 isets=>CFG_ISETS,     
				 ilinesize=>CFG_ILINE,
				 isetsize=>CFG_ISETSZ,  
				 isetlock=>CFG_ILOCK,  
				 dcen=>CFG_DCEN,      
				 drepl=>CFG_DREPL,     
				 dsets=>CFG_DSETS,     
				 dlinesize=>CFG_DLINE, 
				 dsetsize=>CFG_DSETSZ,  
				 dsetlock=>CFG_DLOCK,  
				 dsnoop=>CFG_DSNOOP,    
				 ilram=>CFG_ILRAMEN,     
				 ilramsize=>CFG_ILRAMSZ, 
				 ilramstart=>CFG_ILRAMADDR,
				 dlram=>CFG_DLRAMEN, 
				 dlramsize=>CFG_DLRAMSZ,
				 dlramstart=>CFG_DLRAMADDR,
				 mmuen=>CFG_MMUEN,     
                 itlbnum=> 8,  
                 --dtlbnum=>   
                 tlb_type=> 2,  
                 tlb_rep=>  0 ,
                 lddel=>CFG_LDDEL,     
                 disas=>CFG_DISAS,     
                 tbuf=> 1,     
                 pwd=>CFG_PWD,       
                 svt=>CFG_SVT,       
                 rstaddr => CFG_RSTADDR,   
                 --smp=>       
                 --cached=>    
                 --scantest=>  
                 --mmupgsz=>   
                 bp=>CFG_BP)        
   port map (clkm, rstn, ahbmi, ahbmo(0), ahbsi, ahbso, irqi(0), irqo(0), dbgi(0), dbgo(0), open, alarm_combined, alarmout, alarm1_emsensor, alarm2_aesenc, alarm3_aesdec, triggerout, '0', boot_select);

   
    errorn <= dbgo(0).error ;
  -- LEON3 Debug Support Unit    
  dsu0 : dsu3
    generic map (hindex => 2, ncpu => 1, tech => memtech, irq => 0, kbytes => 0)
    port map (rstn, clkm, ahbmi, ahbsi, ahbso(2), dbgo, dbgi, dsui, dsuo);
   dsui.enable <= '1';
   dsui.break <= '0';
  
 -- SWITCH(7) = dsuen
 -- dsuen_pad : inpad generic map (tech => padtech) port map (switch(7), dsui.enable);

  -- SWITCH(6) = dsubre
 -- dsubre_pad : inpad generic map (tech => padtech) port map (switch(6), dsui.break);

  -- LED(6) = dsuact
 -- dsuact_pad : outpad generic map (tech => padtech) port map (led(6), dsuo.active);
  
  -- Debug UART
  dcom0 : ahbuart 
    generic map (hindex => 1, pindex => 4, paddr => 7)
    port map (rstn, clkm, dui, duo, apbi_bridge0, apbo_bridge0(4), ahbmi, ahbmo(1));
  dsurx_pad : inpad generic map (tech  => padtech) port map (RsRx, dui.rxd);
  dsutx_pad : outpad generic map (tech => padtech) port map (RsTx, duo.txd);
  led(0) <= not dui.rxd;
  led(1) <= not duo.txd;

  ahbjtag0 : ahbjtag generic map(tech => fabtech, hindex => 3)
    port map(rstn, clkm, tck, tms, tdi, tdo, ahbmi, ahbmo(3),
             open, open, open, open, open, open, open, gnd);

-----------------------------------------------------------------------
---  AHB ROM ----------------------------------------------------------
-----------------------------------------------------------------------

  ahbrom0 : entity work.ahbrom
   generic map (hindex => 6, haddr => CFG_AHBRODDR, pipe => CFG_AHBROPIP)
   port map ( rstn, clkm, ahbsi, ahbso(6));
	
-----------------------------------------------------------------------
---  AHB RAM ----------------------------------------------------------
-----------------------------------------------------------------------
	 ahbram0 : ahbram generic map (hindex => 7, haddr => CFG_AHBRADDR,
	 tech => CFG_MEMTECH, pipe => CFG_AHBRPIPE, kbytes => CFG_AHBRSZ)
	 port map ( rstn, clkm, ahbsi, ahbso(7));

----------------------------------------------------------------------
---  APB Bridge and various periherals -------------------------------
----------------------------------------------------------------------

  apb0 : apbctrl       -- APB Bridge
    generic map (hindex => 1, haddr => CFG_APBADDR0)
    port map (rstn, clkm, ahbsi, ahbso(1), apbi_bridge0, apbo_bridge0);
  
  apb1 : apbctrl       -- APB Bridge
    generic map (hindex => 8, haddr => CFG_APBADDR1)
    port map (rstn, clkm, ahbsi, ahbso(8), apbi_bridge1, apbo_bridge1);
  
  apb2 : apbctrl       -- APB Bridge
    generic map (hindex => 9, haddr => CFG_APBADDR2)
    port map (rstn, clkm, ahbsi, ahbso(9), apbi_bridge2, apbo_bridge2);

  irqctrl0 : irqmp     -- Interrupt controller
    generic map (pindex => 2, paddr => 2, ncpu => 1)
    port map (rstn, clkm, apbi_bridge0, apbo_bridge0(2), irqo, irqi);

  uart1 : apbuart      -- UART 1
    generic map (pindex   => 1, paddr => 1, pirq => 2, console => 1, fifosize => CFG_UART1_FIFO)
    port map (rstn, clkm, apbi_bridge0, apbo_bridge0(1), u1i, u1o);
  u1i.rxd    <= rxd1;
 -- u1i.rxd    <= '0';
  u1i.ctsn   <= '0';
  u1i.extclk <= '0';
  txd1       <= u1o.txd;
  
	--gpio0 : generate -- GR GPIO unit
	grgpio0: grgpio
		generic map( pindex => 3, paddr => 3, imask => CFG_GRGPIO_IMASK, nbits => 8)
		port map( rstn, clkm, apbi_bridge0, apbo_bridge0(3), gpioi, gpioo);
		pio_pads : for i in 0 to 7 generate
		pio_pad : iopad generic map (tech => padtech)
		port map (gpio(i), gpioo.dout(i), gpioo.oen(i), gpioi.din(i));
	end generate;
	--end generate;

-----------------------------------------------------------------------
-- TIMER ----------------------
-----------------------------------------------------------------------
  gpt : if CFG_GPT_ENABLE /= 0 generate
    gptimer0 : gptimer      -- timer unit
      generic map (pindex => 6, paddr => 6, pirq => CFG_GPT_IRQ,
       sepirq => CFG_GPT_SEPIRQ, sbits => CFG_GPT_SW, ntimers => CFG_GPT_NTIM,
       nbits => CFG_GPT_TW, wdog => CFG_GPT_WDOGEN*CFG_GPT_WDOG)
      port map (rstn, clkm, apbi_bridge0, apbo_bridge0(6), gpti, gpto);
    gpti.dhalt <= dsuo.tstop; gpti.extclk <= '0';
    --wdogn <= gpto.wdogn when OEPOL = 0 else gpto.wdog;
  end generate;
  notim : if CFG_GPT_ENABLE = 0 generate apbo_bridge0(6) <= apb_none; end generate;

-----------------------------------------------------------------------
--  COPROCESSORS ----------------------
-----------------------------------------------------------------------

  spimc: if CFG_SPICTRL_ENABLE = 0 and CFG_SPIMCTRL = 1 generate
    spimctrl0 : spimctrl        -- SPI Memory Controller
      generic map (hindex => 5, hirq => 5, faddr => 16#100#, fmask => 16#ff0#,
                   ioaddr => 16#002#, iomask => 16#fff#,
                   spliten => CFG_SPLIT, oepol  => 0,
                   sdcard => CFG_SPIMCTRL_SDCARD,
                   readcmd => CFG_SPIMCTRL_READCMD,
                   dummybyte => CFG_SPIMCTRL_DUMMYBYTE,
                   dualoutput => CFG_SPIMCTRL_DUALOUTPUT,
                   scaler => CFG_SPIMCTRL_SCALER,
                   altscaler => CFG_SPIMCTRL_ASCALER,
                   pwrupcnt => CFG_SPIMCTRL_PWRUPCNT)
      port map (rstn, clk, ahbsi, ahbso(5), spmi, spmo);


    -- MISO is shared with Flash data 0
    spmi.miso <= spi_miso;
    spi_mosi <= spmo.mosi;
    spi_sck <= spmo.sck;
    spi_csn <= spmo.csn;
    clkout <= clk;
  end generate;

  nospimc: if ((CFG_SPICTRL_ENABLE = 0 and CFG_SPIMCTRL = 0) or
              (CFG_SPICTRL_ENABLE = 1 and CFG_SPIMCTRL = 1) or
              (CFG_SPICTRL_ENABLE = 1 and CFG_SPIMCTRL = 0)) generate
   --spi_mosi <= '0';
   --spi_sck <= '0';
   --spi_csn <= '1';
   spi_mosi <= alarmin;
   spi_sck <= rxd1;
   spi_csn <= extsave;
   clkout <= spi_miso;
  end generate;
	
-----------------------------------------------------------------------
--  Test report module, only used for simulation ----------------------
-----------------------------------------------------------------------

--pragma translate_off
  test0 : ahbrep generic map (hindex => 4, haddr => 16#200#)
    port map (rstn, clkm, ahbsi, ahbso(4));
--pragma translate_on

-----------------------------------------------------------------------
---  Boot message  ----------------------------------------------------
-----------------------------------------------------------------------

-- pragma translate_off
  x : report_design
    generic map (
      msg1 => "LEON3 Demonstration design",
      fabtech => tech_table(fabtech), memtech => tech_table(memtech),
      mdel => 1
      );
-- pragma translate_on
  clk24out <= clk24out_r;
  clk24 : process (clk48in) -- bilgiday calibration support
  begin 
    if rising_edge(clk48in) then 
--      if rstn = '0' then
  --      clk24out_r <= '0';
    --  else
	clk24out_r <= not clk24out_r;
--	  end if;
   end if;
  end process;


end rtl;
