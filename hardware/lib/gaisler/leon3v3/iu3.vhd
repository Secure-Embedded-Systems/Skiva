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
-----------------------------------------------------------------------------
-- Entity:      iu3
-- File:        iu3.vhd
-- Author:      Jiri Gaisler, Edvin Catovic, Gaisler Research
-- Description: LEON3 7-stage integer pipline
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library grlib;
use grlib.config_types.all;
use grlib.config.all;
use grlib.sparc.all;
use grlib.stdlib.all;
library techmap;
use techmap.gencomp.all;
library gaisler;
use gaisler.leon3.all;
use gaisler.libiu.all;
use gaisler.libfpu.all;
use gaisler.arith.all;
-- pragma translate_off
use grlib.sparc_disas.all;
-- pragma translate_on

entity iu3 is
  generic (
    nwin     : integer range 2 to 32 := 8;
    isets    : integer range 1 to 4 := 1;
    dsets    : integer range 1 to 4 := 1;
    fpu      : integer range 0 to 15 := 0;
    v8       : integer range 0 to 63 := 0;
    cp, mac  : integer range 0 to 1 := 0;
    dsu      : integer range 0 to 1 := 0;
    nwp      : integer range 0 to 4 := 0;
    pclow    : integer range 0 to 2 := 2;
    notag    : integer range 0 to 1 := 0;
    index    : integer range 0 to 15:= 0;
    lddel    : integer range 1 to 2 := 2;
    irfwt    : integer range 0 to 1 := 0;
    disas    : integer range 0 to 2 := 0;
    tbuf     : integer range 0 to 64 := 0;  -- trace buf size in kB (0 - no trace buffer)
    pwd      : integer range 0 to 2 := 0;   -- power-down
    svt      : integer range 0 to 1 := 0;   -- single-vector trapping
    rstaddr  : integer := 16#00000#;   -- reset vector MSB address
    smp      : integer range 0 to 15 := 0;  -- support SMP systems
    fabtech  : integer range 0 to NTECH := 0;    
    clk2x    : integer := 0;
    bp       : integer range 0 to 2 := 1
  );
  port (
    clk   : in  std_ulogic;
    rstn  : in  std_ulogic;
    holdn : in  std_ulogic;
    ici   : out icache_in_type;
    ico   : in  icache_out_type;
    dci   : out dcache_in_type;
    dco   : in  dcache_out_type;
    rfi   : out iregfile_in_type;
    rfo   : in  iregfile_out_type;
    irqi  : in  l3_irq_in_type;
    irqo  : out l3_irq_out_type;
    dbgi  : in  l3_debug_in_type;
    dbgo  : out l3_debug_out_type;
    muli  : out mul32_in_type;
    mulo  : in  mul32_out_type;
    divi  : out div32_in_type;
    divo  : in  div32_out_type;
    fpo   : in  fpc_out_type;
    fpi   : out fpc_in_type;
    cpo   : in  fpc_out_type;
    cpi   : out fpc_in_type;
    tbo   : in  tracebuf_out_type;
    tbi   : out tracebuf_in_type;
    sclk   : in  std_ulogic;
 -- bilgiday
    clkout : out std_ulogic;
    alarmin : in std_logic_vector(3 downto 0);
    alarmout : out std_ulogic;
    alarm1_emsensor : out std_ulogic;
    alarm2_aesenc : out std_ulogic;
    alarm3_aesdec : out std_ulogic;
    triggerout : out std_logic_vector(3 downto 0);
	extsave: in std_ulogic;
	boot_select: in std_ulogic
    );


  attribute sync_set_reset of rstn : signal is "true"; 
 
end;

architecture rtl of iu3 is

	attribute KEEP : string;

  constant ISETMSB : integer := log2x(isets)-1;
  constant DSETMSB : integer := log2x(dsets)-1;
  constant RFBITS : integer range 6 to 10 := log2(NWIN+1) + 4;
--  constant SRFBITS : integer := RFBITS; -- PK
  constant NWINLOG2   : integer range 1 to 5 := log2(NWIN);
  constant CWPOPT : boolean := (NWIN = (2**NWINLOG2));
  constant CWPMIN : std_logic_vector(NWINLOG2-1 downto 0) := (others => '0');
  constant CWPMAX : std_logic_vector(NWINLOG2-1 downto 0) := 
        conv_std_logic_vector(NWIN-1, NWINLOG2);
  constant FPEN   : boolean := (fpu /= 0);
  constant CPEN   : boolean := (cp = 1);
  constant MULEN  : boolean := (v8 /= 0);
  constant MULTYPE: integer := (v8 / 16);
  constant DIVEN  : boolean := (v8 /= 0);
  constant MACEN  : boolean := (mac = 1);
  constant MACPIPE: boolean := (mac = 1) and (v8/2 = 1);
  constant IMPL   : integer := 15;
  constant VER    : integer := 3;
  constant DBGUNIT : boolean := (dsu = 1);
  constant TRACEBUF   : boolean := (tbuf /= 0);
  constant TBUFBITS : integer := 10 + log2(tbuf) - 4;
  constant PWRD1  : boolean := false; --(pwd = 1) and not (index /= 0);
  constant PWRD2  : boolean := (pwd /= 0); --(pwd = 2) or (index /= 0);
  constant RS1OPT : boolean := (is_fpga(FABTECH) /= 0);
  constant DYNRST : boolean := (rstaddr = 16#FFFFF#);

  constant CASAEN : boolean := (notag = 0) and (lddel = 1);
  signal BPRED : std_logic;

  subtype word is std_logic_vector(31 downto 0);
  subtype pctype is std_logic_vector(31 downto PCLOW);
  subtype rfatype is std_logic_vector(RFBITS-1 downto 0); -- PK: RFBITS Reg File size ??
  subtype cwptype is std_logic_vector(NWINLOG2-1 downto 0); -- PK: choose the reg window
  type icdtype is array (0 to isets-1) of word; -- PK: isets of words
  type dcdtype is array (0 to dsets-1) of word;
  
  
  type dc_in_type is record
    signed, enaddr, read, write, lock, dsuen : std_ulogic;
    size : std_logic_vector(1 downto 0);
    asi  : std_logic_vector(7 downto 0);    
  end record;
  
  type pipeline_ctrl_type is record
    pc    : pctype;
    inst  : word;
    cnt   : std_logic_vector(1 downto 0);
    rd    : rfatype;
    tt    : std_logic_vector(5 downto 0);
    trap  : std_ulogic;
    annul : std_ulogic;
    wreg  : std_ulogic;
    wicc  : std_ulogic;
    wy    : std_ulogic;
    ld    : std_ulogic;
    pv    : std_ulogic;
    rett  : std_ulogic;
	-- PK: write to secure reg file
--	swreg : std_ulogic;
  end record;
  
  type fetch_reg_type is record
    pc     : pctype;
    branch : std_ulogic;
  end record;
  
  type decode_reg_type is record
    pc    : pctype;
    inst  : icdtype;
    cwp   : cwptype;
    set   : std_logic_vector(ISETMSB downto 0); --- ????
    mexc  : std_ulogic; --- ????
    cnt   : std_logic_vector(1 downto 0); --- ????
    pv    : std_ulogic; --- ????
    annul : std_ulogic; --- ????
    inull : std_ulogic; --- ????
    step  : std_ulogic; --- ????
    divrdy: std_ulogic; --- ????
  end record;
  
  type regacc_reg_type is record
	branch : std_ulogic;
    ctrl  : pipeline_ctrl_type;
    rs1   : std_logic_vector(4 downto 0);
    rfa1, rfa2 : rfatype;
    rsel1, rsel2 : std_logic_vector(2 downto 0);
    rfe1, rfe2 : std_ulogic;
    cwp   : cwptype;
    imm   : word;
    ldcheck1 : std_ulogic;
    ldcheck2 : std_ulogic;
    ldchkra : std_ulogic;
    ldchkex : std_ulogic;
    su : std_ulogic;
    et : std_ulogic;
    wovf : std_ulogic;
    wunf : std_ulogic;
    ticc : std_ulogic;
    jmpl : std_ulogic;
    step  : std_ulogic;            
    mulstart : std_ulogic;            
    divstart : std_ulogic;
    bp, nobp : std_ulogic;
  end record;
  
  type execute_reg_type is record
	branch : std_ulogic;
    ctrl   : pipeline_ctrl_type;
    op1    : word;
    op2    : word;
    aluop  : std_logic_vector(3 downto 0);      -- Alu operation -- Pantea 2->3
    alusel : std_logic_vector(1 downto 0);      -- Alu result select
    aluadd : std_ulogic;
    alucin : std_ulogic;
    ldbp1, ldbp2 : std_ulogic;
    invop2 : std_ulogic;
    shcnt  : std_logic_vector(4 downto 0);      -- shift count
    sari   : std_ulogic;                                -- shift msb
    shleft : std_ulogic;                                -- shift left/right
    ymsb   : std_ulogic;                                -- shift left/right
    rd     : std_logic_vector(4 downto 0);
    jmpl   : std_ulogic;
    su     : std_ulogic;
    et     : std_ulogic;
    cwp    : cwptype;
    icc    : std_logic_vector(3 downto 0);
    mulstep: std_ulogic;            
    mul    : std_ulogic;            
    mac    : std_ulogic;
    bp     : std_ulogic;
    rfe1, rfe2 : std_ulogic;
  end record;
  
  type memory_reg_type is record
	branch : std_ulogic;
    ctrl   : pipeline_ctrl_type;
    result : word;
    y      : word;
    icc    : std_logic_vector(3 downto 0);
    nalign : std_ulogic;
    dci    : dc_in_type;
    werr   : std_ulogic;
    wcwp   : std_ulogic;
    irqen  : std_ulogic;
    irqen2 : std_ulogic;
    mac    : std_ulogic;
    divz   : std_ulogic;
    su     : std_ulogic;
    mul    : std_ulogic;
    casa   : std_ulogic;
    casaz  : std_ulogic;
	op1    : word;
    op2    : word;
  end record;
  
  type exception_state is (run, trap, dsu1, dsu2);
  
  --signal r_x_ctrl_pc : pctype; -- bilgiday
  
  type exception_reg_type is record
	branch : std_ulogic;
	branch0 : std_ulogic;
	branch1 : std_ulogic;
    ctrl   : pipeline_ctrl_type;
    pc0	   : pctype; -- bilgiday
    pc1	   : pctype; -- bilgiday
	wicc0: std_ulogic;
	wicc1: std_ulogic;
	ld0: std_ulogic;
	ld1: std_ulogic;
	pv0: std_ulogic;
	pv1: std_ulogic;
	annul0: std_ulogic;
	annul1: std_ulogic;
    result : word;
    y      : word;
    icc    : std_logic_vector( 3 downto 0);
    annul_all : std_ulogic;
    data   : dcdtype;
    set    : std_logic_vector(DSETMSB downto 0);
    mexc   : std_ulogic;
    dci    : dc_in_type;
    laddr  : std_logic_vector(1 downto 0);
    rstate : exception_state;
    npc    : std_logic_vector(2 downto 0);
    intack : std_ulogic;
    ipend  : std_ulogic;
    mac    : std_ulogic;
    debug  : std_ulogic;
    nerror : std_ulogic;
    ipmask : std_ulogic;
	op1    : word;
    op2    : word;
  end record;
  
  type dsu_registers is record
    tt      : std_logic_vector(7 downto 0);
    err     : std_ulogic;
    tbufcnt : std_logic_vector(TBUFBITS-1 downto 0);
    asi     : std_logic_vector(7 downto 0);
    crdy    : std_logic_vector(2 downto 1);  -- diag cache access ready
  end record;
  
  type irestart_register is record
    addr   : pctype;
    pwd    : std_ulogic;
  end record;
  
 
  type pwd_register_type is record
    pwd    : std_ulogic;
    error  : std_ulogic;
  end record;

  type special_register_type is record
    cwp    : cwptype;                                -- current window pointer
    cwp0    : cwptype; -- bilgiday
    cwp1    : cwptype; -- bilgiday
    icc    : std_logic_vector(3 downto 0);        -- integer condition codes
    icc0    : std_logic_vector(3 downto 0);  -- bilgiday
    icc1    : std_logic_vector(3 downto 0);  -- bilgiday
    tt     : std_logic_vector(7 downto 0);        -- trap type
    tt0     : std_logic_vector(7 downto 0);  -- bilgiday
    tt1     : std_logic_vector(7 downto 0);  -- bilgiday
    tba    : std_logic_vector(19 downto 0);       -- trap base address
    wim    : std_logic_vector(NWIN-1 downto 0);       -- window invalid mask
    pil    : std_logic_vector(3 downto 0);        -- processor interrupt level
    ec     : std_ulogic;                                  -- enable CP 
    ef     : std_ulogic;                                  -- enable FP 
    ps     : std_ulogic;                                  -- previous supervisor flag
    s      : std_ulogic;                                  -- supervisor flag
    et     : std_ulogic;                                  -- enable traps
    y      : word;
    asr18  : word;
    svt    : std_ulogic;                                  -- enable traps
    dwt    : std_ulogic;                           -- disable write error trap
    dbp    : std_ulogic;                           -- disable branch prediction
	-- PK
--	sec    : std_logic;                -- enable secure mode
  end record;
  
  type write_reg_type is record
	branch : std_ulogic;
	branch0: std_ulogic;
	branch1: std_ulogic;
	pc0     : pctype;
	pc1     : pctype;
	inst0	: std_logic_vector(2 downto 0); -- bilgiday
	inst1	: std_logic_vector(2 downto 0); -- bilgiday
    s      : special_register_type;
    result : word;
    result0 : word; -- bilgiday
    result1 : word; -- bilgiday
    wa     : rfatype;
    wa0     : rfatype; -- bilgiday
    wa1     : rfatype; -- bilgiday
    wreg   : std_ulogic;
    wreg0   : std_ulogic; -- bilgiday
    wreg1   : std_ulogic; -- bilgiday
    rdest0   : std_logic_vector(4 downto 0); -- bilgiday
    rdest1   : std_logic_vector(4 downto 0); -- bilgiday
    except : std_ulogic;
	wicc0: std_ulogic;
	wicc1: std_ulogic;
	ld0: std_ulogic;
	ld1: std_ulogic;
	pv0: std_ulogic;
	pv1: std_ulogic;
	annul0: std_ulogic;
	annul1: std_ulogic;
	et0: std_ulogic;
	et1: std_ulogic;
	rett: std_ulogic;
	-- PK: write data from insecure part to secure register file
	-- swreg  : std_ulogic;
  end record;

  type trig_reg_type is record -- bilgiday trigger support
    r0      : std_logic_vector(31 downto 0);
    r1      : std_logic_vector(31 downto 0);
    r2      : std_logic_vector(31 downto 0);
    r3      : std_logic_vector(31 downto 0);
    cnt      : std_logic_vector(31 downto 0);
  end record;

  type calibration_reg_type is record -- bilgiday calibration support
    r0      : std_logic_vector(31 downto 0);
  end record;

  type observation_reg_type is record -- bilgiday pipeline_read_support
    r0      : std_logic_vector(31 downto 0);
    r1      : std_logic_vector(31 downto 0);
    r2      : std_logic_vector(31 downto 0);
    r3      : std_logic_vector(31 downto 0);
	r4      : std_logic_vector(31 downto 0);
    r5      : std_logic_vector(31 downto 0);
    r6      : std_logic_vector(31 downto 0);
    r7      : std_logic_vector(31 downto 0);
	r8      : std_logic_vector(31 downto 0);
    r9      : std_logic_vector(31 downto 0);
    r10      : std_logic_vector(31 downto 0);
    r11      : std_logic_vector(31 downto 0);
    r12      : std_logic_vector(31 downto 0);
	r13      : std_logic_vector(31 downto 0);
    r14      : std_logic_vector(31 downto 0);
    r15      : std_logic_vector(31 downto 0);
    r16      : std_logic_vector(31 downto 0);
	r17      : std_logic_vector(31 downto 0);
    r18      : std_logic_vector(31 downto 0);
    r19      : std_logic_vector(31 downto 0);
    r20      : std_logic_vector(31 downto 0);
	r21      : std_logic_vector(31 downto 0);
    r22      : std_logic_vector(31 downto 0);
    r23      : std_logic_vector(31 downto 0);
    r24      : std_logic_vector(31 downto 0);
	r25      : std_logic_vector(31 downto 0);
    r26      : std_logic_vector(31 downto 0);
    r27      : std_logic_vector(31 downto 0);
    r28      : std_logic_vector(31 downto 0);
	r29      : std_logic_vector(31 downto 0);
    r30      : std_logic_vector(31 downto 0);
    r31      : std_logic_vector(31 downto 0);
  end record;

  type registers is record
    f  : fetch_reg_type;
    d  : decode_reg_type;
    a  : regacc_reg_type;
    e  : execute_reg_type;
    m  : memory_reg_type;
    x  : exception_reg_type;
    w  : write_reg_type;
    trigger: trig_reg_type; -- bilgiday trigger_support
  end record;

  type exception_type is record
    pri   : std_ulogic;
    ill   : std_ulogic;
    fpdis : std_ulogic;
    cpdis : std_ulogic;
    wovf  : std_ulogic;
    wunf  : std_ulogic;
    ticc  : std_ulogic;
  end record;

  type watchpoint_register is record
    addr    : std_logic_vector(31 downto 2);  -- watchpoint address
    mask    : std_logic_vector(31 downto 2);  -- watchpoint mask
    exec    : std_ulogic;                           -- trap on instruction
    load    : std_ulogic;                           -- trap on load
    store   : std_ulogic;                           -- trap on store
  end record;

  type watchpoint_registers is array (0 to 3) of watchpoint_register;

  function dbgexc(r  : registers; dbgi : l3_debug_in_type; trap : std_ulogic; tt : std_logic_vector(7 downto 0)) return std_ulogic is
    variable dmode : std_ulogic;
  begin
    dmode := '0';
    if (not r.x.ctrl.annul and trap) = '1' then
      if (((tt = "00" & TT_WATCH) and (dbgi.bwatch = '1')) or
          ((dbgi.bsoft = '1') and (tt = "10000001")) or
          (dbgi.btrapa = '1') or
          ((dbgi.btrape = '1') and not ((tt(5 downto 0) = TT_PRIV) or 
            (tt(5 downto 0) = TT_FPDIS) or (tt(5 downto 0) = TT_WINOF) or
            (tt(5 downto 0) = TT_WINUF) or (tt(5 downto 4) = "01") or (tt(7) = '1'))) or 
          (((not r.w.s.et) and dbgi.berror) = '1')) then
        dmode := '1';
      end if;
    end if;
    return(dmode);
  end;
                    
  function dbgerr(r : registers; dbgi : l3_debug_in_type;
                  tt : std_logic_vector(7 downto 0))
  return std_ulogic is
    variable err : std_ulogic;
  begin
    err := not r.w.s.et;
    if (((dbgi.dbreak = '1') and (tt = ("00" & TT_WATCH))) or
        ((dbgi.bsoft = '1') and (tt = ("10000001")))) then
      err := '0';
    end if;
    return(err);
  end;


  procedure diagwr(r    : in registers;
		   calib : in calibration_reg_type; -- bilgiday calibration support
                   dsur : in dsu_registers;
                   ir   : in irestart_register;
                   dbg  : in l3_debug_in_type;
                   wpr  : in watchpoint_registers;
                   s    : out special_register_type;
                   vwpr : out watchpoint_registers;
                   asi : out std_logic_vector(7 downto 0);
                   pc, npc  : out pctype;
                   tbufcnt : out std_logic_vector(TBUFBITS-1 downto 0);
                   wr : out std_ulogic;
                   addr : out std_logic_vector(9 downto 0);
                   data : out word;
                   trigger: out trig_reg_type; -- bilgiday trigger support
		   calibration: out calibration_reg_type; -- bilgiday calibration support
                   fpcwr : out std_ulogic) is
  variable i : integer range 0 to 3;
  begin
    s := r.w.s; pc := r.f.pc; npc := ir.addr; wr := '0';
    vwpr := wpr; asi := dsur.asi; addr := (others => '0');
    data := dbg.ddata;
    tbufcnt := dsur.tbufcnt; fpcwr := '0';
    trigger := r.trigger; -- bilgiday trigger support
    calibration := calib; -- bilgiday calibration support
      if (dbg.dsuen and dbg.denable and dbg.dwrite) = '1' then
        case dbg.daddr(23 downto 20) is
          when "0001" =>
            if (dbg.daddr(16) = '1') and TRACEBUF then -- trace buffer control reg
              tbufcnt := dbg.ddata(TBUFBITS-1 downto 0);
            end if;
          when "0011" => -- IU reg file
            if dbg.daddr(12) = '0' then
              wr := '1';
              addr := (others => '0');
              addr(RFBITS-1 downto 0) := dbg.daddr(RFBITS+1 downto 2);
            else  -- FPC
              fpcwr := '1';
            end if;
          when "0100" => -- IU special registers
            case dbg.daddr(7 downto 6) is
              when "00" => -- IU regs Y - TBUF ctrl reg
                case dbg.daddr(5 downto 2) is
                  when "0000" => -- Y
                    s.y := dbg.ddata;
                  when "0001" => -- PSR
                    s.cwp := dbg.ddata(NWINLOG2-1 downto 0);
                    s.icc := dbg.ddata(23 downto 20);
                    s.ec  := dbg.ddata(13);
                    if FPEN then s.ef := dbg.ddata(12); end if;
                    s.pil := dbg.ddata(11 downto 8);
                    s.s   := dbg.ddata(7);
                    s.ps  := dbg.ddata(6);
                    s.et  := dbg.ddata(5);
                  when "0010" => -- WIM
                    s.wim := dbg.ddata(NWIN-1 downto 0);
                  when "0011" => -- TBR
                    s.tba := dbg.ddata(31 downto 12);
                    s.tt  := dbg.ddata(11 downto 4);
                  when "0100" => -- PC
                    pc := dbg.ddata(31 downto PCLOW);
                  when "0101" => -- NPC
                    npc := dbg.ddata(31 downto PCLOW);
                  when "0110" => --FSR
                    fpcwr := '1';
                  when "0111" => --CFSR
                  when "1001" => -- ASI reg
                    asi := dbg.ddata(7 downto 0);
                  when "1010" => -- bilgiday calibration support
                    calibration.r0 := dbg.ddata(31 downto 0);
                  when others =>
                end case;
              when "01" => -- ASR16 - ASR31
                case dbg.daddr(5 downto 2) is
                when "0001" =>  -- %ASR17
                  if bp = 2 then s.dbp := dbg.ddata(27); end if;
                  s.dwt := dbg.ddata(14);
                  s.svt := dbg.ddata(13);
                when "0010" =>  -- %ASR18
                  if MACEN then s.asr18 := dbg.ddata; end if;
                when "1000" =>          -- %ASR24 - %ASR31
                  vwpr(0).addr := dbg.ddata(31 downto 2);
                  vwpr(0).exec := dbg.ddata(0); 
                when "1001" =>
                  vwpr(0).mask := dbg.ddata(31 downto 2);
                  vwpr(0).load := dbg.ddata(1);
                  vwpr(0).store := dbg.ddata(0);              
                when "1010" =>
                  vwpr(1).addr := dbg.ddata(31 downto 2);
                  vwpr(1).exec := dbg.ddata(0); 
                when "1011" =>
                  vwpr(1).mask := dbg.ddata(31 downto 2);
                  vwpr(1).load := dbg.ddata(1);
                  vwpr(1).store := dbg.ddata(0);              
                when "1100" => -- bilgiday: r.x.pc0 = ping pong buffer for return pc (ASR28)
                  vwpr(2).addr := zero32(31 downto 2);
                  vwpr(2).exec := zero32(0); 
                when "1101" => -- bilgiday: r.x.pc1 = ping pong buffer for return pc (ASR29)
                  vwpr(2).mask := zero32(31 downto 2);
                  vwpr(2).load := zero32(1);
                  vwpr(2).store := zero32(0);              
                when "1110" =>
                  vwpr(3).addr := zero32(31 downto 2);
                  vwpr(3).exec := zero32(0); 
                when "1111" => -- 
                  vwpr(3).mask := zero32(31 downto 2);
                  vwpr(3).load := zero32(1);
                  vwpr(3).store := zero32(0);              
                when others => -- 
                end case;
                when "10" => -- bilgiday trigger_support
                  case dbg.daddr(5 downto 2) is
                      when "0000" =>
                          trigger.r0 := dbg.ddata(31 downto 0);
                      when "0001" =>
                          trigger.r1 := dbg.ddata(31 downto 0);
                      when "0010" => 
                          trigger.r2 := dbg.ddata(31 downto 0);
                      when "0011" =>
                          trigger.r3 := dbg.ddata(31 downto 0);
                      when "0100" =>
                          trigger.cnt := dbg.ddata(31 downto 0);
                      when others => -- 
                  end case;
                  -- disabled due to bug in XST
                  --                  i := conv_integer(dbg.daddr(4 downto 3)); 
                  --                  if dbg.daddr(2) = '0' then
                  --                    vwpr(i).addr := dbg.ddata(31 downto 2);
                  --                    vwpr(i).exec := dbg.ddata(0); 
                  --                  else
                  --                    vwpr(i).mask := dbg.ddata(31 downto 2);
                  --                    vwpr(i).load := dbg.ddata(1);
                  --                    vwpr(i).store := dbg.ddata(0);              
                  --                  end if;                    
              when others =>
            end case;
          when others =>
        end case;
      end if;
  end;

  function asr17_gen ( r : in registers) return word is
  variable asr17 : word;
  variable fpu2 : integer range 0 to 3;  
  begin
    asr17 := zero32;
    asr17(31 downto 28) := conv_std_logic_vector(index, 4);
    if bp = 2 then asr17(27) := r.w.s.dbp; end if;
    if notag = 0 then asr17(26) := '1'; end if; -- CASA and tagged arith
    if (clk2x > 8) then
      asr17(16 downto 15) := conv_std_logic_vector(clk2x-8, 2);
      asr17(17) := '1'; 
    elsif (clk2x > 0) then
      asr17(16 downto 15) := conv_std_logic_vector(clk2x, 2);
    end if;
    asr17(14) := r.w.s.dwt;
    if svt = 1 then asr17(13) := r.w.s.svt; end if;
    if lddel = 2 then asr17(12) := '1'; end if;
    if (fpu > 0) and (fpu < 8) then fpu2 := 1;
    elsif (fpu >= 8) and (fpu < 15) then fpu2 := 3;
    elsif fpu = 15 then fpu2 := 2;
    else fpu2 := 0; end if;
    asr17(11 downto 10) := conv_std_logic_vector(fpu2, 2);                       
    if mac = 1 then asr17(9) := '1'; end if;
    if v8 /= 0 then asr17(8) := '1'; end if;
    asr17(7 downto 5) := conv_std_logic_vector(nwp, 3);                       
    asr17(4 downto 0) := conv_std_logic_vector(nwin-1, 5);       
    return(asr17);
  end;

  procedure diagread(dbgi   : in l3_debug_in_type;
                     r      : in registers;
                     obsr      : in observation_reg_type; -- bilgiday pipeline_read_support
		     calibration      : in calibration_reg_type; -- bilgiday calibration support
                     dsur   : in dsu_registers;
                     ir     : in irestart_register;
                     wpr    : in watchpoint_registers;
                     dco   : in  dcache_out_type;                          
                     tbufo  : in tracebuf_out_type;
                     data : out word) is
    variable cwp : std_logic_vector(4 downto 0);
    variable rd : std_logic_vector(4 downto 0);
    variable i : integer range 0 to 3;    
  begin
    data := (others => '0'); cwp := (others => '0');
    cwp(NWINLOG2-1 downto 0) := r.w.s.cwp;
      case dbgi.daddr(22 downto 20) is
        when "001" => -- trace buffer
          if TRACEBUF then
            if dbgi.daddr(16) = '1' then -- trace buffer control reg
              data(TBUFBITS-1 downto 0) := dsur.tbufcnt;
            else
              case dbgi.daddr(3 downto 2) is
              when "00" => data := tbufo.data(127 downto 96);
              when "01" => data := tbufo.data(95 downto 64);
              when "10" => data := tbufo.data(63 downto 32);
              when others => data := tbufo.data(31 downto 0);
              end case;
            end if;
          end if;
        when "011" => -- IU reg file
          if dbgi.daddr(12) = '0' then
            if dbgi.daddr(11) = '0' then
                data := rfo.data1(31 downto 0);
              else data := rfo.data2(31 downto 0); end if;
          else
              data := fpo.dbg.data;
          end if;
        when "100" => -- IU regs
          case dbgi.daddr(7 downto 6) is
            when "00" => -- IU regs Y - TBUF ctrl reg
              case dbgi.daddr(5 downto 2) is
                when "0000" =>
                  data := r.w.s.y;
                when "0001" =>
                  data := conv_std_logic_vector(IMPL, 4) & conv_std_logic_vector(VER, 4) &
                          r.w.s.icc & "000000" & r.w.s.ec & r.w.s.ef & r.w.s.pil &
                          r.w.s.s & r.w.s.ps & r.w.s.et & cwp;
                when "0010" =>
                  data(NWIN-1 downto 0) := r.w.s.wim;
                when "0011" =>
                  data := r.w.s.tba & r.w.s.tt & "0000";
                when "0100" =>
                  data(31 downto PCLOW) := r.f.pc;
                when "0101" =>
                  data(31 downto PCLOW) := ir.addr;
                when "0110" => -- FSR
                  data := fpo.dbg.data;
                when "0111" => -- CPSR
                when "1000" => -- TT reg
                  data(12 downto 4) := dsur.err & dsur.tt;
                when "1001" => -- ASI reg
                  data(7 downto 0) := dsur.asi;
		when "1010" => -- bilgiday calibration support
                  data := calibration.r0;
                when others =>
              end case;
            when "01" =>
              if dbgi.daddr(5) = '0' then 
                if dbgi.daddr(4 downto 2) = "001" then -- %ASR17
                  data := asr17_gen(r);
                elsif MACEN and  dbgi.daddr(4 downto 2) = "010" then -- %ASR18
                  data := r.w.s.asr18;
                end if;
              else  -- %ASR24 - %ASR31
                i := conv_integer(dbgi.daddr(4 downto 3));                                           -- 
                if dbgi.daddr(2) = '0' then
                  data(31 downto 2) := wpr(i).addr;
                  data(0) := wpr(i).exec;
                else
                  data(31 downto 2) := wpr(i).mask;
                  data(1) := wpr(i).load;
                  data(0) := wpr(i).store; 
                end if;
              end if;
              -- bilgiday trigger support
              when "10" => -- 
                case dbgi.daddr(5 downto 2) is
                  when "0000" =>
                      data := r.trigger.r0;
                  when "0001" =>
                      data := r.trigger.r1;
                  when "0010" =>
                      data := r.trigger.r2;
                  when "0011" =>
                      data := r.trigger.r3;
                  when "0100" =>
                      data := r.trigger.cnt;
                  when "0101" => -- bilgiday pipeline_read_support
                      data := obsr.r0;
                  when "0110" => -- bilgiday pipeline_read_support
                      data := obsr.r1;
                  when "0111" => -- bilgiday pipeline_read_support
                      data := obsr.r2;
                  when "1000" => -- bilgiday pipeline_read_support
                      data := obsr.r3;
                  when "1001" => -- bilgiday pipeline_read_support
                      data := obsr.r4;  
                  when "1010" => -- bilgiday pipeline_read_support
                      data := obsr.r5;	  
                  when "1011" => -- bilgiday pipeline_read_support
                      data := obsr.r6;
                  when "1100" => -- bilgiday pipeline_read_support
                      data := obsr.r7;
                  when "1101" => -- bilgiday pipeline_read_support
                      data := obsr.r8;
                  when "1110" => -- bilgiday pipeline_read_support
                      data := obsr.r9;
                  when "1111" => -- bilgiday pipeline_read_support
                      data := obsr.r10;
                       when others =>
                 end case;
                 when "11" => -- bilgiday pipeline_read_support
                 case dbgi.daddr(5 downto 2) is
                     when "0000" => -- bilgiday pipeline_read_support
                         data := obsr.r11;
                     when "0001" => -- bilgiday pipeline_read_support
                         data := obsr.r12;
                     when "0010" => -- bilgiday pipeline_read_support
                         data := obsr.r13;
                     when "0011" => -- bilgiday pipeline_read_support
                         data := obsr.r14;
                     when "0100" => -- bilgiday pipeline_read_support
                         data := obsr.r15;
                     when "0101" => -- bilgiday pipeline_read_support
                         data := obsr.r16;
                     when "0110" => -- bilgiday pipeline_read_support
                         data := obsr.r17;
                     when "0111" => -- bilgiday pipeline_read_support
                         data := obsr.r18;
                     when "1000" => -- bilgiday pipeline_read_support
                         data := obsr.r19;
                     when "1001" => -- bilgiday pipeline_read_support
                         data := obsr.r20;
                     when "1010" => -- bilgiday pipeline_read_support
                         data := obsr.r21;
                     when "1011" => -- bilgiday pipeline_read_support
                         data := obsr.r22;
                     when "1100" => -- bilgiday pipeline_read_support
                         data := obsr.r23;
                     when "1101" => -- bilgiday pipeline_read_support
                         data := obsr.r24;
                     when "1110" => -- bilgiday pipeline_read_support
                         data := obsr.r25;
                     when "1111" => -- bilgiday pipeline_read_support
                         data := obsr.r26;
                            when others =>
                            end case;
			 when others => 
          end case;
        when "111" =>
          data := r.x.data(conv_integer(r.x.set));
        when others =>
      end case;
  end;
  

  procedure itrace(r    : in registers;
                   dsur : in dsu_registers;
                   vdsu : in dsu_registers;
                   res  : in word;
                   exc  : in std_ulogic;
                   dbgi : in l3_debug_in_type;
                   error : in std_ulogic;
                   trap  : in std_ulogic;                          
                   tbufcnt : out std_logic_vector(TBUFBITS-1 downto 0); 
                   di  : out tracebuf_in_type;
                   ierr : in std_ulogic;
                   derr : in std_ulogic
                   ) is
  variable meminst : std_ulogic;
  begin
    di.addr := (others => '0'); di.data := (others => '0');
    di.enable := '0'; di.write := (others => '0');
    tbufcnt := vdsu.tbufcnt;
    meminst := r.x.ctrl.inst(31) and r.x.ctrl.inst(30);
    if TRACEBUF then
      di.addr(TBUFBITS-1 downto 0) := dsur.tbufcnt;
      di.data(127) := '0';
      di.data(126) := not r.x.ctrl.pv;
      di.data(125 downto 96) := dbgi.timer(29 downto 0);
      di.data(95 downto 64) := res;
      di.data(63 downto 34) := r.x.ctrl.pc(31 downto 2);
      di.data(33) := trap;
      di.data(32) := error;
      di.data(31 downto 0) := r.x.ctrl.inst;
      if (dbgi.tenable = '0') or (r.x.rstate = dsu2) then
        if ((dbgi.dsuen and dbgi.denable) = '1') and (dbgi.daddr(23 downto 20) & dbgi.daddr(16) = "00010") then
          di.enable := '1'; 
          di.addr(TBUFBITS-1 downto 0) := dbgi.daddr(TBUFBITS-1+4 downto 4);
          if dbgi.dwrite = '1' then            
            case dbgi.daddr(3 downto 2) is
              when "00" => di.write(3) := '1';
              when "01" => di.write(2) := '1';
              when "10" => di.write(1) := '1';
              when others => di.write(0) := '1';
            end case;
            di.data := dbgi.ddata & dbgi.ddata & dbgi.ddata & dbgi.ddata;
          end if;
        end if;
      elsif (not r.x.ctrl.annul and (r.x.ctrl.pv or meminst) and not r.x.debug) = '1' then
        di.enable := '1'; di.write := (others => '1');
        tbufcnt := dsur.tbufcnt + 1;
      end if;      
      di.diag := dco.testen &  dco.scanen & "00";
      if dco.scanen = '1' then di.enable := '0'; end if;
    end if;
  end;

  procedure dbg_cache(holdn    : in std_ulogic;
                      dbgi     :  in l3_debug_in_type;
                      r        : in registers;
                      dsur     : in dsu_registers;
                      mresult  : in word;
                      dci      : in dc_in_type;
                      mresult2 : out word;
                      dci2     : out dc_in_type
                      ) is
  begin
    mresult2 := mresult; dci2 := dci; dci2.dsuen := '0'; 
    if DBGUNIT then
      if (r.x.rstate = dsu2)
      then
        dci2.asi := dsur.asi;
        if (dbgi.daddr(22 downto 20) = "111") and (dbgi.dsuen = '1') then
          dci2.dsuen := (dbgi.denable or r.m.dci.dsuen) and not dsur.crdy(2);
          dci2.enaddr := dbgi.denable;
          dci2.size := "10"; dci2.read := '1'; dci2.write := '0';
          if (dbgi.denable and not r.m.dci.enaddr) = '1' then            
            mresult2 := (others => '0'); mresult2(19 downto 2) := dbgi.daddr(19 downto 2);
          else
            mresult2 := dbgi.ddata;            
          end if;
          if dbgi.dwrite = '1' then
            dci2.read := '0'; dci2.write := '1';
          end if;
        end if;
      end if;
    end if;
  end;
    
  procedure fpexack(r : in registers; fpexc : out std_ulogic) is
  begin
    fpexc := '0';
    if FPEN then 
      if r.x.ctrl.tt = TT_FPEXC then fpexc := '1'; end if;
    end if;
  end;

  procedure diagrdy(denable : in std_ulogic;
                    dsur : in dsu_registers;
                    dci   : in dc_in_type;
                    mds : in std_ulogic;
                    ico : in icache_out_type;
                    crdy : out std_logic_vector(2 downto 1)) is                   
  begin
    crdy := dsur.crdy(1) & '0';    
    if dci.dsuen = '1' then
      case dsur.asi(4 downto 0) is
        when ASI_ITAG | ASI_IDATA | ASI_UINST | ASI_SINST =>
          crdy(2) := ico.diagrdy and not dsur.crdy(2);
        when ASI_DTAG | ASI_MMUSNOOP_DTAG | ASI_DDATA | ASI_UDATA | ASI_SDATA =>
          crdy(1) := not denable and dci.enaddr and not dsur.crdy(1);
        when others =>
          crdy(2) := dci.enaddr and denable;
      end case;
    end if;
  end;


  constant RESET_ALL : boolean := GRLIB_CONFIG_ARRAY(grlib_sync_reset_enable_all) = 1;
  constant dc_in_res : dc_in_type := (
    signed => '0',
    enaddr => '0',
    read   => '0',
    write  => '0',
    lock   => '0',
    dsuen  => '0',
    size   => (others => '0'),
    asi    => (others => '0'));
  constant pipeline_ctrl_res :  pipeline_ctrl_type := (
    pc    => (others => '0'),
    inst  => (others => '0'),
    cnt   => (others => '0'),
    rd    => (others => '0'),
    tt    => (others => '0'),
    trap  => '0',
    annul => '1',
    wreg  => '0',
    wicc  => '0',
    wy    => '0',
    ld    => '0',
    pv    => '0',
    rett  => '0');
  constant fpc_res : pctype := conv_std_logic_vector(rstaddr, 20) & zero32(11 downto PCLOW);
  
  constant calibration_reg_res: calibration_reg_type := ( -- bilgiday calibration support
    r0 	=> (others => '0')
  );  

  constant obs_reg_res: observation_reg_type := ( -- bilgiday pipeline_read_support
    r0 	=> (others => '0'),
    r1 	=> (others => '0'),
    r2 	=> (others => '0'),
    r3 	=> (others => '0'),
    r4 	=> (others => '0'),
    r5 	=> (others => '0'),
    r6 	=> (others => '0'),
    r7 	=> (others => '0'),
    r8 	=> (others => '0'),
    r9 	=> (others => '0'),
    r10	=> (others => '0'),
    r11	=> (others => '0'),
    r12	=> (others => '0'),
    r13	=> (others => '0'),
    r14	=> (others => '0'),
    r15	=> (others => '0'),
    r16	=> (others => '0'),
    r17	=> (others => '0'),
    r18	=> (others => '0'),
    r19	=> (others => '0'),
    r20	=> (others => '0'),
    r21	=> (others => '0'),
    r22	=> (others => '0'),
    r23	=> (others => '0'),
    r24	=> (others => '0'),
    r25	=> (others => '0'),
    r26	=> (others => '0'),
    r27	=> (others => '0'),
    r28	=> (others => '0'),
    r29	=> (others => '0'),
    r30	=> (others => '0'),
    r31	=> (others => '0')
  );
  
  constant trig_reg_res : trig_reg_type := ( -- bilgiday trigger support
  r0     => (others => '0'),
  r1     => (others => '0'),
  r2     => (others => '0'),
  r3     => (others => '0'),
  cnt     => (others => '0')
          );
  constant fetch_reg_res : fetch_reg_type := (
    pc     => fpc_res,  -- Needs special handling
    branch => '0'
    );
  constant decode_reg_res : decode_reg_type := (
    pc     => (others => '0'),
    inst   => (others => (others => '0')),
    cwp    => (others => '0'),
    set    => (others => '0'),
    mexc   => '0',
    cnt    => (others => '0'),
    pv     => '0',
    annul  => '1',
    inull  => '0',
    step   => '0',
    divrdy => '0'
    );
  constant regacc_reg_res : regacc_reg_type := (
	branch      => '0',
    ctrl     => pipeline_ctrl_res,
    rs1      => (others => '0'),
    rfa1     => (others => '0'),
    rfa2     => (others => '0'),
    rsel1    => (others => '0'),
    rsel2    => (others => '0'),
    rfe1     => '0',
    rfe2     => '0',
    cwp      => (others => '0'),
    imm      => (others => '0'),
    ldcheck1 => '0',
    ldcheck2 => '0',
    ldchkra  => '1',
    ldchkex  => '1',
    su       => '1',
    et       => '0',
    wovf     => '0',
    wunf     => '0',
    ticc     => '0',
    jmpl     => '0',
    step     => '0',
    mulstart => '0',
    divstart => '0',
    bp       => '0',
    nobp     => '0'
);
  constant execute_reg_res : execute_reg_type := (
  branch      => '0',
  ctrl    =>  pipeline_ctrl_res,
  op1     => (others => '0'),
  op2     => (others => '0'),
  aluop   => (others => '0'),
  alusel  => "11",
  aluadd  => '1',
  alucin  => '0',
  ldbp1   => '0',
  ldbp2   => '0',
  invop2  => '0',
  shcnt   => (others => '0'),
  sari    => '0',
  shleft  => '0',
  ymsb    => '0',
  rd      => (others => '0'),
  jmpl    => '0',
  su      => '0',
  et      => '0',
  cwp     => (others => '0'),
  icc     => (others => '0'),
  mulstep => '0',
  mul     => '0',
  mac     => '0',
  bp      => '0',
  rfe1    => '0',
  rfe2    => '0'
  );
  constant memory_reg_res : memory_reg_type := (
  branch      => '0',
  ctrl   => pipeline_ctrl_res,
  result => (others => '0'),
  y      => (others => '0'),
  icc    => (others => '0'),
  nalign => '0',
  dci    => dc_in_res,
  werr   => '0',
  wcwp   => '0',
  irqen  => '0',
  irqen2 => '0',
  mac    => '0',
  divz   => '0',
  su     => '0',
  mul    => '0',
  casa   => '0',
  casaz  => '0',
  op1    => (others => '0'),
  op2    => (others => '0')
  );
  function xnpc_res return std_logic_vector is
  begin
  if v8 /= 0 then return "100"; end if;
  return "011";
  end function xnpc_res;
  constant exception_reg_res : exception_reg_type := (
  branch      => '0',
  branch0      => '0',
  branch1      => '0',
  ctrl      => pipeline_ctrl_res,
  pc0    => (others => '0'), -- bilgiday
  pc1    => (others => '0'), -- bilgiday
  wicc0 => '0',-- bilgiday
  wicc1 => '0',-- bilgiday
  ld0 => '0',  -- bilgiday
  ld1 => '0',  -- bilgiday
  pv0 => '0',  -- bilgiday
  pv1 => '0',  -- bilgiday
  annul0 => '0', --bilgiday
  annul1 => '0', --bilgiday
  result    => (others => '0'),
  y         => (others => '0'),
  icc       => (others => '0'),
  annul_all => '1',
  data      => (others => (others => '0')),
  set       => (others => '0'),
  mexc      => '0',
  dci       => dc_in_res,
  laddr     => (others => '0'),
  rstate    => run,                   -- Has special handling
  npc       => xnpc_res,
  intack    => '0',
  ipend     => '0',
  mac       => '0',
  debug     => '0',                   -- Has special handling
  nerror    => '0',
  ipmask    => '0',
  op1    => (others => '0'),
  op2    => (others => '0')
  );
  constant DRES : dsu_registers := (
  tt      => (others => '0'),
  err     => '0',
  tbufcnt => (others => '0'),
  asi     => (others => '0'),
  crdy    => (others => '0')
  );
  constant IRES : irestart_register := (
  addr => (others => '0'), pwd => '0'
  );
  constant PRES : pwd_register_type := (
  pwd => '0',                         -- Needs special handling
  error => '0'
  );
  --constant special_register_res : special_register_type := (
  --  cwp    => zero32(NWINLOG2-1 downto 0),
  --  icc    => (others => '0'),
  --  tt     => (others => '0'),
  --  tba    => fpc_res(31 downto 12),
  --  wim    => (others => '0'),
  --  pil    => (others => '0'),
  --  ec     => '0',
  --  ef     => '0',
  --  ps     => '1',
  --  s      => '1',
  --  et     => '0',
  --  y      => (others => '0'),
  --  asr18  => (others => '0'),
  --  svt    => '0',
  --  dwt    => '0',
  --  dbp    => '0'
  --  );
  --XST workaround:
  function special_register_res return special_register_type is
  variable s : special_register_type;
  begin
  s.cwp   := zero32(NWINLOG2-1 downto 0);
  s.cwp0   := zero32(NWINLOG2-1 downto 0); -- bilgiday
  s.cwp1   := zero32(NWINLOG2-1 downto 0); -- bilgiday
  s.icc   := (others => '0');
  s.icc0   := (others => '0'); -- bilgiday
  s.icc1   := (others => '0'); -- bilgiday
  s.tt    := (others => '0');
  s.tt0    := (others => '0'); -- bilgiday
  s.tt1    := (others => '0'); -- bilgiday
  --s.tba   := fpc_res(31 downto 12);
  s.tba   := x"40000"; -- chinmay
  s.wim   := (others => '0');
  s.pil   := (others => '0');
  s.ec    := '0';
  s.ef    := '0';
  s.ps    := '1';
  s.s     := '1';
  s.et    := '0';
  s.y     := (others => '0');
  s.asr18 := (others => '0');
  s.svt   := '0';
  s.dwt   := '0';
  s.dbp   := '0';
  return s;
  end function special_register_res;
  --constant write_reg_res : write_reg_type := (
  --  s      => special_register_res,
  --  result => (others => '0'),
  --  wa     => (others => '0'),
  --  wreg   => '0',
  --  except => '0'
  --  );
  -- XST workaround:
  function write_reg_res return write_reg_type is
  variable w : write_reg_type;
  begin
  w.branch := '0';
  w.branch0 := '0';
  w.branch1 := '0';
  w.pc0 := (others => '0');
  w.pc1 := (others => '0');
  w.inst1 := (others => '0');
  w.inst0 := (others => '0');
  w.s      := special_register_res;
  w.result := (others => '0');
  w.result0 := (others => '0'); -- bilgiday
  w.result1 := (others => '0'); -- bilgiday
  w.wa     := (others => '0');
  w.wa0     := (others => '0'); -- bilgiday
  w.wa1     := (others => '0'); -- bilgiday
  w.wreg   := '0';
  w.wreg0   := '0'; -- bilgiday
  w.wreg1   := '0'; -- bilgiday
  w.rdest0 := (others => '0'); -- bilgiday
  w.rdest1 := (others => '0'); -- bilgiday
  w.except := '0';
  w.wicc0 := '0';-- bilgiday
  w.wicc1 := '0';-- bilgiday
  w.ld0 := '0';  -- bilgiday
  w.ld1 := '0';  -- bilgiday
  w.pv0 := '0';  -- bilgiday
  w.pv1 := '0';  -- bilgiday
  w.annul0 := '0'; --bilgiday
  w.annul1 := '0'; --bilgiday
  w.et0 := '0';    --bilgiday
  w.et1 := '0';    --bilgiday
  w.rett := '0';    --bilgiday
  return w;
  end function write_reg_res;
  constant RRES : registers := (
  f => fetch_reg_res,
  d => decode_reg_res,
  a => regacc_reg_res,
  e => execute_reg_res,
  m => memory_reg_res,
  x => exception_reg_res,
  w => write_reg_res,
  trigger => trig_reg_res -- bilgiday trigger support
  );
  constant exception_res : exception_type := (
  pri   => '0',
  ill   => '0',
  fpdis => '0',
  cpdis => '0',
  wovf  => '0',
  wunf  => '0',
  ticc  => '0'
  );
  constant wpr_none : watchpoint_register := (
  addr  => zero32(31 downto 2),
  mask  => zero32(31 downto 2),
  exec  => '0',
  load  => '0',
  store => '0');
  
  signal chip_boundary_reg : std_logic_vector (56 downto 0);
  signal r, rin : registers;
  signal obsr, obsrin : observation_reg_type; -- bilgiday pipeline_read_support
  signal calibr, calibrin : calibration_reg_type; -- bilgiday calibration support
  signal wpr, wprin : watchpoint_registers;
  signal dsur, dsuin : dsu_registers;
  signal ir, irin : irestart_register;
  signal rp, rpin : pwd_register_type;
  
  --signal extsave : std_ulogic; -- bilgiday pipeline_read_support
  signal alarm : std_ulogic; -- bilgiday
  signal cnten : std_ulogic; -- bilgiday
  signal bufcnt : std_ulogic; -- bilgiday
  signal invalid_bufcnt_x : std_ulogic; -- bilgiday
  signal invalid_bufcnt_w : std_ulogic; -- bilgiday
  signal osel : std_ulogic; -- bilgiday
  signal alarmc, alarmin1, alarmin2, alarmin3, alarm_reg : std_ulogic; -- bilgiday
  signal alarm_sensors, alarm_emsensor, alarm_aesenc, alarm_aesdec : std_ulogic; -- bilgiday

-- execute stage operations
	-- logicout: -- Pantea changed width 2->3
  constant EXE_AND   : std_logic_vector(3 downto 0) := "0000";
  constant EXE_XOR   : std_logic_vector(3 downto 0) := "0001"; -- must be equal to EXE_PASS2
  constant EXE_OR    : std_logic_vector(3 downto 0) := "0010";
  constant EXE_XNOR  : std_logic_vector(3 downto 0) := "0011";
  constant EXE_ANDN  : std_logic_vector(3 downto 0) := "0100";
  constant EXE_ORN   : std_logic_vector(3 downto 0) := "0101";
  constant EXE_DIV   : std_logic_vector(3 downto 0) := "0110";
  constant EXE_SUBROT : std_logic_vector(3 downto 0) := "0111"; -- pk

    -- miscout: -- Pantea changed width 2->3
  constant EXE_PASS1 : std_logic_vector(3 downto 0) := "0000";
  constant EXE_PASS2 : std_logic_vector(3 downto 0) := "0001";
  constant EXE_STB   : std_logic_vector(3 downto 0) := "0010";
  constant EXE_STH   : std_logic_vector(3 downto 0) := "0011";
  constant EXE_ONES  : std_logic_vector(3 downto 0) := "0100";
  constant EXE_RDY   : std_logic_vector(3 downto 0) := "0101";
  constant EXE_SPR   : std_logic_vector(3 downto 0) := "0110";
  constant EXE_LINK  : std_logic_vector(3 downto 0) := "0111";

    -- shiftout -- Pantea changed width 2->3
  constant EXE_SLL   : std_logic_vector(3 downto 0) := "0001";
  constant EXE_SRL   : std_logic_vector(3 downto 0) := "0010";
  constant EXE_SRA   : std_logic_vector(3 downto 0) := "0100";
  
  constant EXE_TR2   : std_logic_vector(3 downto 0) := "0011"; -- pk
  constant EXE_INVTR2   : std_logic_vector(3 downto 0) := "0101"; -- pk
  
  constant EXE_NOP   : std_logic_vector(3 downto 0) := "0000";
 
  constant EXE_RED   : std_logic_vector(3 downto 0) := "1000"; -- pk
  constant EXE_FTCHK : std_logic_vector(3 downto 0) := "1001"; -- pk
  constant EXE_ANDC8 : std_logic_vector(3 downto 0) := "1010"; -- pk
  constant EXE_ANDC16 : std_logic_vector(3 downto 0) := "1011"; -- pk
  constant EXE_XORC8 : std_logic_vector(3 downto 0) := "1100"; -- pk
  constant EXE_XORC16 : std_logic_vector(3 downto 0) := "1101"; -- pk
  constant EXE_XNORC8 : std_logic_vector(3 downto 0) := "1110"; -- pk
  constant EXE_XNORC16 : std_logic_vector(3 downto 0) := "1111"; -- pk
-- EXE result select

  constant EXE_RES_ADD   : std_logic_vector(1 downto 0) := "00";
  constant EXE_RES_SHIFT : std_logic_vector(1 downto 0) := "01";
  constant EXE_RES_LOGIC : std_logic_vector(1 downto 0) := "10";
  constant EXE_RES_MISC  : std_logic_vector(1 downto 0) := "11";

-- Load types

  constant SZBYTE    : std_logic_vector(1 downto 0) := "00";
  constant SZHALF    : std_logic_vector(1 downto 0) := "01";
  constant SZWORD    : std_logic_vector(1 downto 0) := "10";
  constant SZDBL     : std_logic_vector(1 downto 0) := "11";

-- calculate register file address

  procedure regaddr(cwp : std_logic_vector; reg : std_logic_vector(4 downto 0);
         rao : out rfatype) is
  variable ra : rfatype;
  constant globals : std_logic_vector(RFBITS-5  downto 0) := 
        conv_std_logic_vector(NWIN, RFBITS-4);
  begin
    ra := (others => '0'); ra(4 downto 0) := reg;
    if reg(4 downto 3) = "00" then ra(RFBITS -1 downto 4) := globals;
    else
      ra(NWINLOG2+3 downto 4) := cwp + ra(4);
      if ra(RFBITS-1 downto 4) = globals then
        ra(RFBITS-1 downto 4) := (others => '0');
      end if;
    end if;
    rao := ra;
  end;

-- branch adder

  function branch_address(inst : word; pc : pctype) return std_logic_vector is
  variable baddr, caddr, tmp : pctype;
  begin
    caddr := (others => '0'); caddr(31 downto 2) := inst(29 downto 0);
    caddr(31 downto 2) := caddr(31 downto 2) + pc(31 downto 2);
    baddr := (others => '0'); baddr(31 downto 24) := (others => inst(21)); 
    baddr(23 downto 2) := inst(21 downto 0);
    baddr(31 downto 2) := baddr(31 downto 2) + pc(31 downto 2);
    if inst(30) = '1' then tmp := caddr; else tmp := baddr; end if;
    return(tmp);
  end;

-- evaluate branch condition

  function branch_true(icc : std_logic_vector(3 downto 0); inst : word) 
        return std_ulogic is
  variable n, z, v, c, branch : std_ulogic;
  begin
    n := icc(3); z := icc(2); v := icc(1); c := icc(0);
    case inst(27 downto 25) is
    when "000" =>  branch := inst(28) xor '0';                  -- bn, ba
    when "001" =>  branch := inst(28) xor z;                    -- be, bne
    when "010" =>  branch := inst(28) xor (z or (n xor v));     -- ble, bg
    when "011" =>  branch := inst(28) xor (n xor v);            -- bl, bge
    when "100" =>  branch := inst(28) xor (c or z);             -- bleu, bgu
    when "101" =>  branch := inst(28) xor c;                    -- bcs, bcc 
    when "110" =>  branch := inst(28) xor n;                    -- bneg, bpos
    when others => branch := inst(28) xor v;                    -- bvs, bvc   
    end case;
    return(branch);
  end;

-- detect RETT instruction in the pipeline and set the local psr.su and psr.et

  procedure su_et_select(r : in registers; xc_ps, xc_s, xc_et : in std_ulogic;
                       su, et : out std_ulogic) is
  begin
   if ((r.a.ctrl.rett or r.e.ctrl.rett or r.m.ctrl.rett or r.x.ctrl.rett) = '1')
     and (r.x.annul_all = '0')
   then su := xc_ps; et := '1';
   else su := xc_s; et := xc_et; end if;
  end;

-- detect watchpoint trap

  function wphit(r : registers; wpr : watchpoint_registers; debug : l3_debug_in_type)
    return std_ulogic is
  variable exc : std_ulogic;
  begin
    exc := '0';
    for i in 1 to NWP loop
      if ((wpr(i-1).exec and r.a.ctrl.pv and not r.a.ctrl.annul) = '1') then
         if (((wpr(i-1).addr xor r.a.ctrl.pc(31 downto 2)) and wpr(i-1).mask) = Zero32(31 downto 2)) then
           exc := '1';
         end if;
      end if;
    end loop;

   if DBGUNIT then
     if (debug.dsuen and not r.a.ctrl.annul) = '1' then
       exc := exc or (r.a.ctrl.pv and ((debug.dbreak and debug.bwatch) or r.a.step));
     end if;
   end if;
    return(exc);
  end;

-- 32-bit shifter

  function shift3(r : registers; aluin1, aluin2 : word) return word is
  variable shiftin : unsigned(63 downto 0);
  variable shiftout : unsigned(63 downto 0);
  variable cnt : natural range 0 to 31;
  begin

    cnt := conv_integer(r.e.shcnt);
    if r.e.shleft = '1' then
      shiftin(30 downto 0) := (others => '0');
      shiftin(63 downto 31) := '0' & unsigned(aluin1);
    else
      shiftin(63 downto 32) := (others => r.e.sari);
      shiftin(31 downto 0) := unsigned(aluin1);
    end if;
    shiftout := SHIFT_RIGHT(shiftin, cnt);
    return(std_logic_vector(shiftout(31 downto 0)));
     
  end;

  function shift2(r : registers; aluin1, aluin2 : word) return word is
  variable ushiftin : unsigned(31 downto 0);
  variable sshiftin : signed(32 downto 0);
  variable cnt : natural range 0 to 31;
  variable resleft, resright : word;
  begin

    cnt := conv_integer(r.e.shcnt);
    ushiftin := unsigned(aluin1);
    sshiftin := signed('0' & aluin1);
    if r.e.shleft = '1' then
      resleft := std_logic_vector(SHIFT_LEFT(ushiftin, cnt));
      return(resleft);
    else
      if r.e.sari = '1' then sshiftin(32) := aluin1(31); end if;
      sshiftin := SHIFT_RIGHT(sshiftin, cnt);
      resright := std_logic_vector(sshiftin(31 downto 0));
      return(resright);
    end if;
     
  end;

  function shift(r : registers; aluin1, aluin2 : word;
                 shiftcnt : std_logic_vector(4 downto 0); sari : std_ulogic ) return word is
  variable shiftin : std_logic_vector(63 downto 0);
  begin
    shiftin := zero32 & aluin1;
    if r.e.shleft = '1' then
      shiftin(31 downto 0) := zero32; shiftin(63 downto 31) := '0' & aluin1;
    else shiftin(63 downto 32) := (others => sari); end if;
    if shiftcnt (4) = '1' then shiftin(47 downto 0) := shiftin(63 downto 16); end if;
    if shiftcnt (3) = '1' then shiftin(39 downto 0) := shiftin(47 downto 8); end if;
    if shiftcnt (2) = '1' then shiftin(35 downto 0) := shiftin(39 downto 4); end if;
    if shiftcnt (1) = '1' then shiftin(33 downto 0) := shiftin(35 downto 2); end if;
    if shiftcnt (0) = '1' then shiftin(31 downto 0) := shiftin(32 downto 1); end if;
    return(shiftin(31 downto 0));
  end;

-- Check for illegal and privileged instructions

  procedure exception_detect(r : registers; wpr : watchpoint_registers; dbgi : l3_debug_in_type;
          trapin : in std_ulogic; ttin : in std_logic_vector(5 downto 0); 
          trap : out std_ulogic; tt : out std_logic_vector(5 downto 0)) is
    variable illegal_inst, privileged_inst : std_ulogic;
    variable cp_disabled, fp_disabled, fpop : std_ulogic;
    variable op : std_logic_vector(1 downto 0);
    variable op2 : std_logic_vector(2 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable rd  : std_logic_vector(4 downto 0);
    variable inst : word;
    variable wph : std_ulogic;
  begin
    inst := r.a.ctrl.inst; trap := trapin; tt := ttin;
    if r.a.ctrl.annul = '0' then
      op  := inst(31 downto 30); op2 := inst(24 downto 22);
      op3 := inst(24 downto 19); rd  := inst(29 downto 25);
      illegal_inst := '0'; privileged_inst := '0'; cp_disabled := '0'; 
      fp_disabled := '0'; fpop := '0'; 
      case op is
      when CALL => null;
      when FMT2 =>
        case op2 is
        when SETHI | BICC => null;
        when FBFCC => 
          if FPEN then fp_disabled := not r.w.s.ef; else fp_disabled := '1'; end if;
        when CBCCC =>
          if (not CPEN) or (r.w.s.ec = '0') then cp_disabled := '1'; end if;
        when others => illegal_inst := '1';
        end case;
      when FMT3 =>
        case op3 is
        when IAND | ANDCC | ANDN | ANDNCC | IOR | ORCC | ORN | ORNCC | IXOR |
          XORCC | IXNOR | XNORCC | ISLL | ISRL | ISRA | MULSCC | IADD | ADDX |
          ADDCC | ADDXCC | ISUB | SUBX | SUBCC | SUBXCC | FLUSH | JMPL | TICC | 
          SAVE | RESTORE | RDY => null;
        when TADDCC | TADDCCTV | TSUBCC | TSUBCCTV => 
          if notag = 1 then illegal_inst := '1'; end if;
        when UMAC | SMAC => 
          if not MACEN then illegal_inst := '1'; end if;
        when UMUL | SMUL | UMULCC | SMULCC => 
          if not MULEN then illegal_inst := '1'; end if;
        when UDIV | SDIV | UDIVCC | SDIVCC => 
          if not DIVEN then illegal_inst := '1'; end if;
        when RETT => illegal_inst := r.a.et; privileged_inst := not r.a.su;
        when RDPSR | RDTBR | RDWIM => privileged_inst := not r.a.su;
        when WRY =>
          if rd(4) = '1' and rd(3 downto 0) /= "0010" then -- %ASR16-17, %ASR19-31
            privileged_inst := not r.a.su;
          end if;
  	   
      when SUBROT => null;  
      when TR2 => null;  
      when INVTR2 => null;  
      when RED => null;  
      when FTCHK => null;  
  	  -----------------------------
        when WRPSR => 
          privileged_inst := not r.a.su; 
        when WRWIM | WRTBR  => privileged_inst := not r.a.su;
        when FPOP1 | FPOP2 => 
          if FPEN then fp_disabled := not r.w.s.ef; fpop := '1';
          else fp_disabled := '1'; fpop := '0'; end if;
        when CPOP1 | CPOP2 =>
          if (not CPEN) or (r.w.s.ec = '0') then cp_disabled := '1'; end if;
        when others => illegal_inst := '1';
        end case;
      when others =>      -- LDST
        case op3 is
        when LDD | ISTD => illegal_inst := rd(0); -- trap if odd destination register
        when LD | LDUB | LDSTUB | LDUH | LDSB | LDSH | ST | STB | STH | SWAP =>
          null;
        when LDDA | STDA =>
          illegal_inst := inst(13) or rd(0); privileged_inst := not r.a.su;
        when LDA | LDUBA| LDSTUBA | LDUHA | LDSBA | LDSHA | STA | STBA | STHA |
             SWAPA =>
          illegal_inst := inst(13); privileged_inst := not r.a.su;
        when CASA =>
          if CASAEN then
            illegal_inst := inst(13);
            if (inst(12 downto 5) /= X"0A") then privileged_inst := not r.a.su; end if;
          else illegal_inst := '1'; end if;
        when LDDF | STDF | LDF | LDFSR | STF | STFSR =>
          if FPEN then fp_disabled := not r.w.s.ef;
          else fp_disabled := '1'; end if;
        when STDFQ =>
          privileged_inst := not r.a.su;
          if (not FPEN) or (r.w.s.ef = '0') then fp_disabled := '1'; end if;
        when STDCQ =>
          privileged_inst := not r.a.su;
          if (not CPEN) or (r.w.s.ec = '0') then cp_disabled := '1'; end if;
        when LDC | LDCSR | LDDC | STC | STCSR | STDC =>
          if (not CPEN) or (r.w.s.ec = '0') then cp_disabled := '1'; end if;
	when ANDC8 => null; 
	when ANDC16 => null; 
	when XORC8 => null; 
	when XORC16 => null; 
	when XNORC8 => null; 
	when XNORC16 => null; 
        when others => illegal_inst := '1';
        end case;
      end case;
     
       wph := wphit(r, wpr, dbgi);
      
      trap := '1';
      if r.a.ctrl.trap = '1' then tt := r.a.ctrl.tt;
      elsif privileged_inst = '1' then tt := TT_PRIV; 
      elsif illegal_inst = '1' then tt := TT_IINST;
      elsif fp_disabled = '1' then tt := TT_FPDIS;
      elsif cp_disabled = '1' then tt := TT_CPDIS;
      elsif wph = '1' then tt := TT_WATCH;
      elsif r.a.wovf= '1' then tt := TT_WINOF;
      elsif r.a.wunf= '1' then tt := TT_WINUF;
      elsif r.a.ticc= '1' then tt := TT_TICC;
      else trap := '0'; tt:= (others => '0'); end if;
    end if;
  end;
  
  -- instructions that write the condition codes (psr.icc)
  
  procedure wicc_y_gen(inst : word; wicc, wy : out std_ulogic) is
  begin
  wicc := '0'; wy := '0';
  if inst(31 downto 30) = FMT3 then
    case inst(24 downto 19) is
    when SUBCC | TSUBCC | TSUBCCTV | ADDCC | ANDCC | ORCC | XORCC | ANDNCC |
         ORNCC | XNORCC | TADDCC | TADDCCTV | ADDXCC | SUBXCC | WRPSR => 
      wicc := '1';
    when WRY =>
      if r.d.inst(conv_integer(r.d.set))(29 downto 25) = "00000" then wy := '1'; 
      elsif r.d.inst(conv_integer(r.d.set))(29 downto 26) = "1011" then wicc := '1'; -- bilgiday asr22-icc and asr23-icc
      end if;
    when MULSCC =>
      wicc := '1'; wy := '1';
    when  UMAC | SMAC  =>
      if MACEN then wy := '1'; end if;
    when UMULCC | SMULCC => 
      if MULEN and (((mulo.nready = '1') and (r.d.cnt /= "00")) or (MULTYPE /= 0)) then
        wicc := '1'; wy := '1';
      end if;
    when UMUL | SMUL => 
      if MULEN and (((mulo.nready = '1') and (r.d.cnt /= "00")) or (MULTYPE /= 0)) then
        wy := '1';
      end if;
    when UDIVCC | SDIVCC => 
      if DIVEN and (divo.nready = '1') and (r.d.cnt /= "00") then
        wicc := '1';
      end if;
	when TR2 | INVTR2 | RED =>
	  wy := '1'; 
    when others =>
    end case;
  end if;
end;

-- select cwp 

  procedure cwp_gen(r, v : registers; annul, wcwp : std_ulogic; ncwp : cwptype;
                    cwp : out cwptype) is
  begin
    if (r.x.rstate = trap) or
        (r.x.rstate = dsu2) 
       or (rstn = '0') then cwp := v.w.s.cwp;                                                                     
    elsif (wcwp = '1') and (annul = '0') then cwp := ncwp;
    elsif r.m.wcwp = '1' then cwp := r.m.result(NWINLOG2-1 downto 0);
    else cwp := r.d.cwp; end if;
  end;
  
  -- generate wcwp in ex stage
  
  procedure cwp_ex(r : in  registers; wcwp : out std_ulogic) is
  begin
    if (r.e.ctrl.inst(31 downto 30) = FMT3) and 
       (r.e.ctrl.inst(24 downto 19) = WRPSR)
    then wcwp := not r.e.ctrl.annul; else wcwp := '0'; end if;
  end;
  
  -- generate next cwp & window under- and overflow traps
  
  procedure cwp_ctrl(r : in registers; xc_wim : in std_logic_vector(NWIN-1 downto 0);
          inst : word; de_cwp : out cwptype; wovf_exc, wunf_exc, wcwp : out std_ulogic) is
  variable op : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable wim : word;
  variable ncwp : cwptype;
  begin
    op := inst(31 downto 30); op3 := inst(24 downto 19); 
    wovf_exc := '0'; wunf_exc := '0'; wim := (others => '0'); 
    wim(NWIN-1 downto 0) := xc_wim; ncwp := r.d.cwp; wcwp := '0';
  
    if (op = FMT3) and ((op3 = RETT) or (op3 = RESTORE) or (op3 = SAVE)) then
      wcwp := '1';
      if (op3 = SAVE) then
        if (not CWPOPT) and (r.d.cwp = CWPMIN) then ncwp := CWPMAX;
        else ncwp := r.d.cwp - 1 ; end if;
      else
        if (not CWPOPT) and (r.d.cwp = CWPMAX) then ncwp := CWPMIN;
        else ncwp := r.d.cwp + 1; end if;
      end if;
      if wim(conv_integer(ncwp)) = '1' then -- wim: Window Invalid Mask  ???
        if op3 = SAVE then wovf_exc := '1'; else wunf_exc := '1'; end if;
      end if;
    end if;
    de_cwp := ncwp;
  end;

  -- generate register read address 1
  
  procedure rs1_gen(r : registers; inst : word;  rs1 : out std_logic_vector(4 downto 0);
          rs1mod : out std_ulogic) is
  variable op : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  begin
    op := inst(31 downto 30); op3 := inst(24 downto 19); 
    rs1 := inst(18 downto 14); rs1mod := '0';
   if (op = LDST) then
      if ((r.d.cnt = "01") and ((op3(2) and not op3(3)) = '1')) or
          (r.d.cnt = "10") 
      then rs1mod := '1'; rs1 := inst(29 downto 25); end if;
      if ((r.d.cnt = "10") and (op3(3 downto 0) = "0111")) then
        rs1(0) := '1';
      end if;
    end if;
-- end if;
  end;

-- load/icc interlock detection

  function icc_valid(r : registers) return std_logic is
  variable not_valid : std_logic;
  begin
    not_valid := '0';
    if MULEN or DIVEN then 
      not_valid := r.m.ctrl.wicc and (r.m.ctrl.cnt(0) or r.m.mul);
    end if;
    not_valid := not_valid or (r.a.ctrl.wicc or r.e.ctrl.wicc);
    return(not not_valid);
  end;

  procedure bp_miss_ex(r : registers; icc : std_logic_vector(3 downto 0); 
        ex_bpmiss, ra_bpannul : out std_logic) is
  variable miss : std_logic;
  begin
    miss := (not r.e.ctrl.annul) and r.e.bp and not branch_true(icc, r.e.ctrl.inst);
    ra_bpannul := miss and r.e.ctrl.inst(29);
    ex_bpmiss := miss;
  end;

  procedure bp_miss_ra(r : registers; ra_bpmiss, de_bpannul : out std_logic) is
  variable miss : std_logic;
  begin
    miss := ((not r.a.ctrl.annul) and r.a.bp and icc_valid(r) and not branch_true(r.m.icc, r.a.ctrl.inst));
    de_bpannul := miss and r.a.ctrl.inst(29);
    ra_bpmiss := miss;
  end;

  procedure lock_gen(r : registers; rs2, rd : std_logic_vector(4 downto 0);
        rfa1, rfa2, rfrd : rfatype; inst : word; fpc_lock, mulinsn, divinsn, de_wcwp : std_ulogic;
        lldcheck1, lldcheck2, lldlock, lldchkra, lldchkex, bp, nobp, de_fins_hold : out std_ulogic;
        iperr : std_logic) is
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable cond : std_logic_vector(3 downto 0);
  variable rs1  : std_logic_vector(4 downto 0);
  variable i, ldcheck1, ldcheck2, ldchkra, ldchkex, ldcheck3 : std_ulogic;
  variable ldlock, icc_check, bicc_hold, chkmul, y_check : std_logic;
  variable icc_check_bp, y_hold, mul_hold, bicc_hold_bp, fins, call_hold  : std_ulogic;
  variable de_fins_holdx : std_ulogic;
  begin
    op := inst(31 downto 30); op3 := inst(24 downto 19); 
    op2 := inst(24 downto 22); cond := inst(28 downto 25); 
    rs1 := inst(18 downto 14); i := inst(13);
    ldcheck1 := '0'; ldcheck2 := '0'; ldcheck3 := '0'; ldlock := '0';
    ldchkra := '1'; ldchkex := '1'; icc_check := '0'; bicc_hold := '0';
    y_check := '0'; y_hold := '0'; bp := '0'; mul_hold := '0';
    icc_check_bp := '0'; nobp := '0'; fins := '0'; call_hold := '0';

    if (r.d.annul = '0') 
    then
      case op is
      when CALL =>
        call_hold := '1'; nobp := BPRED;
      when FMT2 =>
        if (op2 = BICC) and (cond(2 downto 0) /= "000") then 
          icc_check_bp := '1';
        end if;
        if (op2 = BICC) then nobp := BPRED; end if;
      when FMT3 =>
        ldcheck1 := '1'; ldcheck2 := not i;
        case op3 is
        when TICC =>
          if (cond(2 downto 0) /= "000") then icc_check := '1'; end if;
          nobp := BPRED;
        when RDY => 
          ldcheck1 := '0'; ldcheck2 := '0';
          if MACPIPE then y_check := '1'; end if;
        when RDWIM | RDTBR => 
          ldcheck1 := '0'; ldcheck2 := '0';
        when RDPSR => 
          ldcheck1 := '0'; ldcheck2 := '0'; icc_check := '1';
        when SDIV | SDIVCC | UDIV | UDIVCC =>
          if DIVEN then y_check := '1'; nobp := op3(4); end if; -- no BP on divcc
        when FPOP1 | FPOP2 => ldcheck1:= '0'; ldcheck2 := '0'; fins := BPRED;
        when JMPL => call_hold := '1'; nobp := BPRED;
        when others => 
        end case;
      when LDST =>
        ldcheck1 := '1'; ldchkra := '0';
        case r.d.cnt is
        when "00" =>
          if (lddel = 2) and (op3(2) = '1') and (op3(5) = '0') then ldcheck3 := '1'; end if; 
          ldcheck2 := not i; ldchkra := '1';
        when "01" =>
          ldcheck2 := not i;
          if (op3(5) and op3(2) and not op3(3)) = '1' then ldcheck1 := '0'; ldcheck2 := '0'; end if;  -- STF/STC
        when others => ldchkex := '0';
          if CASAEN and (op3(5 downto 3) = "111") then
            ldcheck2 := '1';
          elsif (op3(5) = '1') or ((op3(5) & op3(3 downto 1)) = "0110") -- LDST
          then ldcheck1 := '0'; ldcheck2 := '0'; end if;
        end case;
        if op3(5) = '1' then fins := BPRED; end if; -- no BP on FPU/CP LD/ST
      when others => null;
      end case;
    end if;

    if MULEN or DIVEN then 
      chkmul := mulinsn;
      mul_hold := (r.a.mulstart and r.a.ctrl.wicc) or (r.m.ctrl.wicc and (r.m.ctrl.cnt(0) or r.m.mul));
      if (MULTYPE = 0) and ((icc_check_bp and BPRED and r.a.ctrl.wicc and r.a.ctrl.wy) = '1')
      then mul_hold := '1'; end if;
    else chkmul := '0'; end if;
    if DIVEN then 
      y_hold := y_check and (r.a.ctrl.wy or r.e.ctrl.wy);
      chkmul := chkmul or divinsn;
    end if;

    bicc_hold := icc_check and not icc_valid(r);
    bicc_hold_bp := icc_check_bp and not icc_valid(r);

    if (((r.a.ctrl.ld or chkmul) and r.a.ctrl.wreg and ldchkra) = '1') and
       (((ldcheck1 = '1') and (r.a.ctrl.rd = rfa1)) or
        ((ldcheck2 = '1') and (r.a.ctrl.rd = rfa2)) or
        ((ldcheck3 = '1') and (r.a.ctrl.rd = rfrd)))
    then ldlock := '1'; end if;

    if (((r.e.ctrl.ld or r.e.mac) and r.e.ctrl.wreg and ldchkex) = '1') and 
        ((lddel = 2) or (MACPIPE and (r.e.mac = '1')) or ((MULTYPE = 3) and (r.e.mul = '1'))) and
       (((ldcheck1 = '1') and (r.e.ctrl.rd = rfa1)) or
        ((ldcheck2 = '1') and (r.e.ctrl.rd = rfa2)))
    then ldlock := '1'; end if;

    de_fins_holdx := BPRED and fins and (r.a.bp or r.e.bp); -- skip BP on FPU inst in branch target address
    de_fins_hold := de_fins_holdx;
    ldlock := ldlock or y_hold or fpc_lock or (BPRED and r.a.bp and r.a.ctrl.inst(29) and de_wcwp) or de_fins_holdx;
    if ((icc_check_bp and BPRED) = '1') and ((r.a.nobp or mul_hold) = '0') then 
      bp := bicc_hold_bp;
    else ldlock := ldlock or bicc_hold or bicc_hold_bp; end if;
    lldcheck1 := ldcheck1; lldcheck2:= ldcheck2; lldlock := ldlock;
    lldchkra := ldchkra; lldchkex := ldchkex;
  end;

  procedure fpbranch(inst : in word; fcc  : in std_logic_vector(1 downto 0);
                      branch : out std_ulogic) is
  variable cond : std_logic_vector(3 downto 0);
  variable fbres : std_ulogic;
  begin
    cond := inst(28 downto 25);
    case cond(2 downto 0) is
      when "000" => fbres := '0';                       -- fba, fbn
      when "001" => fbres := fcc(1) or fcc(0);
      when "010" => fbres := fcc(1) xor fcc(0);
      when "011" => fbres := fcc(0);
      when "100" => fbres := (not fcc(1)) and fcc(0);
      when "101" => fbres := fcc(1);
      when "110" => fbres := fcc(1) and not fcc(0);
      when others => fbres := fcc(1) and fcc(0);
    end case;
    branch := cond(3) xor fbres;     
  end;

-- PC generation

  procedure ic_ctrl(r : registers; inst : word; annul_all, ldlock, branch_true, 
        fbranch_true, cbranch_true, fccv, cccv : in std_ulogic; 
        cnt : out std_logic_vector(1 downto 0); 
        de_pc : out pctype; de_branch, ctrl_annul, de_annul, jmpl_inst, inull, 
        de_pv, ctrl_pv, de_hold_pc, ticc_exception, rett_inst, mulstart,
        divstart : out std_ulogic; rabpmiss, exbpmiss, iperr : std_logic) is
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable cond : std_logic_vector(3 downto 0);
  variable hold_pc, annul_current, annul_next, branch, annul, pv : std_ulogic;
  variable de_jmpl, inhibit_current : std_ulogic;
  begin
    branch := '0'; annul_next := '0'; annul_current := '0'; pv := '1';
    hold_pc := '0'; ticc_exception := '0'; rett_inst := '0';
    op := inst(31 downto 30); op3 := inst(24 downto 19); 
    op2 := inst(24 downto 22); cond := inst(28 downto 25); 
    annul := inst(29); de_jmpl := '0'; cnt := "00";
    mulstart := '0'; divstart := '0'; inhibit_current := '0';
    if (r.d.annul = '0') 
    then
      case inst(31 downto 30) is
      when CALL =>
        branch := '1';
        if r.d.inull = '1' then 
          hold_pc := '1'; annul_current := '1';
        end if;
      when FMT2 =>
        if (op2 = BICC) or (FPEN and (op2 = FBFCC)) or (CPEN and (op2 = CBCCC)) then
          if (FPEN and (op2 = FBFCC)) then 
            branch := fbranch_true;
            if fccv /= '1' then hold_pc := '1'; annul_current := '1'; end if;
          elsif (CPEN and (op2 = CBCCC)) then 
            branch := cbranch_true;
            if cccv /= '1' then hold_pc := '1'; annul_current := '1'; end if;
          else branch := branch_true or (BPRED and orv(cond) and not icc_valid(r)); end if;
          if hold_pc = '0' then
            if (branch = '1') then
              if (cond = BA) and (annul = '1') then annul_next := '1'; end if;
            else annul_next := annul_next or annul; end if;
            if r.d.inull = '1' then -- contention with JMPL
              hold_pc := '1'; annul_current := '1'; annul_next := '0';
            end if;
          end if;
        end if;
      when FMT3 =>
        case op3 is
        when UMUL | SMUL | UMULCC | SMULCC =>
          if MULEN and (MULTYPE /= 0) then mulstart := '1'; end if;
          if MULEN and (MULTYPE = 0) then
            case r.d.cnt is
            when "00" =>
              cnt := "01"; hold_pc := '1'; pv := '0'; mulstart := '1';
            when "01" =>
              if mulo.nready = '1' then cnt := "00";
              else cnt := "01"; pv := '0'; hold_pc := '1'; end if;
            when others => null;
            end case;
          end if;
        when UDIV | SDIV | UDIVCC | SDIVCC =>
          if DIVEN then
            case r.d.cnt is
            when "00" =>
              hold_pc := '1'; pv := '0';
              if r.d.divrdy = '0' then
                cnt := "01"; divstart := '1';
              end if;
            when "01" =>
              if divo.nready = '1' then cnt := "00"; 
              else cnt := "01"; pv := '0'; hold_pc := '1'; end if;
            when others => null;
            end case;
          end if;
        when TICC =>
          if branch_true = '1' then ticc_exception := '1'; end if;
        when RETT =>
          rett_inst := '1'; --su := sregs.ps; 
        when JMPL =>
          de_jmpl := '1';
        when WRY =>
          if PWRD1 then 
            if inst(29 downto 25) = "10011" then -- %ASR19
              case r.d.cnt is
              when "00" =>
                pv := '0'; cnt := "00"; hold_pc := '1';
                if r.x.ipend = '1' then cnt := "01"; end if;              
              when "01" =>
                cnt := "00";
              when others =>
              end case;
            end if;
          end if;
        when others => null;
        end case;
      when others =>  -- LDST
        case r.d.cnt is
        when "00" =>
          if (op3(2) = '1') or (op3(1 downto 0) = "11") then -- ST/LDST/SWAP/LDD/CASA
            cnt := "01"; hold_pc := '1'; pv := '0';
          end if;
        when "01" =>
          if (op3(2 downto 0) = "111") or (op3(3 downto 0) = "1101") or
             (CASAEN and (op3(5 downto 4) = "11")) or   -- CASA
             ((CPEN or FPEN) and ((op3(5) & op3(2 downto 0)) = "1110"))
          then  -- LDD/STD/LDSTUB/SWAP
            cnt := "10"; pv := '0'; hold_pc := '1';
          else
            cnt := "00";
          end if;
        when "10" =>
          cnt := "00";
        when others => null;
        end case;
      end case;
    end if;

    if ldlock = '1' then
      cnt := r.d.cnt; annul_next := '0'; pv := '1';
    end if;
    hold_pc := (hold_pc or ldlock) and not annul_all;

    if ((exbpmiss and r.a.ctrl.annul and r.d.pv and not hold_pc) = '1') then
        annul_next := '1'; pv := '0';
    end if;
    if ((exbpmiss and not r.a.ctrl.annul and r.d.pv) = '1') then
        annul_next := '1'; pv := '0'; annul_current := '1';
    end if;
    if ((exbpmiss and not r.a.ctrl.annul and not r.d.pv and not hold_pc) = '1') then
        annul_next := '1'; pv := '0';
    end if;
    if ((exbpmiss and r.e.ctrl.inst(29) and not r.a.ctrl.annul and not r.d.pv ) = '1') 
        and (r.d.cnt = "01") then
        annul_next := '1'; annul_current := '1'; pv := '0';
    end if;
    if (exbpmiss and r.e.ctrl.inst(29) and r.a.ctrl.annul and r.d.pv) = '1' then
      annul_next := '1'; pv := '0'; inhibit_current := '1';
    end if; 
    if (rabpmiss and not r.a.ctrl.inst(29) and not r.d.annul and r.d.pv and not hold_pc) = '1' then
        annul_next := '1'; pv := '0';
    end if;
    if (rabpmiss and r.a.ctrl.inst(29) and not r.d.annul and r.d.pv ) = '1' then
        annul_next := '1'; pv := '0'; inhibit_current := '1';
    end if;

    if hold_pc = '1' then de_pc := r.d.pc; else de_pc := r.f.pc; end if;

    annul_current := (annul_current or (ldlock and not inhibit_current) or annul_all);
    ctrl_annul := r.d.annul or annul_all or annul_current or inhibit_current;
    pv := pv and not ((r.d.inull and not hold_pc) or annul_all);
    jmpl_inst := de_jmpl and not annul_current and not inhibit_current;
    annul_next := (r.d.inull and not hold_pc) or annul_next or annul_all;
    if (annul_next = '1') or (rstn = '0') then
      cnt := (others => '0'); 
    end if;

    de_hold_pc := hold_pc; de_branch := branch; de_annul := annul_next;
    de_pv := pv; ctrl_pv := r.d.pv and 
        not ((r.d.annul and not r.d.pv) or annul_all or annul_current);
    inull := (not rstn) or r.d.inull or hold_pc or annul_all;

  end;

-- register write address generation

  procedure rd_gen(r : registers; inst : word; wreg, ld : out std_ulogic; 
        rdo : out std_logic_vector(4 downto 0)) is
  variable write_reg : std_ulogic;
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable rd  : std_logic_vector(4 downto 0);
  begin

    op    := inst(31 downto 30);
    op2   := inst(24 downto 22);
    op3   := inst(24 downto 19);

    write_reg := '0'; rd := inst(29 downto 25); ld := '0';

    case op is
    when CALL =>
        write_reg := '1'; rd := "01111";    -- CALL saves PC in r[15] (%o7)
    when FMT2 => 
        if (op2 = SETHI) then write_reg := '1'; end if;
    when FMT3 =>
        case op3 is
        when UMUL | SMUL | UMULCC | SMULCC => 
          if MULEN then
            if (((mulo.nready = '1') and (r.d.cnt /= "00")) or (MULTYPE /= 0)) then
              write_reg := '1'; 
            end if;
          else write_reg := '1'; end if;
        when UDIV | SDIV | UDIVCC | SDIVCC => 
          if DIVEN then
            if (divo.nready = '1') and (r.d.cnt /= "00") then
              write_reg := '1'; 
            end if;
          else write_reg := '1'; end if;
        when RETT | WRPSR | WRWIM | WRTBR | TICC | FLUSH => null; -- bilgiday 
        when WRY => -- bilgiday
		 if (inst(29 downto 25) = "10110") then -- bilgiday asr22
		   write_reg := r.w.wreg0;
--		   if (invalid_bufcnt_w = '1') then
--		     write_reg := r.w.wreg0;
--		   else
--		     write_reg := r.w.wreg1;
--		   end if;
		 elsif (inst(29 downto 25) = "10111") then -- bilgiday asr23
		   write_reg := r.w.wreg1;
--		   if (invalid_bufcnt_w = '1') then
--		     write_reg := r.w.wreg0;
--		   else
--		     write_reg := r.w.wreg1;
--		   end if;
		 else -- bilgiday asr other
		    write_reg := '1';
		 end if;
        when FPOP1 | FPOP2 => null;
        when CPOP1 | CPOP2 => null;
        when others => write_reg := '1';
        end case;
      when others =>   -- LDST
	 if (op3 /= ANDC8 and op3 /= ANDC16 and op3 /= XORC8 and op3 /= XORC16 and op3 /= XNORC8 and op3 /= XNORC16) then
        ld := not op3(2);
        if (op3(2) = '0') and not ((CPEN or FPEN) and (op3(5) = '1')) 
        then write_reg := '1'; end if;
        case op3 is
        when SWAP | SWAPA | LDSTUB | LDSTUBA | CASA =>
          if r.d.cnt = "00" then write_reg := '1'; ld := '1'; end if;
        when others => null;
        end case;
        if r.d.cnt = "01" then
          case op3 is
          when LDD | LDDA | LDDC | LDDF => rd(0) := '1';
          when others =>
          end case;
        end if;
	else 
	  write_reg := '1'; 
	end if; 
    end case;

    if (rd = "00000") then write_reg := '0'; end if;
    wreg := write_reg; rdo := rd;
  end;

-- immediate data generation

  function imm_data (r : registers; insn : word) 
        return word is
  variable immediate_data, inst : word;
  begin
    immediate_data := (others => '0'); inst := insn;
    case inst(31 downto 30) is
    when FMT2 =>
      immediate_data := inst(21 downto 0) & "0000000000";
    when others =>      -- LDST
      immediate_data(31 downto 13) := (others => inst(12));
      immediate_data(12 downto 0) := inst(12 downto 0);
    end case;
    return(immediate_data);
  end;

-- read special registers
  function get_spr (r : registers) return word is
  variable spr : word;
  begin
    spr := (others => '0');
      case r.e.ctrl.inst(24 downto 19) is
      when RDPSR => spr(31 downto 5) := conv_std_logic_vector(IMPL,4) &
        conv_std_logic_vector(VER,4) & r.m.icc & "000000" & r.w.s.ec & r.w.s.ef & 
        r.w.s.pil & r.e.su & r.w.s.ps & r.e.et;
        spr(NWINLOG2-1 downto 0) := r.e.cwp;
      when RDTBR => spr(31 downto 4) := r.w.s.tba & r.w.s.tt;
      when RDWIM => spr(NWIN-1 downto 0) := r.w.s.wim;
      when others =>
      end case;
    return(spr);
  end;

-- immediate data select

  function imm_select(inst : word) return boolean is
  variable imm : boolean;
  begin
    imm := false;
    case inst(31 downto 30) is
    when FMT2 =>
      case inst(24 downto 22) is
      when SETHI => imm := true;
      when others => 
      end case;
    when FMT3 =>
      case inst(24 downto 19) is
      when RDWIM | RDPSR | RDTBR => imm := true;
      when others => if (inst(13) = '1') then imm := true; end if;
      end case;
    when LDST => 
      if (inst(13) = '1') then imm := true; end if;
    when others => 
    end case;
    return(imm);
  end;

-- EXE operation

  procedure alu_op(r : in registers; iop1, iop2 : in word; me_icc : std_logic_vector(3 downto 0);
        my, ldbp : std_ulogic; aop1, aop2 : out word; aluop  : out std_logic_vector(3 downto 0); -- Pantea 2->3
        alusel : out std_logic_vector(1 downto 0); aluadd : out std_ulogic;
        shcnt : out std_logic_vector(4 downto 0); sari, shleft, ymsb, 
        mulins, divins, mulstep, macins, ldbp2, invop2 : out std_logic
        ) is
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable rs1, rs2, rd  : std_logic_vector(4 downto 0);
  variable icc : std_logic_vector(3 downto 0);
  variable y0, i  : std_ulogic;
  begin

    op   := r.a.ctrl.inst(31 downto 30);
    op2  := r.a.ctrl.inst(24 downto 22);
    op3  := r.a.ctrl.inst(24 downto 19);
    rs1 := r.a.ctrl.inst(18 downto 14); i := r.a.ctrl.inst(13);
    rs2 := r.a.ctrl.inst(4 downto 0); rd := r.a.ctrl.inst(29 downto 25);
    aop1 := iop1; aop2 := iop2; ldbp2 := ldbp;
    aluop := EXE_NOP; alusel := EXE_RES_MISC; aluadd := '1'; 
    shcnt := iop2(4 downto 0); sari := '0'; shleft := '0'; invop2 := '0';
    ymsb := iop1(0); mulins := '0'; divins := '0'; mulstep := '0';
    macins := '0';

    if r.e.ctrl.wy = '1' then y0 := my;
    elsif r.m.ctrl.wy = '1' then y0 := r.m.y(0);
    elsif r.x.ctrl.wy = '1' then y0 := r.x.y(0);
    else y0 := r.w.s.y(0); end if;

    if r.e.ctrl.wicc = '1' then icc := me_icc;
    elsif r.m.ctrl.wicc = '1' then icc := r.m.icc;
    elsif r.x.ctrl.wicc = '1' then icc := r.x.icc;
    else icc := r.w.s.icc; end if;

    case op is
    when CALL =>
      aluop := EXE_LINK;
    when FMT2 =>
      case op2 is
      when SETHI => aluop := EXE_PASS2;
      when others =>
      end case;
    when FMT3 =>
      case op3 is
      when IADD | ADDX | ADDCC | ADDXCC | TADDCC | TADDCCTV | SAVE | RESTORE |
           TICC | JMPL | RETT  => alusel := EXE_RES_ADD;
      when ISUB | SUBX | SUBCC | SUBXCC | TSUBCC | TSUBCCTV  => 
        alusel := EXE_RES_ADD; aluadd := '0'; aop2 := not iop2; invop2 := '1';
      when MULSCC => alusel := EXE_RES_ADD;
        aop1 := (icc(3) xor icc(1)) & iop1(31 downto 1);
        if y0 = '0' then aop2 := (others => '0'); ldbp2 := '0'; end if;
        mulstep := '1';
      when UMUL | UMULCC | SMUL | SMULCC => 
        if MULEN then mulins := '1'; end if;
      when UMAC | SMAC => 
        if MACEN then mulins := '1'; macins := '1'; end if;
      when UDIV | UDIVCC | SDIV | SDIVCC => 
        if DIVEN then 
          aluop := EXE_DIV; alusel := EXE_RES_LOGIC; divins := '1';
        end if;
      when IAND | ANDCC => aluop := EXE_AND; alusel := EXE_RES_LOGIC;
      when SUBROT => aluop := EXE_SUBROT; alusel := EXE_RES_LOGIC; -- pk 
      when ANDN | ANDNCC => aluop := EXE_ANDN; alusel := EXE_RES_LOGIC;
      when IOR | ORCC  => aluop := EXE_OR; alusel := EXE_RES_LOGIC;
      when ORN | ORNCC  => aluop := EXE_ORN; alusel := EXE_RES_LOGIC;
      when IXNOR | XNORCC  => aluop := EXE_XNOR; alusel := EXE_RES_LOGIC;
      when XORCC | IXOR | WRPSR | WRWIM | WRTBR | WRY => 
        aluop := EXE_XOR; alusel := EXE_RES_LOGIC;
      when RDPSR | RDTBR | RDWIM => aluop := EXE_SPR;
      when RDY => aluop := EXE_RDY;
      when ISLL => aluop := EXE_SLL; alusel := EXE_RES_SHIFT; shleft := '1'; 
                   shcnt := not iop2(4 downto 0); invop2 := '1';
      when ISRL => aluop := EXE_SRL; alusel := EXE_RES_SHIFT; 
      when "011101" => aluop := EXE_TR2; alusel := EXE_RES_SHIFT; -- pk TR2 
      when "011001" => aluop := EXE_INVTR2; alusel := EXE_RES_SHIFT; -- pk INVTR2
      when RED => aluop := EXE_RED; alusel := EXE_RES_SHIFT; -- pk RED 
      when FTCHK => aluop := EXE_FTCHK; alusel := EXE_RES_SHIFT; -- pk FTCHK
      when ISRA => aluop := EXE_SRA; alusel := EXE_RES_SHIFT; sari := iop1(31);
      when FPOP1 | FPOP2 =>
      when others =>
      end case;
    when others =>      -- LDST
      case op3 is
        when ANDC8 => aluop := EXE_ANDC8; alusel := EXE_RES_SHIFT; -- pk ANDC8 
        when ANDC16 => aluop := EXE_ANDC16; alusel := EXE_RES_SHIFT; -- pk ANDC16 
        when XORC8 => aluop := EXE_XORC8; alusel := EXE_RES_SHIFT; -- pk XORC8 
        when XORC16 => aluop := EXE_XORC16; alusel := EXE_RES_SHIFT; -- pk XORC16 
        when XNORC8 => aluop := EXE_XNORC8; alusel := EXE_RES_SHIFT; -- pk XNORC8 
        when XNORC16 => aluop := EXE_XNORC16; alusel := EXE_RES_SHIFT; -- pk XNORC16 
        when others =>
          case r.a.ctrl.cnt is
            when "00" =>
               alusel := EXE_RES_ADD;
            when "01" =>
              case op3 is
                when LDD | LDDA | LDDC => alusel := EXE_RES_ADD;
                when LDDF => alusel := EXE_RES_ADD;
                when SWAP | SWAPA | LDSTUB | LDSTUBA | CASA => alusel := EXE_RES_ADD;
                when STF | STDF =>
                when others =>
                   aluop := EXE_PASS1;
                    if op3(2) = '1' then
                     if op3(1 downto 0) = "01" then aluop := EXE_STB;
                   elsif op3(1 downto 0) = "10" then aluop := EXE_STH; end if;
                    end if;
              end case;
            when "10" =>
              aluop := EXE_PASS1;
              if op3(2) = '1' then  -- ST
                if (op3(3) and not op3(5) and not op3(1))= '1' then aluop := EXE_ONES; end if; -- LDSTUB
              end if;
              if CASAEN and (r.m.casa = '1') then
                alusel := EXE_RES_ADD; aluadd := '0'; aop2 := not iop2; invop2 := '1';
              end if;
            when others =>
          end case;
      end case;
    end case;
  end;

  function ra_inull_gen(r, v : registers) return std_ulogic is
  variable de_inull : std_ulogic;
  begin
    de_inull := '0';
    if ((v.e.jmpl or v.e.ctrl.rett) and not v.e.ctrl.annul and not (r.e.jmpl and not r.e.ctrl.annul)) = '1' then de_inull := '1'; end if;
    if ((v.a.jmpl or v.a.ctrl.rett) and not v.a.ctrl.annul and not (r.a.jmpl and not r.a.ctrl.annul)) = '1' then de_inull := '1'; end if;
    return(de_inull);    
  end;

-- operand generation

  procedure op_mux(r : in registers; rfd, ed, md, xd, im : in word; 
        rsel : in std_logic_vector(2 downto 0); 
        ldbp : out std_ulogic; d : out word; id : std_logic) is 
  begin
    ldbp := '0';
    case rsel is
    when "000" => d := rfd;
    when "001" => d := ed;
    when "010" => d := md; if lddel = 1 then ldbp := r.m.ctrl.ld; end if;
    when "011" => d := xd;
    when "100" => d := im;
    when "101" => d := (others => '0');
    when "110" => d := r.w.result;
    when others => d := (others => '-');
    end case;
    if CASAEN and (r.a.ctrl.cnt = "10") and ((r.m.casa and not id) = '1') then ldbp := '1'; end if;
  end;

  procedure op_find(r : in registers; ldchkra : std_ulogic; ldchkex : std_ulogic;
         rs1 : std_logic_vector(4 downto 0); ra : rfatype; im : boolean; rfe : out std_ulogic; 
        osel : out std_logic_vector(2 downto 0); ldcheck : std_ulogic) is
  begin
    rfe := '0';
    if im then osel := "100";
    elsif rs1 = "00000" then osel := "101";     -- %g0
    elsif ((r.a.ctrl.wreg and ldchkra) = '1') and (ra = r.a.ctrl.rd) then osel := "001";
    elsif ((r.e.ctrl.wreg and ldchkex) = '1') and (ra = r.e.ctrl.rd) then osel := "010";                                        
    elsif (r.m.ctrl.wreg = '1') and (ra = r.m.ctrl.rd) then osel := "011";             
    elsif (irfwt = 0) and (r.x.ctrl.wreg = '1') and (ra = r.x.ctrl.rd) then osel := "110"; 
	else  osel := "000"; rfe := ldcheck; end if;
  end;

-- generate carry-in for alu

  procedure cin_gen(r : registers; me_cin : in std_ulogic; cin : out std_ulogic) is
  variable op : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable ncin : std_ulogic;
  begin

    op := r.a.ctrl.inst(31 downto 30); op3 := r.a.ctrl.inst(24 downto 19);
    if r.e.ctrl.wicc = '1' then ncin := me_cin;
    else ncin := r.m.icc(0); end if;
    cin := '0';
    case op is
    when FMT3 =>
      case op3 is
      when ISUB | SUBCC | TSUBCC | TSUBCCTV => cin := '1';
      when ADDX | ADDXCC => cin := ncin; 
      when SUBX | SUBXCC => cin := not ncin; 
      when others => null;
      end case;
    when LDST =>
      if CASAEN and (r.m.casa = '1') and (r.a.ctrl.cnt = "10") then
        cin := '1';
      end if;
    when others => null;
    end case;
  end;

  procedure logic_op(r : registers; aluin1, aluin2, mey, shiftres : word; 
        ymsb : std_ulogic; logicres, y : out word) is
  variable logicout : word;
  begin
    case r.e.aluop is
    when EXE_AND   => logicout := aluin1 and aluin2;
    when EXE_SUBROT   => 
	case aluin2(4 downto 0) is
		when "00010" => logicout := aluin1(30) & aluin1(31) & aluin1(28) & aluin1(29) & 
					aluin1(26) & aluin1(27) & aluin1(24) & aluin1(25) &
					aluin1(22) & aluin1(23) & aluin1(20) & aluin1(21) &
					aluin1(18) & aluin1(19) & aluin1(16) & aluin1(17) &
					aluin1(14) & aluin1(15) & aluin1(12) & aluin1(13) &
					aluin1(10) & aluin1(11) & aluin1(8) & aluin1(9) &
					aluin1(6) & aluin1(7) & aluin1(4) & aluin1(5) &
					aluin1(2) & aluin1(3) & aluin1(0) & aluin1(1);

		when "00100" => logicout :=  aluin1(30) & aluin1(29) & aluin1(28) & aluin1(31) & 
					aluin1(26) & aluin1(25) & aluin1(24) & aluin1(27) &
					aluin1(22) & aluin1(21) & aluin1(20) & aluin1(23) & 
					aluin1(18) & aluin1(17) & aluin1(16) & aluin1(19) &
					aluin1(14) & aluin1(13) & aluin1(12) & aluin1(15) & 
					aluin1(10) & aluin1(9) & aluin1(8) & aluin1(11) &
 					aluin1(6) & aluin1(5) & aluin1(4) & aluin1(7) & 
					aluin1(2) & aluin1(1) & aluin1(0) & aluin1(3);

		when others => logicout := aluin1;
	end case;

    ------------------------
	when EXE_ANDN  => logicout := aluin1 and not aluin2;
    when EXE_OR    => logicout := aluin1 or aluin2;
    when EXE_ORN   => logicout := aluin1 or not aluin2;
    when EXE_XOR   => logicout := aluin1 xor aluin2;
    when EXE_XNOR  => logicout := aluin1 xor not aluin2;
    when EXE_DIV   => 
      if DIVEN then logicout := aluin2;
      else logicout := (others => '-'); end if;
    when others => logicout := (others => '-');
    end case;
    if (r.e.ctrl.wy and r.e.mulstep) = '1' then 
      y := ymsb & r.m.y(31 downto 1); 
    elsif (r.e.ctrl.wy = '1' and (r.e.aluop = EXE_TR2 or r.e.aluop = EXE_INVTR2 or r.e.aluop = EXE_RED)) then 
	  if (r.e.aluop = EXE_TR2) then -- TR2 
	    y := aluin1(31) & aluin2(31) & aluin1(30) & aluin2(30) & aluin1(29) & aluin2(29) & aluin1(28) & aluin2(28) &
		aluin1(27) & aluin2(27) & aluin1(26) & aluin2(26) & aluin1(25) & aluin2(25) & aluin1(24) & aluin2(24) &
		aluin1(23) & aluin2(23) & aluin1(22) & aluin2(22) & aluin1(21) & aluin2(21) & aluin1(20) & aluin2(20) &
		aluin1(19) & aluin2(19) & aluin1(18) & aluin2(18) & aluin1(17) & aluin2(17) & aluin1(16) & aluin2(16);
	 elsif (r.e.aluop = EXE_INVTR2) then -- INVTR2
	    y := aluin1(31) & aluin1(29) & aluin1(27) & aluin1(25) & aluin1(23) & aluin1(21) & aluin1(19) & aluin1(17) &
		aluin1(15) & aluin1(13) & aluin1(11) & aluin1(9) & aluin1(7) & aluin1(5) & aluin1(3) & aluin1(1) &
		aluin2(31) & aluin2(29) & aluin2(27) & aluin2(25) & aluin2(23) & aluin2(21) & aluin2(19) & aluin2(17) &
		aluin2(15) & aluin2(13) & aluin2(11) & aluin2(9) & aluin2(7) & aluin2(5) & aluin2(3) & aluin2(1);
	 else -- RED
	     case aluin2(4 downto 0) is 
		when "00010" => 
			y := aluin1(31 downto 16) & aluin1(31 downto 16);
		when "00011" => 
			y := (not aluin1(31 downto 16)) & (aluin1(31 downto 16));
		when "00100" => 
			y := aluin1(15 downto 8) & aluin1(15 downto 8) & aluin1(15 downto 8) & aluin1(15 downto 8);
		when "00101" =>
			y := (not aluin1(15 downto 8)) & aluin1(15 downto 8) & (not aluin1(15 downto 8)) & aluin1(15 downto 8);
		when "00110" =>
			y := aluin1(31 downto 24) & aluin1(31 downto 24) & aluin1(31 downto 24) & aluin1(31 downto 24); 
		when "00111" => 
                        y := (not aluin1(31 downto 24)) & aluin1(31 downto 24) & (not aluin1(31 downto 24)) & aluin1(31 downto 24);
		when others =>
			y := aluin1; 
	     end case;  	
	 end if;
	-------------------------------------------
    elsif r.e.ctrl.wy = '1' then y := logicout;
    elsif r.m.ctrl.wy = '1' then y := mey; 
    elsif MACPIPE and (r.x.mac = '1') then y := mulo.result(63 downto 32);
    elsif r.x.ctrl.wy = '1' then y := r.x.y; 
    else y := r.w.s.y; end if;
    logicres := logicout;
  end;

  procedure shift_op(r : registers; aluin1, aluin2 : word; 
			shcnt : std_logic_vector(4 downto 0); sari : std_ulogic; 
			shiftres : out word) is
  variable shiftout : word;
  begin
  
    case r.e.aluop is 
    when EXE_TR2 => shiftout := aluin1(15) & aluin2(15) & aluin1(14) & aluin2(14) & aluin1(13) & aluin2(13) & aluin1(12) & aluin2(12) &
				aluin1(11) & aluin2(11) & aluin1(10) & aluin2(10) & aluin1(9) & aluin2(9) & aluin1(8) & aluin2(8) &
				aluin1(7) & aluin2(7) & aluin1(6) & aluin2(6) & aluin1(5) & aluin2(5) & aluin1(4) & aluin2(4) &
				aluin1(3) & aluin2(3) & aluin1(2) & aluin2(2) & aluin1(1) & aluin2(1) & aluin1(0) & aluin2(0);
    
    when EXE_INVTR2 => shiftout := aluin1(30) & aluin1(28) & aluin1(26) & aluin1(24) & aluin1(22) & aluin1(20) & aluin1(18) & aluin1(16) &
		    	aluin1(14) & aluin1(12) & aluin1(10) & aluin1(8) & aluin1(6) & aluin1(4) & aluin1(2) & aluin1(0) &
		    	aluin2(30) & aluin2(28) & aluin2(26) & aluin2(24) & aluin2(22) & aluin2(20) & aluin2(18) & aluin2(16) &
		    	aluin2(14) & aluin2(12) & aluin2(10) & aluin2(8) & aluin2(6) & aluin2(4) & aluin2(2) & aluin2(0);

       when EXE_RED => 
	case aluin2(4 downto 0) is 
            when "00010" =>
                shiftout := aluin1(15 downto 0) & aluin1(15 downto 0);
            when "00011" =>
                shiftout := (not aluin1(15 downto 0)) & (aluin1(15 downto 0));
            when "00100" =>
                shiftout := aluin1(7 downto 0) & aluin1(7 downto 0) & aluin1(7 downto 0) & aluin1(7 downto 0);
            when "00101" =>
                shiftout := (not aluin1(7 downto 0)) & aluin1(7 downto 0) & (not aluin1(7 downto 0)) & aluin1(7 downto 0);
            when "00110" =>
                shiftout := aluin1(23 downto 16) & aluin1(23 downto 16) & aluin1(23 downto 16) & aluin1(23 downto 16);
            when "00111" =>
                shiftout := (not aluin1(23 downto 16)) & aluin1(23 downto 16) & (not aluin1(23 downto 16)) & aluin1(23 downto 16);
            when others =>
		shiftout := aluin1;
        end case;
   
    when EXE_FTCHK =>
	case aluin2(4 downto 0) is 
	    when "00010" =>
		shiftout(31 downto 16) := (aluin1(31) xor aluin1(15)) &
                                         (aluin1(30) xor aluin1(14)) &
                                         (aluin1(29) xor aluin1(13)) &
                                         (aluin1(28) xor aluin1(12)) &
                                         (aluin1(27) xor aluin1(11)) &
                                         (aluin1(26) xor aluin1(10)) &
                                         (aluin1(25) xor aluin1(9)) &
                                         (aluin1(24) xor aluin1(8)) &
                                         (aluin1(23) xor aluin1(7)) &
                                         (aluin1(22) xor aluin1(6)) &
                                         (aluin1(21) xor aluin1(5)) &
                                         (aluin1(20) xor aluin1(4)) &
                                         (aluin1(19) xor aluin1(3)) &
                                         (aluin1(18) xor aluin1(2)) &
                                         (aluin1(17) xor aluin1(1)) &
                                         (aluin1(16) xor aluin1(0)) ;

		shiftout(15 downto 0) := (aluin1(31) xor aluin1(15)) &
					 (aluin1(30) xor aluin1(14)) &
                                         (aluin1(29) xor aluin1(13)) &
                                         (aluin1(28) xor aluin1(12)) &
                                         (aluin1(27) xor aluin1(11)) &
                                         (aluin1(26) xor aluin1(10)) &
                                         (aluin1(25) xor aluin1(9)) &
                                         (aluin1(24) xor aluin1(8)) &
                                         (aluin1(23) xor aluin1(7)) &
                                         (aluin1(22) xor aluin1(6)) &
                                         (aluin1(21) xor aluin1(5)) &
                                         (aluin1(20) xor aluin1(4)) &
                                         (aluin1(19) xor aluin1(3)) &
                                         (aluin1(18) xor aluin1(2)) &
                                         (aluin1(17) xor aluin1(1)) &
                                         (aluin1(16) xor aluin1(0)) ;
	    when "01010" =>
                shiftout(31 downto 16) := (aluin1(31) xnor aluin1(15)) &
                                         (aluin1(30) xnor aluin1(14)) &
                                         (aluin1(29) xnor aluin1(13)) &
                                         (aluin1(28) xnor aluin1(12)) &
                                         (aluin1(27) xnor aluin1(11)) &
                                         (aluin1(26) xnor aluin1(10)) &
                                         (aluin1(25) xnor aluin1(9)) &
                                         (aluin1(24) xnor aluin1(8)) &
                                         (aluin1(23) xnor aluin1(7)) &
                                         (aluin1(22) xnor aluin1(6)) &
                                         (aluin1(21) xnor aluin1(5)) &
                                         (aluin1(20) xnor aluin1(4)) &
                                         (aluin1(19) xnor aluin1(3)) &
                                         (aluin1(18) xnor aluin1(2)) &
                                         (aluin1(17) xnor aluin1(1)) &
                                         (aluin1(16) xnor aluin1(0)) ;

                shiftout(15 downto 0) := (aluin1(31) xor aluin1(15)) &
                                         (aluin1(30) xor aluin1(14)) &
                                         (aluin1(29) xor aluin1(13)) &
                                         (aluin1(28) xor aluin1(12)) &
                                         (aluin1(27) xor aluin1(11)) &
                                         (aluin1(26) xor aluin1(10)) &
                                         (aluin1(25) xor aluin1(9)) &
                                         (aluin1(24) xor aluin1(8)) &
                                         (aluin1(23) xor aluin1(7)) &
                                         (aluin1(22) xor aluin1(6)) &
                                         (aluin1(21) xor aluin1(5)) &
                                         (aluin1(20) xor aluin1(4)) &
                                         (aluin1(19) xor aluin1(3)) &
                                         (aluin1(18) xor aluin1(2)) &
                                         (aluin1(17) xor aluin1(1)) &
                                         (aluin1(16) xor aluin1(0)) ;
	    when "00011" =>
                shiftout(31 downto 16) := (aluin1(31) xnor aluin1(15)) &
                                         (aluin1(30) xnor aluin1(14)) &
                                         (aluin1(29) xnor aluin1(13)) &
                                         (aluin1(28) xnor aluin1(12)) &
                                         (aluin1(27) xnor aluin1(11)) &
                                         (aluin1(26) xnor aluin1(10)) &
                                         (aluin1(25) xnor aluin1(9)) &
                                         (aluin1(24) xnor aluin1(8)) &
                                         (aluin1(23) xnor aluin1(7)) &
                                         (aluin1(22) xnor aluin1(6)) &
                                         (aluin1(21) xnor aluin1(5)) &
                                         (aluin1(20) xnor aluin1(4)) &
                                         (aluin1(19) xnor aluin1(3)) &
                                         (aluin1(18) xnor aluin1(2)) &
                                         (aluin1(17) xnor aluin1(1)) &
                                         (aluin1(16) xnor aluin1(0)) ;

                shiftout(15 downto 0) := (aluin1(31) xnor aluin1(15)) &
                                         (aluin1(30) xnor aluin1(14)) &
                                         (aluin1(29) xnor aluin1(13)) &
                                         (aluin1(28) xnor aluin1(12)) &
                                         (aluin1(27) xnor aluin1(11)) &
                                         (aluin1(26) xnor aluin1(10)) &
                                         (aluin1(25) xnor aluin1(9)) &
                                         (aluin1(24) xnor aluin1(8)) &
                                         (aluin1(23) xnor aluin1(7)) &
                                         (aluin1(22) xnor aluin1(6)) &
                                         (aluin1(21) xnor aluin1(5)) &
                                         (aluin1(20) xnor aluin1(4)) &
                                         (aluin1(19) xnor aluin1(3)) &
                                         (aluin1(18) xnor aluin1(2)) &
                                         (aluin1(17) xnor aluin1(1)) &
                                         (aluin1(16) xnor aluin1(0)) ;
	    when "01011" =>
                shiftout(31 downto 16) := (aluin1(31) xor aluin1(15)) &
                                         (aluin1(30) xor aluin1(14)) &
                                         (aluin1(29) xor aluin1(13)) &
                                         (aluin1(28) xor aluin1(12)) &
                                         (aluin1(27) xor aluin1(11)) &
                                         (aluin1(26) xor aluin1(10)) &
                                         (aluin1(25) xor aluin1(9)) & 
                                         (aluin1(24) xor aluin1(8)) & 
                                         (aluin1(23) xor aluin1(7)) & 
                                         (aluin1(22) xor aluin1(6)) & 
                                         (aluin1(21) xor aluin1(5)) &
                                         (aluin1(20) xor aluin1(4)) &
                                         (aluin1(19) xor aluin1(3)) &
                                         (aluin1(18) xor aluin1(2)) &
                                         (aluin1(17) xor aluin1(1)) &
                                         (aluin1(16) xor aluin1(0)) ;

                shiftout(15 downto 0) := (aluin1(31) xnor aluin1(15)) &
                                         (aluin1(30) xnor aluin1(14)) &
                                         (aluin1(29) xnor aluin1(13)) &
                                         (aluin1(28) xnor aluin1(12)) &
                                         (aluin1(27) xnor aluin1(11)) &
                                         (aluin1(26) xnor aluin1(10)) &
                                         (aluin1(25) xnor aluin1(9)) &
                                         (aluin1(24) xnor aluin1(8)) &
                                         (aluin1(23) xnor aluin1(7)) &
                                         (aluin1(22) xnor aluin1(6)) &
                                         (aluin1(21) xnor aluin1(5)) &
                                         (aluin1(20) xnor aluin1(4)) &
                                         (aluin1(19) xnor aluin1(3)) &
                                         (aluin1(18) xnor aluin1(2)) &
                                         (aluin1(17) xnor aluin1(1)) &
                                         (aluin1(16) xnor aluin1(0)) ;
	    when "00100" =>
                shiftout(31 downto 24) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;

                shiftout(23 downto 16) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;

                shiftout(15 downto 8) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;

                shiftout(7 downto 0) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
					((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;
	
	    when "01100" =>
                shiftout(31 downto 24) := ((aluin1(31) xnor aluin1(7)) and (aluin1(23) xnor aluin1(7)) and (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) and (aluin1(22) xnor aluin1(6)) and (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) and (aluin1(21) xnor aluin1(5)) and (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) and (aluin1(20) xnor aluin1(4)) and (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) and (aluin1(19) xnor aluin1(3)) and (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) and (aluin1(18) xnor aluin1(2)) and (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) and (aluin1(17) xnor aluin1(1)) and (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) and (aluin1(16) xnor aluin1(0)) and (aluin1(8) xnor aluin1(0))) ;

                shiftout(23 downto 16) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;

                shiftout(15 downto 8) := ((aluin1(31) xnor aluin1(7)) and (aluin1(23) xnor aluin1(7)) and (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) and (aluin1(22) xnor aluin1(6)) and (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) and (aluin1(21) xnor aluin1(5)) and (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) and (aluin1(20) xnor aluin1(4)) and (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) and (aluin1(19) xnor aluin1(3)) and (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) and (aluin1(18) xnor aluin1(2)) and (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) and (aluin1(17) xnor aluin1(1)) and (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) and (aluin1(16) xnor aluin1(0)) and (aluin1(8) xnor aluin1(0))) ;

                shiftout(7 downto 0) := ((aluin1(31) xor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xor aluin1(0))) ;

            when "11100" =>
            	for idx_offset in 0 to 7 loop 
	                if 	((aluin1(24+idx_offset) /= aluin1(0+idx_offset)) and (aluin1(16+idx_offset) = aluin1(0+idx_offset)) and (aluin1(8+idx_offset) = aluin1(0+idx_offset))) or
	                	((aluin1(24+idx_offset) = aluin1(0+idx_offset)) and (aluin1(16+idx_offset) /= aluin1(0+idx_offset)) and (aluin1(8+idx_offset) = aluin1(0+idx_offset))) or
	                	((aluin1(24+idx_offset) = aluin1(0+idx_offset)) and (aluin1(16+idx_offset) = aluin1(0+idx_offset)) and (aluin1(8+idx_offset) /= aluin1(0+idx_offset))) then 
		                    shiftout(0+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(8+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(24+idx_offset) := aluin1(0+idx_offset);
	                elsif ((aluin1(24+idx_offset) = aluin1(16+idx_offset)) and (aluin1(16+idx_offset) = aluin1(8+idx_offset)) and (aluin1(16+idx_offset) /= aluin1(0+idx_offset))) then 
		                    shiftout(0+idx_offset) := aluin1(16+idx_offset);
		                    shiftout(8+idx_offset) := aluin1(16+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(16+idx_offset);
		                    shiftout(24+idx_offset) := aluin1(16+idx_offset);
		            else 
		                    shiftout(0+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(8+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(24+idx_offset) := aluin1(0+idx_offset);
		            end if;
		        end loop; 

	    when "00101" =>
		shiftout(31 downto 24) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

		shiftout(23 downto 16) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

                shiftout(15 downto 8) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

                shiftout(7 downto 0) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

	    when "01101" =>
                shiftout(31 downto 24) := ((aluin1(31) xor aluin1(7)) and (aluin1(23) xnor aluin1(7)) and (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) and (aluin1(22) xnor aluin1(6)) and (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) and (aluin1(21) xnor aluin1(5)) and (aluin1(13) xor aluin1(5))) &
                                        ((aluin1(28) xor aluin1(4)) and (aluin1(20) xnor aluin1(4)) and (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) and (aluin1(19) xnor aluin1(3)) and (aluin1(11) xor aluin1(3))) &
                                        ((aluin1(26) xor aluin1(2)) and (aluin1(18) xnor aluin1(2)) and (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) and (aluin1(17) xnor aluin1(1)) and (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) and (aluin1(16) xnor aluin1(0)) and (aluin1(8) xor aluin1(0))) ;

                shiftout(23 downto 16) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) & 
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) & 
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

                shiftout(15 downto 8) := ((aluin1(31) xor aluin1(7)) and (aluin1(23) xnor aluin1(7)) and (aluin1(15) xor aluin1(7))) &
                                        ((aluin1(30) xor aluin1(6)) and (aluin1(22) xnor aluin1(6)) and (aluin1(14) xor aluin1(6))) &
                                        ((aluin1(29) xor aluin1(5)) and (aluin1(21) xnor aluin1(5)) and (aluin1(13) xor aluin1(5))) & 
                                        ((aluin1(28) xor aluin1(4)) and (aluin1(20) xnor aluin1(4)) and (aluin1(12) xor aluin1(4))) &
                                        ((aluin1(27) xor aluin1(3)) and (aluin1(19) xnor aluin1(3)) and (aluin1(11) xor aluin1(3))) & 
                                        ((aluin1(26) xor aluin1(2)) and (aluin1(18) xnor aluin1(2)) and (aluin1(10) xor aluin1(2))) &
                                        ((aluin1(25) xor aluin1(1)) and (aluin1(17) xnor aluin1(1)) and (aluin1(9) xor aluin1(1))) &
                                        ((aluin1(24) xor aluin1(0)) and (aluin1(16) xnor aluin1(0)) and (aluin1(8) xor aluin1(0))) ;

                shiftout(7 downto 0) := ((aluin1(31) xnor aluin1(7)) or (aluin1(23) xor aluin1(7)) or (aluin1(15) xnor aluin1(7))) &
                                        ((aluin1(30) xnor aluin1(6)) or (aluin1(22) xor aluin1(6)) or (aluin1(14) xnor aluin1(6))) &
                                        ((aluin1(29) xnor aluin1(5)) or (aluin1(21) xor aluin1(5)) or (aluin1(13) xnor aluin1(5))) &
                                        ((aluin1(28) xnor aluin1(4)) or (aluin1(20) xor aluin1(4)) or (aluin1(12) xnor aluin1(4))) &
                                        ((aluin1(27) xnor aluin1(3)) or (aluin1(19) xor aluin1(3)) or (aluin1(11) xnor aluin1(3))) &
                                        ((aluin1(26) xnor aluin1(2)) or (aluin1(18) xor aluin1(2)) or (aluin1(10) xnor aluin1(2))) &
                                        ((aluin1(25) xnor aluin1(1)) or (aluin1(17) xor aluin1(1)) or (aluin1(9) xnor aluin1(1))) &
                                        ((aluin1(24) xnor aluin1(0)) or (aluin1(16) xor aluin1(0)) or (aluin1(8) xnor aluin1(0))) ;

            when "11101" =>
            	for idx_offset in 0 to 7 loop 
	                if 	((aluin1(24+idx_offset) /= aluin1(0+idx_offset)) and (aluin1(16+idx_offset) = aluin1(0+idx_offset)) and (aluin1(8+idx_offset) = not aluin1(0+idx_offset))) or
	                	((aluin1(24+idx_offset) = not aluin1(0+idx_offset)) and (aluin1(16+idx_offset) /= aluin1(0+idx_offset)) and (aluin1(8+idx_offset) = not aluin1(0+idx_offset))) or
	                	((aluin1(24+idx_offset) = not aluin1(0+idx_offset)) and (aluin1(16+idx_offset) = aluin1(0+idx_offset)) and (aluin1(8+idx_offset) /= aluin1(0+idx_offset))) then 
		                    shiftout(0+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(8+idx_offset) := not aluin1(0+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(24+idx_offset) := not aluin1(0+idx_offset);
	                elsif ((aluin1(24+idx_offset) = not aluin1(16+idx_offset)) and (aluin1(16+idx_offset) = not aluin1(8+idx_offset)) and (aluin1(16+idx_offset) /= aluin1(0+idx_offset))) then 
		                    shiftout(0+idx_offset) := aluin1(16+idx_offset);
		                    shiftout(8+idx_offset) := not aluin1(16+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(16+idx_offset);
		                    shiftout(24+idx_offset) := not aluin1(16+idx_offset);
		            else 
		                    shiftout(0+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(8+idx_offset) := not aluin1(0+idx_offset);
		                    shiftout(16+idx_offset) := aluin1(0+idx_offset);
		                    shiftout(24+idx_offset) := not aluin1(0+idx_offset);
		            end if;
		        end loop; 

	    when others =>
		shiftout := (others => '1');
	end case;
    when EXE_ANDC8 => shiftout := (aluin1(31 downto 24) or aluin2(31 downto 24)) & (aluin1(23 downto 16) and aluin2(23 downto 16)) & (aluin1(15 downto 8) or aluin2(15 downto 8)) & (aluin1(7 downto 0) and aluin2(7 downto 0));
    when EXE_ANDC16 => shiftout := (aluin1(31 downto 16) or aluin2(31 downto 16)) & (aluin1(15 downto 0) and aluin2(15 downto 0));
    when EXE_XORC8 => shiftout := (aluin1(31 downto 24) xnor aluin2(31 downto 24)) & (aluin1(23 downto 16) xor aluin2(23 downto 16)) & (aluin1(15 downto 8) xnor aluin2(15 downto 8)) & (aluin1(7 downto 0) xor aluin2(7 downto 0));
    when EXE_XORC16 => shiftout := (aluin1(31 downto 16) xnor aluin2(31 downto 16)) & (aluin1(15 downto 0) xor aluin2(15 downto 0));
    when EXE_XNORC8 => shiftout := (aluin1(31 downto 24) xor aluin2(31 downto 24)) & (aluin1(23 downto 16) xnor aluin2(23 downto 16)) & (aluin1(15 downto 8) xor aluin2(15 downto 8)) & (aluin1(7 downto 0) xnor aluin2(7 downto 0));
    when EXE_XNORC16 => shiftout := (aluin1(31 downto 16) xor aluin2(31 downto 16)) & (aluin1(15 downto 0) xnor aluin2(15 downto 0));
    when others => shiftout := shift(r, aluin1, aluin2, shcnt, sari);
    end case;
    shiftres := shiftout;
  end;
  
  
  
  function st_align(size : std_logic_vector(1 downto 0); bpdata : word) return word is
  variable edata : word;
  begin
    case size is
    when "01"   => edata := bpdata(7 downto 0) & bpdata(7 downto 0) &
                             bpdata(7 downto 0) & bpdata(7 downto 0);
    when "10"   => edata := bpdata(15 downto 0) & bpdata(15 downto 0);
    when others    => edata := bpdata;
    end case;
    return(edata);
  end;

  procedure misc_op(r : registers; wpr : watchpoint_registers; 
        aluin1, aluin2, ldata, mey : word; 
        mout, edata : out word) is
  variable miscout, bpdata, stdata : word;
  variable wpi : integer;
  begin
    wpi := 0; miscout := r.e.ctrl.pc(31 downto 2) & "00"; 
    edata := aluin1; bpdata := aluin1;
    if ((r.x.ctrl.wreg and r.x.ctrl.ld and not r.x.ctrl.annul) = '1') and
       (r.x.ctrl.rd = r.e.ctrl.rd) and (r.e.ctrl.inst(31 downto 30) = LDST) and
        (r.e.ctrl.cnt /= "10")
    then bpdata := ldata; end if;

    case r.e.aluop is
    when EXE_STB   => miscout := bpdata(7 downto 0) & bpdata(7 downto 0) &
                             bpdata(7 downto 0) & bpdata(7 downto 0);
                      edata := miscout;
    when EXE_STH   => miscout := bpdata(15 downto 0) & bpdata(15 downto 0);
                      edata := miscout;
    when EXE_PASS1 => miscout := bpdata; edata := miscout;
    when EXE_PASS2 => miscout := aluin2;
    when EXE_ONES  => miscout := (others => '1');
                      edata := miscout;
    when EXE_RDY  => 
      if MULEN and (r.m.ctrl.wy = '1') then miscout := mey;
      else miscout := r.m.y; end if;
      if (NWP > 0) and (r.e.ctrl.inst(18 downto 17) = "11") then
        wpi := conv_integer(r.e.ctrl.inst(16 downto 15));
        if r.e.ctrl.inst(14) = '0' then miscout := wpr(wpi).addr & '0' & wpr(wpi).exec;
        else miscout := wpr(wpi).mask & wpr(wpi).load & wpr(wpi).store; end if;
      end if;
      if (r.e.ctrl.inst(18 downto 17) = "10") and (r.e.ctrl.inst(14) = '1') then --%ASR17
        miscout := asr17_gen(r);
      end if;

      if MACEN then
        if (r.e.ctrl.inst(18 downto 14) = "10010") then --%ASR18
          if ((r.m.mac = '1') and not MACPIPE) or ((r.x.mac = '1') and MACPIPE) then
            miscout := mulo.result(31 downto 0);        -- data forward of asr18
          else miscout := r.w.s.asr18; end if;
        else
          if ((r.m.mac = '1') and not MACPIPE) or ((r.x.mac = '1') and MACPIPE) then
            miscout := mulo.result(63 downto 32);   -- data forward Y
          end if;
        end if;
      end if;
	  
	  if (r.e.ctrl.inst(18 downto 14) = "10100") then -- bilgiday asr20
	    miscout := invalid_bufcnt_w & r.x.ld0 & r.x.pv0 & r.x.annul0 & r.x.branch0 & r.w.wicc0 & r.w.ld0 & r.w.pv0 & r.w.annul0 & r.w.branch0 & r.w.rdest0 & r.w.wreg0 & bufcnt & "0000" & r.w.inst0 & r.w.s.cwp0 & r.w.s.icc0 & invalid_bufcnt_x;
	  end if;
	  
	  if (r.e.ctrl.inst(18 downto 14) = "10101") then -- bilgiday asr21
	    miscout := invalid_bufcnt_w & r.x.ld1 & r.x.pv1 & r.x.annul1 & r.x.branch1 & r.w.wicc1 & r.w.ld1 & r.w.pv1 & r.w.annul1 & r.w.branch1 & r.w.rdest1 & r.w.wreg1 & bufcnt & "0000" & r.w.inst1 & r.w.s.cwp1 & r.w.s.icc1 & invalid_bufcnt_x;
	  end if;
	  
	  if (r.e.ctrl.inst(18 downto 14) = "10110") then -- bilgiday asr22 
--		   if (invalid_bufcnt_w = '1') then
--		     miscout := r.w.result0;
--		   else
--		     miscout := r.w.result1;
--		   end if;
	    miscout := r.w.pc0(31 downto 2) & "00";
	  end if;
	  
	  if (r.e.ctrl.inst(18 downto 14) = "10111") then -- bilgiday asr23
--		   if (invalid_bufcnt_w = '1') then
--		     miscout := r.w.result0;
--		   else
--		     miscout := r.w.result1;
--		   end if;
	    miscout := r.w.pc1(31 downto 2) & "00";
	  end if;
	  
	  if (r.e.ctrl.inst(18 downto 14) = "11100") then -- bilgiday asr28 for return pc0
            miscout := r.x.pc0(31 downto 2) & "00";
	  -- if (r.x.branch0 = '1') then -- delete till 2nd else
	    --  if (invalid_bufcnt_w = '1') then
	      --  miscout := r.w.pc0(31 downto 2) & "00";
 	    --  else		 
	    --    miscout := r.w.pc1(31 downto 2) & "00";
	    --  end if;
 	   -- else -- delete
--	      if (invalid_bufcnt_w = '0') then
--		   if (r.w.inst1 = "111") then -- ST
--		     miscout := r.w.pc1(31 downto 2) & "00";
--		   else
--		     miscout := r.x.pc0(31 downto 2) & "00";
--		   end if;
--	      else
--		   if (r.w.inst0 = "111") then -- ST
--		     miscout := r.w.pc0(31 downto 2) & "00";
--		   else
--		     miscout := r.x.pc0(31 downto 2) & "00";
--		   end if;
  --             end if;
	   -- end if; -- delete
	  end if;

	  if (r.e.ctrl.inst(18 downto 14) = "11101") then -- bilgiday asr29 for return pc1
		     miscout := r.x.pc1(31 downto 2) & "00";
	  -- if (r.x.branch1 = '1') then
	  --    if (invalid_bufcnt_w = '1') then
	  --      miscout := r.w.pc0(31 downto 2) & "00";
 	  --    else		 
	  --      miscout := r.w.pc1(31 downto 2) & "00";
	  --    end if;
 	  --  else
--	      if (invalid_bufcnt_w = '0') then
--		   if (r.w.inst1 = "111") then -- ST
--		     miscout := r.w.pc1(31 downto 2) & "00";
--		   else
--		     miscout := r.x.pc1(31 downto 2) & "00";
--		   end if;
--	      else
--		   if (r.w.inst0 = "111") then -- ST
--		     miscout := r.w.pc0(31 downto 2) & "00";
--		   else
--		     miscout := r.x.pc1(31 downto 2) & "00";
--		   end if;
  --             end if;
	  -- end if;
	  end if;
	  
	  --if (r.e.ctrl.inst(18 downto 14) = "11101") then -- bilgiday asr29 for return pc1
	   -- miscout := r.x.pc1(31 downto 2) & "00";
	  --end if;
	  
    when EXE_SPR  => 
      miscout := get_spr(r);
    when others => null;
    end case;
    mout := miscout;
  end;

  procedure alu_select(r : registers; addout : std_logic_vector(32 downto 0);
        op1, op2 : word; shiftout, logicout, miscout : word; res : out word; 
        me_icc : std_logic_vector(3 downto 0);
        icco : out std_logic_vector(3 downto 0); divz, mzero : out std_ulogic) is
  variable op : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable icc : std_logic_vector(3 downto 0);
  variable aluresult : word;
  variable azero : std_logic;
  begin
    op   := r.e.ctrl.inst(31 downto 30); op3  := r.e.ctrl.inst(24 downto 19);
    icc := (others => '0');
    if addout(32 downto 1) = zero32 then azero := '1'; else azero := '0'; end if;
    mzero := azero;
    case r.e.alusel is
    when EXE_RES_ADD => 
      aluresult := addout(32 downto 1);
      if r.e.aluadd = '0' then
        icc(0) := ((not op1(31)) and not op2(31)) or    -- Carry
                 (addout(32) and ((not op1(31)) or not op2(31)));
        icc(1) := (op1(31) and (op2(31)) and not addout(32)) or         -- Overflow
                 (addout(32) and (not op1(31)) and not op2(31));
      else
        icc(0) := (op1(31) and op2(31)) or      -- Carry
                 ((not addout(32)) and (op1(31) or op2(31)));
        icc(1) := (op1(31) and op2(31) and not addout(32)) or   -- Overflow
                 (addout(32) and (not op1(31)) and (not op2(31)));
      end if;
      if notag = 0 then
        case op is 
        when FMT3 =>
          case op3 is
          when TADDCC | TADDCCTV =>
            icc(1) := op1(0) or op1(1) or op2(0) or op2(1) or icc(1);
          when TSUBCC | TSUBCCTV =>
            icc(1) := op1(0) or op1(1) or (not op2(0)) or (not op2(1)) or icc(1);
          when others => null;
          end case;
        when others => null;
        end case;
      end if;

--      if aluresult = zero32 then icc(2) := '1'; end if;
      icc(2) := azero;
    when EXE_RES_SHIFT => aluresult := shiftout;
    when EXE_RES_LOGIC => aluresult := logicout;
      if aluresult = zero32 then icc(2) := '1'; end if;
    when others => aluresult := miscout;
    end case;
    if r.e.jmpl = '1' then aluresult := r.e.ctrl.pc(31 downto 2) & "00"; end if;
    icc(3) := aluresult(31); divz := icc(2);
    if r.e.ctrl.wicc = '1' then
      if (op = FMT3) and (op3 = WRPSR) then icco := logicout(23 downto 20);
      elsif ((op = FMT3) and (op3 = WRY) and (r.e.ctrl.inst(29 downto 25) = "10110")) then -- bilgiday asr22-icc
        icco := r.w.s.icc0;
--        if (invalid_bufcnt_w = '1') then
--          icco := r.w.s.icc0;
--        else
--          icco := r.w.s.icc1;
--        end if;
      elsif ((op = FMT3) and (op3 = WRY) and (r.e.ctrl.inst(29 downto 25) = "10111")) then -- bilgiday asr23
        icco := r.w.s.icc1;
--        if (invalid_bufcnt_w = '1') then
--          icco := r.w.s.icc0;
--        else
--          icco := r.w.s.icc1;
--        end if;
      else icco := icc; end if;
    elsif r.m.ctrl.wicc = '1' then icco := me_icc;
    elsif r.x.ctrl.wicc = '1' then icco := r.x.icc;
    else icco := r.w.s.icc; end if;
    res := aluresult;
  end;

  procedure dcache_gen(r, v : registers; dci : out dc_in_type; 
        link_pc, jump, force_a2, load, mcasa : out std_ulogic) is
  variable op : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable su, lock : std_ulogic;
  begin
    op := r.e.ctrl.inst(31 downto 30); op3 := r.e.ctrl.inst(24 downto 19);
    dci.signed := '0'; dci.lock := '0'; dci.dsuen := '0'; dci.size := SZWORD;
    mcasa := '0';
    if op = LDST then
    case op3 is
      when LDUB | LDUBA => dci.size := SZBYTE;
      when LDSTUB | LDSTUBA => dci.size := SZBYTE; dci.lock := '1'; 
      when LDUH | LDUHA => dci.size := SZHALF;
      when LDSB | LDSBA => dci.size := SZBYTE; dci.signed := '1';
      when LDSH | LDSHA => dci.size := SZHALF; dci.signed := '1';
      when LD | LDA | LDF | LDC => dci.size := SZWORD;
      when SWAP | SWAPA => dci.size := SZWORD; dci.lock := '1'; 
      when CASA => if CASAEN then dci.size := SZWORD; dci.lock := '1'; end if;
      when LDD | LDDA | LDDF | LDDC => dci.size := SZDBL;
      when STB | STBA => dci.size := SZBYTE;
      when STH | STHA => dci.size := SZHALF;
      when ST | STA | STF => dci.size := SZWORD;
      when ISTD | STDA => dci.size := SZDBL;
      when STDF | STDFQ => if FPEN then dci.size := SZDBL; end if;
      when STDC | STDCQ => if CPEN then dci.size := SZDBL; end if;
      when others => dci.size := SZWORD; dci.lock := '0'; dci.signed := '0';
    end case;
    end if;

    link_pc := '0'; jump:= '0'; force_a2 := '0'; load := '0';
    dci.write := '0'; dci.enaddr := '0'; dci.read := not op3(2);

-- load/store control decoding

    if (r.e.ctrl.annul or r.e.ctrl.trap) = '0' then
      case op is
      when CALL => link_pc := '1';
      when FMT3 =>
        if r.e.ctrl.trap = '0' then
          case op3 is
          when JMPL => jump := '1'; link_pc := '1'; 
          when RETT => jump := '1';
          when others => null;
          end case;
        end if;
      when LDST =>
           if (op3 /= ANDC8 and op3 /= ANDC16 and op3 /= XORC8 and op3 /= XORC16 and op3 /= XNORC8 and op3 /= XNORC16) then  
          case r.e.ctrl.cnt is
          when "00" =>
            dci.read := op3(3) or not op3(2);   -- LD/LDST/SWAP/CASA
            load := op3(3) or not op3(2);
            --dci.enaddr := '1';
            dci.enaddr := (not op3(2)) or op3(2)
                          or (op3(3) and op3(2));
          when "01" =>
            force_a2 := not op3(2);     -- LDD
            load := not op3(2); dci.enaddr := not op3(2);
            if op3(3 downto 2) = "01" then              -- ST/STD
              dci.write := '1';              
            end if;
            if (CASAEN and (op3(5 downto 4) = "11")) or -- CASA
                (op3(3 downto 2) = "11") then           -- LDST/SWAP
              dci.enaddr := '1';
            end if;
          when "10" =>                                  -- STD/LDST/SWAP/CASA
            dci.write := '1';
          when others => null;
          end case;
          if (r.e.ctrl.trap or (v.x.ctrl.trap and not v.x.ctrl.annul)) = '1' then 
            dci.enaddr := '0';
          end if;
          if (CASAEN and (op3(5 downto 4) = "11")) then mcasa := '1'; end if;
	  end if; 
      when others => null;
      end case;
    end if;

    if ((r.x.ctrl.rett and not r.x.ctrl.annul) = '1') then su := r.w.s.ps;
    else su := r.w.s.s; end if;
    if su = '1' then dci.asi := "00001011"; else dci.asi := "00001010"; end if;
    if (op3(4) = '1') and ((op3(5) = '0') or not CPEN) then
      dci.asi := r.e.ctrl.inst(12 downto 5);
    end if;

  end;

  procedure fpstdata(r : in registers; edata, eres : in word; fpstdata : in std_logic_vector(31 downto 0);
                       edata2, eres2 : out word) is
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
  begin
    edata2 := edata; eres2 := eres;
    op := r.e.ctrl.inst(31 downto 30); op3 := r.e.ctrl.inst(24 downto 19);
   
    if (op3 /= ANDC8 and op3 /= ANDC16 and op3 /= XORC8 and op3 /= XORC16 and op3 /= XNORC8 and op3 /= XNORC16) then 

    if FPEN then
      if FPEN and (op = LDST) and  ((op3(5 downto 4) & op3(2)) = "101") and (r.e.ctrl.cnt /= "00") then
        edata2 := fpstdata; eres2 := fpstdata;
      end if;
    end if;
    if CASAEN and (r.m.casa = '1') and (r.e.ctrl.cnt = "10") then
      edata2 := r.e.op1; eres2 := r.e.op1;
    end if;
    end if;  
  end;
  
  function ld_align(data : dcdtype; set : std_logic_vector(DSETMSB downto 0);
        size, laddr : std_logic_vector(1 downto 0); signed : std_ulogic) return word is
  variable align_data, rdata : word;
  begin
    align_data := data(conv_integer(set)); rdata := (others => '0');
    case size is
    when "00" =>                        -- byte read
      case laddr is
      when "00" => 
        rdata(7 downto 0) := align_data(31 downto 24);
        if signed = '1' then rdata(31 downto 8) := (others => align_data(31)); end if;
      when "01" => 
        rdata(7 downto 0) := align_data(23 downto 16);
        if signed = '1' then rdata(31 downto 8) := (others => align_data(23)); end if;
      when "10" => 
        rdata(7 downto 0) := align_data(15 downto 8);
        if signed = '1' then rdata(31 downto 8) := (others => align_data(15)); end if;
      when others => 
        rdata(7 downto 0) := align_data(7 downto 0);
        if signed = '1' then rdata(31 downto 8) := (others => align_data(7)); end if;
      end case;
    when "01" =>                        -- half-word read
      if  laddr(1) = '1' then 
        rdata(15 downto 0) := align_data(15 downto 0);
        if signed = '1' then rdata(31 downto 15) := (others => align_data(15)); end if;
      else
        rdata(15 downto 0) := align_data(31 downto 16);
        if signed = '1' then rdata(31 downto 15) := (others => align_data(31)); end if;
      end if;
    when others =>                      -- single and double word read
      rdata := align_data;
    end case;
    return(rdata);
  end;

  
  procedure mem_trap(r : registers; wpr : watchpoint_registers;
                     annul, holdn : in std_ulogic;
                     trapout, iflush, nullify, werrout : out std_ulogic;
                     tt : out std_logic_vector(5 downto 0)) is
  variable cwp   : std_logic_vector(NWINLOG2-1 downto 0);
  variable cwpx  : std_logic_vector(5 downto NWINLOG2);
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable nalign_d : std_ulogic;
  variable trap, werr : std_ulogic;
  begin
    op := r.m.ctrl.inst(31 downto 30); op2  := r.m.ctrl.inst(24 downto 22);
    op3 := r.m.ctrl.inst(24 downto 19);
    cwpx := r.m.result(5 downto NWINLOG2); cwpx(5) := '0';
    iflush := '0'; trap := r.m.ctrl.trap; nullify := annul;
    tt := r.m.ctrl.tt; werr := (dco.werr or r.m.werr) and not r.w.s.dwt;
    nalign_d := r.m.nalign or r.m.result(2); 
    if (trap = '1') and (r.m.ctrl.pv = '1') then
      if op = LDST then nullify := '1'; end if;
    end if;
    if ((annul or trap) /= '1') and (r.m.ctrl.pv = '1') then
      if (werr and holdn) = '1' then
        trap := '1'; tt := TT_DSEX; werr := '0';
        if op = LDST then nullify := '1'; end if;
      end if;
    end if;
    if ((annul or trap) /= '1') then      
      case op is
      when FMT2 =>
        case op2 is
        when FBFCC => 
          if FPEN and (fpo.exc = '1') then trap := '1'; tt := TT_FPEXC; end if;
        when CBCCC =>
          if CPEN and (cpo.exc = '1') then trap := '1'; tt := TT_CPEXC; end if;
        when others => null;
        end case;
      when FMT3 =>
        case op3 is
        when WRPSR =>
          if (orv(cwpx) = '1') then trap := '1'; tt := TT_IINST; end if;
        when UDIV | SDIV | UDIVCC | SDIVCC =>
          if DIVEN then 
            if r.m.divz = '1' then trap := '1'; tt := TT_DIV; end if;
          end if;
        when JMPL | RETT =>
          if r.m.nalign = '1' then trap := '1'; tt := TT_UNALA; end if;
        when TADDCCTV | TSUBCCTV =>
          if (notag = 0) and (r.m.icc(1) = '1') then
            trap := '1'; tt := TT_TAG;
          end if;
        when FLUSH => iflush := '1';
        when FPOP1 | FPOP2 =>
          if FPEN and (fpo.exc = '1') then trap := '1'; tt := TT_FPEXC; end if;
        when CPOP1 | CPOP2 =>
          if CPEN and (cpo.exc = '1') then trap := '1'; tt := TT_CPEXC; end if;
        when others => null;
        end case;
      when LDST =>
        if r.m.ctrl.cnt = "00" then
          case op3 is
            when LDDF | STDF | STDFQ =>
            if FPEN then
              if nalign_d = '1' then
                trap := '1'; tt := TT_UNALA; nullify := '1';
              elsif (fpo.exc and r.m.ctrl.pv) = '1' 
              then trap := '1'; tt := TT_FPEXC; nullify := '1'; end if;
            end if;
          when LDDC | STDC | STDCQ =>
            if CPEN then
              if nalign_d = '1' then
                trap := '1'; tt := TT_UNALA; nullify := '1';
              elsif ((cpo.exc and r.m.ctrl.pv) = '1') 
              then trap := '1'; tt := TT_CPEXC; nullify := '1'; end if;
            end if;
          when LDD | ISTD | LDDA | STDA =>
            if r.m.result(2 downto 0) /= "000" then
              trap := '1'; tt := TT_UNALA; nullify := '1';
            end if;
          when LDF | LDFSR | STFSR | STF =>
            if FPEN and (r.m.nalign = '1') then
              trap := '1'; tt := TT_UNALA; nullify := '1';
            elsif FPEN and ((fpo.exc and r.m.ctrl.pv) = '1')
            then trap := '1'; tt := TT_FPEXC; nullify := '1'; end if;
          when LDC | LDCSR | STCSR | STC =>
            if CPEN and (r.m.nalign = '1') then 
              trap := '1'; tt := TT_UNALA; nullify := '1';
            elsif CPEN and ((cpo.exc and r.m.ctrl.pv) = '1') 
            then trap := '1'; tt := TT_CPEXC; nullify := '1'; end if;
          when LD | LDA | ST | STA | SWAP | SWAPA | CASA =>
            if r.m.result(1 downto 0) /= "00" then
              trap := '1'; tt := TT_UNALA; nullify := '1';
            end if;
          when LDUH | LDUHA | LDSH | LDSHA | STH | STHA =>
            if r.m.result(0) /= '0' then
              trap := '1'; tt := TT_UNALA; nullify := '1';
            end if;
          when others => null;
          end case;
          for i in 1 to NWP loop
            if ((((wpr(i-1).load and not op3(2)) or (wpr(i-1).store and op3(2))) = '1') and
                (((wpr(i-1).addr xor r.m.result(31 downto 2)) and wpr(i-1).mask) = zero32(31 downto 2)))
            then trap := '1'; tt := TT_WATCH; nullify := '1'; end if;
          end loop;
        end if;
      when others => null;
      end case;
    end if;
    if (rstn = '0') or (r.x.rstate = dsu2) then werr := '0'; end if;
    trapout := trap; werrout := werr;
  end;

  procedure irq_trap(r       : in registers;
                     ir      : in irestart_register;
                     irl     : in std_logic_vector(3 downto 0);
                     annul   : in std_ulogic;
                     pv      : in std_ulogic;
                     trap    : in std_ulogic;
                     tt      : in std_logic_vector(5 downto 0);
                     nullify : in std_ulogic;
                     irqen   : out std_ulogic;
                     irqen2  : out std_ulogic;
                     nullify2 : out std_ulogic;
                     trap2, ipend  : out std_ulogic;
                     tt2      : out std_logic_vector(5 downto 0)) is
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable pend : std_ulogic;
  begin
    nullify2 := nullify; trap2 := trap; tt2 := tt; 
    op := r.m.ctrl.inst(31 downto 30); op3 := r.m.ctrl.inst(24 downto 19);
    irqen := '1'; irqen2 := r.m.irqen;

    if (annul or trap) = '0' then
      if ((op = FMT3) and (op3 = WRPSR)) then irqen := '0'; end if;    
    end if;

    if (irl = "1111") or (irl > r.w.s.pil) then
      pend := r.m.irqen and r.m.irqen2 and r.w.s.et and not ir.pwd
      ;
    else pend := '0'; end if;
    ipend := pend;

    if ((not annul) and pv and (not trap) and pend) = '1' then
      trap2 := '1'; tt2 := "01" & irl;
      if op = LDST then nullify2 := '1'; end if;
    end if;
  end;

  procedure irq_intack(r : in registers; holdn : in std_ulogic; intack: out std_ulogic) is 
  begin
    intack := '0';
    if r.x.rstate = trap then 
     -- if r.w.s.tt(7 downto 4) = "0001" then intack := '1'; end if;
      if r.w.s.tt(7 downto 4) = "0001" then intack := '0'; end if; -- bilgiday
    end if;
  end;
  
-- write special registers

  procedure sp_write (r : registers; wpr : watchpoint_registers;
        s : out special_register_type; vwpr : out watchpoint_registers) is
  variable op : std_logic_vector(1 downto 0);
  variable op2 : std_logic_vector(2 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  variable rd  : std_logic_vector(4 downto 0);
  variable i   : integer range 0 to 3;
  begin

    op  := r.x.ctrl.inst(31 downto 30);
    op2 := r.x.ctrl.inst(24 downto 22);
    op3 := r.x.ctrl.inst(24 downto 19);
    s   := r.w.s;
    rd  := r.x.ctrl.inst(29 downto 25);
    vwpr := wpr;
    
      case op is
      when FMT3 =>
        case op3 is
        when WRY =>
          if rd = "00000" then
            s.y := r.x.result;
          elsif MACEN and (rd = "10010") then
            s.asr18 := r.x.result;
          elsif (rd = "10001") then
            if bp = 2 then s.dbp := r.x.result(27); end if;
            s.dwt := r.x.result(14);
            if (svt = 1) then s.svt := r.x.result(13); end if;
          elsif rd(4 downto 3) = "11" then -- %ASR24 - %ASR31
            case rd(2 downto 0) is
            when "000" => 
              vwpr(0).addr := r.x.result(31 downto 2);
              vwpr(0).exec := r.x.result(0); 
            when "001" => 
              vwpr(0).mask := r.x.result(31 downto 2);
              vwpr(0).load := r.x.result(1);
              vwpr(0).store := r.x.result(0);              
            when "010" => 
              vwpr(1).addr := r.x.result(31 downto 2);
              vwpr(1).exec := r.x.result(0); 
            when "011" => 
              vwpr(1).mask := r.x.result(31 downto 2);
              vwpr(1).load := r.x.result(1);
              vwpr(1).store := r.x.result(0);              
            when "100" => -- bilgiday ASR28 ping pong buffer 0 for return pc
              vwpr(2).addr := zero32(31 downto 2);
              vwpr(2).exec := zero32(0); 
            when "101" => -- bilgiday ASR29 ping pong buffer 1 for return pc
              vwpr(2).mask := zero32(31 downto 2);
              vwpr(2).load := zero32(1);
              vwpr(2).store := zero32(0);              
            when "110" => 
              vwpr(3).addr := zero32(31 downto 2);
              vwpr(3).exec := zero32(0); 
            when others =>   -- "111"
              vwpr(3).mask := zero32(31 downto 2);
              vwpr(3).load := zero32(1);
              vwpr(3).store := zero32(0);              
            end case;
          end if;
        when WRPSR =>
          s.cwp := r.x.result(NWINLOG2-1 downto 0);
          s.icc := r.x.result(23 downto 20);
          s.ec  := r.x.result(13);
          if FPEN then s.ef  := r.x.result(12); end if;
          s.pil := r.x.result(11 downto 8);
          s.s   := r.x.result(7);
          s.ps  := r.x.result(6);
          s.et  := r.x.result(5);
        when WRWIM =>
          s.wim := r.x.result(NWIN-1 downto 0);
        when WRTBR =>
          s.tba := r.x.result(31 downto 12);
        when SAVE =>
          if (not CWPOPT) and (r.w.s.cwp = CWPMIN) then s.cwp := CWPMAX;
          else s.cwp := r.w.s.cwp - 1 ; end if;
        when RESTORE =>
          if (not CWPOPT) and (r.w.s.cwp = CWPMAX) then s.cwp := CWPMIN;
          else s.cwp := r.w.s.cwp + 1; end if;
        when RETT =>
          if (not CWPOPT) and (r.w.s.cwp = CWPMAX) then s.cwp := CWPMIN;
          else s.cwp := r.w.s.cwp + 1; end if;
          s.s := r.w.s.ps;
          s.et := '1';
        when others => null;
        end case;
      when others => null;
      end case;
      if r.x.ctrl.wicc = '1' then s.icc := r.x.icc; end if;
      if r.x.ctrl.wy = '1' then s.y := r.x.y; end if;
      if MACPIPE and (r.x.mac = '1') then 
        s.asr18 := mulo.result(31 downto 0);
        s.y := mulo.result(63 downto 32);
      end if;
  end;

  function npc_find (r : registers) return std_logic_vector is
  variable npc : std_logic_vector(2 downto 0);
  begin
    npc := "011";
    if r.m.ctrl.pv = '1' then npc := "000";
    elsif r.e.ctrl.pv = '1' then npc := "001";
    elsif r.a.ctrl.pv = '1' then npc := "010";
    elsif r.d.pv = '1' then npc := "011";
    elsif v8 /= 0 then npc := "100"; end if;
    return(npc);
  end;

  function npc_gen (r : registers) return word is
  --function npc_gen (r : registers; r.x.ctrl.pc : pctype) return word is -- bilgiday
  variable npc : std_logic_vector(31 downto 0);
  begin
    npc :=  r.a.ctrl.pc(31 downto 2) & "00";
    case r.x.npc is
    when "000" => npc(31 downto 2) := r.x.ctrl.pc(31 downto 2);
    when "001" => npc(31 downto 2) := r.m.ctrl.pc(31 downto 2);
    when "010" => npc(31 downto 2) := r.e.ctrl.pc(31 downto 2);
    when "011" => npc(31 downto 2) := r.a.ctrl.pc(31 downto 2);
    when others => 
        if v8 /= 0 then npc(31 downto 2) := r.d.pc(31 downto 2); end if;
    end case;
    return(npc);
  end;

  procedure mul_res(r : registers; asr18in : word; result, y, asr18 : out word; 
          icc : out std_logic_vector(3 downto 0)) is
  variable op  : std_logic_vector(1 downto 0);
  variable op3 : std_logic_vector(5 downto 0);
  begin
    op    := r.m.ctrl.inst(31 downto 30); op3   := r.m.ctrl.inst(24 downto 19);
    result := r.m.result; y := r.m.y; icc := r.m.icc; asr18 := asr18in;
    case op is
    when FMT3 =>
      case op3 is
      when UMUL | SMUL =>
        if MULEN then 
          result := mulo.result(31 downto 0);
          y := mulo.result(63 downto 32);
        end if;
      when UMULCC | SMULCC =>
        if MULEN then 
          result := mulo.result(31 downto 0); icc := mulo.icc;
          y := mulo.result(63 downto 32);
        end if;
      when UMAC | SMAC =>
        if MACEN and not MACPIPE then
          result := mulo.result(31 downto 0);
          asr18  := mulo.result(31 downto 0);
          y := mulo.result(63 downto 32);
        end if;
      when UDIV | SDIV =>
        if DIVEN then 
          result := divo.result(31 downto 0);
        end if;
      when UDIVCC | SDIVCC =>
        if DIVEN then 
          result := divo.result(31 downto 0); icc := divo.icc;
        end if;
      when others => null;
      end case;
    when others => null;
    end case;
  end;

  function powerdwn(r : registers; trap : std_ulogic; rp : pwd_register_type) return std_ulogic is
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable rd  : std_logic_vector(4 downto 0);
    variable pd  : std_ulogic;
  begin
    op := r.x.ctrl.inst(31 downto 30);
    op3 := r.x.ctrl.inst(24 downto 19);
    rd  := r.x.ctrl.inst(29 downto 25);    
    pd := '0';
    if (not (r.x.ctrl.annul or trap) and r.x.ctrl.pv) = '1' then
      if ((op = FMT3) and (op3 = WRY) and (rd = "10011")) then pd := '1'; end if;
      pd := pd or rp.pwd;
    end if;
    return(pd);
  end;
  
  ------------------------------------------
  
  signal dummy : std_ulogic;
  signal cpu_index : std_logic_vector(3 downto 0);
  signal disasen : std_ulogic;
  signal tclear0, tclear1, tclear2, tclear3 : std_logic; -- trigger support FAME
  signal ten0, ten1, ten2, ten3 : std_logic; -- trigger support FAME
  signal tcnt0, tcnt1, tcnt2, tcnt3 : std_logic_vector(7 downto 0); -- trigger support FAME

begin -- rtl architecture
  count_bil0 : entity work.count_bil port map(clk,rstn,cnten,bufcnt); -- bilgiday

  count_trig0 : entity work.count_trig port map(clk, rstn, tclear0, ten0, tcnt0); -- bilgiday_trigger_support
  count_trig1 : entity work.count_trig port map(clk, rstn, tclear1, ten1, tcnt1); -- bilgiday_trigger_support
  count_trig2 : entity work.count_trig port map(clk, rstn, tclear2, ten2, tcnt2); -- bilgiday_trigger_support
  count_trig3 : entity work.count_trig port map(clk, rstn, tclear3, ten3, tcnt3); -- bilgiday_trigger_support

  clkout <= clk;  -- FAME
  -- to disable alarm functionality 
  --alarm <= '0';
  -- else use the following
  alarm_aesenc <= alarmin(1);  -- FAME
  alarm_aesdec <= alarmin(2);  -- FAME
  alarm_emsensor <= alarmin(3);  -- FAME
  alarm_sensors <= alarmc or alarm_emsensor or alarm_aesenc or alarm_aesdec;  -- FAME
  alarm <= (alarm_sensors or alarm_reg) xor alarmin2;  -- FAME
  alarmout <= alarmin3 xor (alarm_sensors or alarm_reg);  -- FAME
  alarm1_emsensor <= alarm_emsensor;  -- FAME
  alarm2_aesenc <= alarm_aesenc;  -- FAME
  alarm3_aesdec <= alarm_aesdec;  -- FAME


  --chinmay_canary : entity work.canary port map(clk, rstn, alarmc); -- chinmay -- bilgiday: enable this to use old canary sensor
  chinmay_canary2 : entity work.canary2 port map(clk, rstn, calibr.r0, alarmc); -- chinmay -- bilgiday: calibration support, enable this to use configurable canary sensor

  BPRED <= '0' when bp = 0 else '1' when bp = 1 else not r.w.s.dbp;

  ten0 <= '1' when ((( r.f.pc(31 downto 2) & "00") = r.trigger.r0) and (r.trigger.cnt(7 downto 0) /= "00000000")) else '0'; --trigger_support_bilgiday
  ten1 <= '1' when ((( r.f.pc(31 downto 2) & "00") = r.trigger.r1) and (r.trigger.cnt(15 downto 8) /= "00000000")) else '0'; --trigger_support_bilgiday
  ten2 <= '1' when ((( r.f.pc(31 downto 2) & "00") = r.trigger.r2) and (r.trigger.cnt(23 downto 16) /= "00000000")) else '0'; --trigger_support_bilgiday
  ten3 <= '1' when ((( r.f.pc(31 downto 2) & "00") = r.trigger.r3) and (r.trigger.cnt(31 downto 24) /= "00000000")) else '0'; --trigger_support_bilgiday

  tclear0 <= '1' when ((( r.f.pc(31 downto 2) & "00") /= r.trigger.r0)) else '0'; --trigger_support_bilgiday
  tclear1 <= '1' when ((( r.f.pc(31 downto 2) & "00") /= r.trigger.r1)) else '0'; --trigger_support_bilgiday
  tclear2 <= '1' when ((( r.f.pc(31 downto 2) & "00") /= r.trigger.r2)) else '0'; --trigger_support_bilgiday
  tclear3 <= '1' when ((( r.f.pc(31 downto 2) & "00") /= r.trigger.r3)) else '0'; --trigger_support_bilgiday

  comb : process(bufcnt, alarm, -- FAME
				 ico, dco, rfo, r, wpr, ir, dsur, rstn, holdn, irqi, dbgi, fpo, cpo, tbo,
                 mulo, divo, dummy, rp, BPRED, 
				 tcnt0, tcnt1, tcnt2, tcnt3, boot_select, invalid_bufcnt_x, invalid_bufcnt_w, calibr, obsr, alarm_reg, alarm_sensors)--,   -- FAME
				 --srfo ) -- PK

  variable ce0 : std_ulogic;
  variable ce1 : std_ulogic;
  variable v    : registers;
  variable vobs	: observation_reg_type; -- bilgiday pipeline_read_support
  variable vcalib	: calibration_reg_type; -- bilgiday calibration support
  variable vp  : pwd_register_type;
  variable vwpr : watchpoint_registers;
  variable vdsu : dsu_registers;
  variable fe_pc, fe_npc :  std_logic_vector(31 downto PCLOW);
  variable npc  : std_logic_vector(31 downto PCLOW);
  variable de_raddr1, de_raddr2 : std_logic_vector(9 downto 0);
  variable de_rs2, de_rd : std_logic_vector(4 downto 0);
  variable de_hold_pc, de_branch, de_ldlock : std_ulogic;
  variable de_cwp, de_cwp2 : cwptype;
  variable de_inull : std_ulogic;
  variable de_ren1, de_ren2 : std_ulogic;
  variable de_wcwp : std_ulogic;
  variable de_inst : word;
  variable de_icc : std_logic_vector(3 downto 0);
  variable de_fbranch, de_cbranch : std_ulogic;
  variable de_rs1mod : std_ulogic;
  variable de_bpannul : std_ulogic;
  variable de_fins_hold : std_ulogic;
  variable de_iperr : std_ulogic;

  variable ra_op1, ra_op2 : word;
  variable ra_div : std_ulogic;
  variable ra_bpmiss : std_ulogic;
  variable ra_bpannul : std_ulogic;

  variable ex_jump, ex_link_pc : std_ulogic;
  variable ex_jump_address : pctype;
  variable ex_add_res : std_logic_vector(32 downto 0);
  variable ex_shift_res, ex_logic_res, ex_misc_res : word;
  variable ex_edata, ex_edata2 : word;
  variable ex_dci : dc_in_type;
  variable ex_force_a2, ex_load, ex_ymsb : std_ulogic;
  variable ex_op1, ex_op2, ex_result, ex_result2, ex_result3, mul_op2 : word;
  variable ex_shcnt : std_logic_vector(4 downto 0);
  variable ex_dsuen : std_ulogic;
  variable ex_ldbp2 : std_ulogic;
  variable ex_sari : std_ulogic;
  variable ex_bpmiss : std_ulogic;

  variable ex_cdata : std_logic_vector(31 downto 0);
  variable ex_mulop1, ex_mulop2 : std_logic_vector(32 downto 0);
  
  variable me_bp_res : word;
  variable me_inull, me_nullify, me_nullify2 : std_ulogic;
  variable me_iflush : std_ulogic;
  variable me_newtt : std_logic_vector(5 downto 0);
  variable me_asr18 : word;
  variable me_signed : std_ulogic;
  variable me_size, me_laddr : std_logic_vector(1 downto 0);
  variable me_icc : std_logic_vector(3 downto 0);

  
  variable xc_result : word;
  variable xc_df_result : word;
  variable xc_waddr : std_logic_vector(9 downto 0);
  --variable xc_exception, xc_wreg, xc_swreg : std_ulogic; -- PK added xc_swreg
  variable xc_exception, xc_wreg : std_ulogic; -- PK added xc_swreg
  variable xc_trap_address : pctype;
  variable xc_newtt, xc_vectt : std_logic_vector(7 downto 0);
  variable xc_trap : std_ulogic;
  variable xc_fpexack : std_ulogic;  
  variable xc_rstn, xc_halt : std_ulogic;
  
  variable diagdata : word;
  variable tbufi : tracebuf_in_type;
  variable dbgm : std_ulogic;
  variable fpcdbgwr : std_ulogic;
  variable vfpi : fpc_in_type;
  variable dsign : std_ulogic;
  variable pwrd, sidle : std_ulogic;
  variable vir : irestart_register;
  variable xc_dflushl  : std_ulogic;
  variable xc_dcperr : std_ulogic;
  variable st : std_ulogic;
  variable icnt, fcnt : std_ulogic;
  variable tbufcntx : std_logic_vector(TBUFBITS-1 downto 0);
  variable bpmiss : std_ulogic;
  
  begin

    -- cnten <= '0' when (r.x.rstate = trap) else v.w.s.et;
	if ((r.x.rstate = trap) or (holdn = '0')) then
	 cnten <= '0';
	else
	 cnten <= v.w.s.et and (not r.x.ctrl.rett) and (not r.w.rett);
	end if;
	
	if ((holdn = '0')) then
		ce0 := '0';
		ce1 := '0';
	elsif (v.x.rstate /= trap) then
    	ce0 := ((not alarm) and (not bufcnt)) and (v.w.s.et) and (not r.x.ctrl.rett) and (not r.w.rett);  -- bilgiday
    	ce1 := ((not alarm) and (bufcnt)) and (v.w.s.et) and (not r.x.ctrl.rett) and (not r.w.rett); -- bilgiday
    else
		ce0 := '0';
		ce1 := '0';
    end if;

    vcalib := calibr; -- bilgiday calibration support
    v := r; vwpr := wpr; vdsu := dsur; vp := rp;
    xc_fpexack := '0'; sidle := '0';
    fpcdbgwr := '0'; vir := ir; xc_rstn := rstn;
    v.w.rett := r.x.ctrl.rett;
	
	-- if (alarm = '1') then
		-- alarmout <= '1';
	-- else
		-- alarmout <= '0';
	-- end if;
	
	triggerout(3 downto 0) <= "0000";
    if ((tcnt0 = r.trigger.cnt(7 downto 0)) and (r.trigger.cnt(7 downto 0) /= "00000000")) then --trigger_support_bilgiday
        triggerout(0) <= '1';
    end if;
    if ((tcnt1 = r.trigger.cnt(15 downto 8)) and (r.trigger.cnt(15 downto 8) /= "00000000")) then --trigger_support_bilgiday
        triggerout(1) <= '1';
    end if;
    if ((tcnt2 = r.trigger.cnt(23 downto 16)) and (r.trigger.cnt(23 downto 16) /= "00000000")) then --trigger_support_bilgiday
        triggerout(2) <= '1';
    end if;
    if ((tcnt3 = r.trigger.cnt(31 downto 24)) and (r.trigger.cnt(31 downto 24) /= "00000000")) then --trigger_support_bilgiday
        triggerout(3) <= '1';
    end if;
    
-----------------------------------------------------------------------
-- EXCEPTION STAGE
-----------------------------------------------------------------------
	
    xc_exception := '0'; xc_halt := '0'; icnt := '0'; fcnt := '0';
    xc_waddr := (others => '0');
	-- FAME: ------------------------------------------------------------------
    -- xc_waddr(RFBITS-1 downto 0) := r.x.ctrl.rd(RFBITS-1 downto 0);
	
	if ((r.x.ctrl.inst(31 downto 30) = "10") and (r.x.ctrl.inst(24 downto 19) = WRY) and r.x.ctrl.inst(29 downto 25) = "10110") then -- bilgiday asr22
--		   if (invalid_bufcnt_w = '1') then
--	  	    xc_waddr(RFBITS-1 downto 0) := r.w.wa0;
--		   else
--	  	    xc_waddr(RFBITS-1 downto 0) := r.w.wa1;
--		   end if;
	  xc_waddr(RFBITS-1 downto 0) := r.w.wa0;
	elsif ((r.x.ctrl.inst(31 downto 30) = "10") and (r.x.ctrl.inst(24 downto 19) = WRY) and r.x.ctrl.inst(29 downto 25) = "10111")then -- bilgiday asr23
--		   if (invalid_bufcnt_w = '1') then
--	  	    xc_waddr(RFBITS-1 downto 0) := r.w.wa0;
--		   else
--	  	    xc_waddr(RFBITS-1 downto 0) := r.w.wa1;
--		   end if;
	  xc_waddr(RFBITS-1 downto 0) := r.w.wa1;
	else
	  xc_waddr(RFBITS-1 downto 0) := r.x.ctrl.rd(RFBITS-1 downto 0);
	end if;
    -- xc_trap := r.x.mexc or r.x.ctrl.trap;
	----------------------------------------------------------------------------
    xc_trap := r.x.mexc or r.x.ctrl.trap; -- bilgiday 
    v.x.nerror := rp.error; xc_dflushl := '0';

    if r.x.mexc = '1' then xc_vectt := "00" & TT_DAEX;
    elsif r.x.ctrl.tt = TT_TICC then
      xc_vectt := '1' & r.x.result(6 downto 0);
    else xc_vectt := "00" & r.x.ctrl.tt; end if;

    if r.w.s.svt = '0' then
      xc_trap_address(31 downto 2) := r.w.s.tba & xc_vectt & "00"; 
    else
      xc_trap_address(31 downto 2) := r.w.s.tba & "00000000" & "00"; 
    end if;
    xc_trap_address(2 downto PCLOW) := (others => '0');
    xc_wreg := '0'; v.x.annul_all := '0'; 
	
	-- FAME: ------------------------------------------------------------------
	if ((r.x.ctrl.inst(31 downto 30) = "10") and (r.x.ctrl.inst(24 downto 19) = WRY) and r.x.ctrl.inst(29 downto 25) = "10110") then -- bilgiday asr22
--		   if (invalid_bufcnt_w = '1') then
--	  	     xc_result := r.w.result0;
--		   else
--	  	     xc_result := r.w.result1;
--		   end if;
	  xc_result := r.w.result0;
	
	elsif ((r.x.ctrl.inst(31 downto 30) = "10") and (r.x.ctrl.inst(24 downto 19) = WRY) and r.x.ctrl.inst(29 downto 25) = "10111") then -- bilgiday asr23
--		   if (invalid_bufcnt_w = '1') then
--	  	     xc_result := r.w.result0;
--		   else
--	  	     xc_result := r.w.result1;
--		   end if;
	  xc_result := r.w.result1;
	--------------------------------------------------------------------------
	elsif (not r.x.ctrl.annul and r.x.ctrl.ld) = '1' then 
      if (lddel = 2) then 
        xc_result := ld_align(r.x.data, r.x.set, r.x.dci.size, r.x.laddr, r.x.dci.signed);
      else
        xc_result := r.x.data(0); 
      end if;
    elsif MACEN and MACPIPE and ((not r.x.ctrl.annul and r.x.mac) = '1') then
      xc_result := mulo.result(31 downto 0);
    else xc_result := r.x.result; 
	end if;
    xc_df_result := xc_result;

    
    if DBGUNIT
    then 
      dbgm := dbgexc(r, dbgi, xc_trap, xc_vectt);
      if (dbgi.dsuen and dbgi.dbreak) = '0'then v.x.debug := '0'; end if;
    else dbgm := '0'; v.x.debug := '0'; end if;
    if PWRD2 then pwrd := powerdwn(r, xc_trap, rp); else pwrd := '0'; end if;
    
    case r.x.rstate is
    when run =>
      if (dbgm 
      ) /= '0' then        
        v.x.annul_all := '1'; vir.addr := r.x.ctrl.pc;
        v.x.rstate := dsu1;
          v.x.debug := '1'; 
        v.x.npc := npc_find(r);
        vdsu.tt := xc_vectt; vdsu.err := dbgerr(r, dbgi, xc_vectt);
      elsif (pwrd = '1') and (ir.pwd = '0') then
        v.x.annul_all := '1'; vir.addr := r.x.ctrl.pc;
        v.x.rstate := dsu1; v.x.npc := npc_find(r); vp.pwd := '1';
      elsif (alarm and r.w.s.et) = '1' then -- bilgiday
		    xc_trap := '1';
	      xc_vectt := "01100000"; -- bilgiday
	      xc_trap_address(31 downto 2) := r.w.s.tba & xc_vectt & "00"; -- bilgiday
		-- HOLD_PP_BUFFERS = 1; -- bilgiday
        xc_exception := '1'; 
		-- xc_result := r.x.ctrl.pc(31 downto 2) & "00";
		    if (bufcnt = '1') then
		       xc_result := r.x.pc1(31 downto 2) & "00";
		    else
		       xc_result := r.x.pc0(31 downto 2) & "00";
		    end if;
        xc_wreg := '0'; v.w.s.tt := xc_vectt; v.w.s.ps := r.w.s.s;
        v.w.s.s := '1'; v.x.annul_all := '1'; v.x.rstate := trap;
        xc_waddr := (others => '0');
        xc_waddr(NWINLOG2 + 3  downto 0) :=  r.w.s.cwp & "0001";
        v.x.npc := npc_find(r);
        --fpexack(r, xc_fpexack);
        --if r.w.s.et = '0' then
        --v.x.rstate := dsu1; xc_wreg := '0'; vp.error := '1';
        --end if;
	  --elsif (alarm and not r.w.s.et) = '1' then -- bilgiday, hard-reset version
		--v.x.rstate := dsu2; xc_wreg := '0'; vp.error := '1'; xc_exception := '1'; v.x.annul_all := '1';
	  elsif (alarm and (not r.w.s.et)) = '1' then -- bilgiday, re-entrant version
	    --if (r.w.s.tt = "01100000") = '1' then -- bilgiday, re-entrant version
		  v.x.rstate := run; 
		  xc_wreg := '0';  
		  xc_exception := '1'; 
		  xc_trap := '1';
		  xc_vectt := "01100000"; -- bilgiday
	      xc_trap_address(31 downto 2) := r.w.s.tba & xc_vectt & "00";
		  v.x.annul_all := '1';
		  v.w.s.tt := xc_vectt;
		-- else
		  -- xc_wreg := r.x.ctrl.wreg;
          -- sp_write (r, wpr, v.w.s, vwpr);        
          -- vir.pwd := '0';
          -- if (r.x.ctrl.pv and not r.x.debug) = '1' then
            -- icnt := holdn;
            -- if (r.x.ctrl.inst(31 downto 30) = FMT3) and 
                  -- ((r.x.ctrl.inst(24 downto 19) = FPOP1) or 
                   -- (r.x.ctrl.inst(24 downto 19) = FPOP2))
            -- then fcnt := holdn; end if;
          -- end if;
		-- end if;
	  elsif (r.x.ctrl.annul or xc_trap) = '0' then
        xc_wreg := r.x.ctrl.wreg;
        sp_write (r, wpr, v.w.s, vwpr);        
        vir.pwd := '0';
        if (r.x.ctrl.pv and not r.x.debug) = '1' then
          icnt := holdn;
          if (r.x.ctrl.inst(31 downto 30) = FMT3) and 
                ((r.x.ctrl.inst(24 downto 19) = FPOP1) or 
                 (r.x.ctrl.inst(24 downto 19) = FPOP2))
          then fcnt := holdn; end if;
        end if;
      elsif ((not r.x.ctrl.annul) and xc_trap) = '1' then
        xc_exception := '1'; xc_result := r.x.ctrl.pc(31 downto 2) & "00";
        xc_wreg := '1'; v.w.s.tt := xc_vectt; v.w.s.ps := r.w.s.s;
        v.w.s.s := '1'; v.x.annul_all := '1'; v.x.rstate := trap;
        xc_waddr := (others => '0');
        xc_waddr(NWINLOG2 + 3  downto 0) :=  r.w.s.cwp & "0001";
        v.x.npc := npc_find(r);
        fpexack(r, xc_fpexack);
        if r.w.s.et = '0' then
--        v.x.rstate := dsu1; xc_wreg := '0'; vp.error := '1';
          xc_wreg := '0';
        end if;
      end if;
    when trap =>
      xc_result := npc_gen(r); xc_wreg := '1'; 
      xc_waddr := (others => '0');
      xc_waddr(NWINLOG2 + 3  downto 0) :=  r.w.s.cwp & "0010";
      --if alarm = '1' then -- bilgiday : hard-reset version
		--v.x.rstate := dsu2; xc_wreg := '0'; vp.error := '1'; v.w.s.et := '0';
	  if (r.w.s.tt = "01100000") then -- bilgiday : re-entrant version
	    v.w.s.et := '0';
	    if alarm = '1' then -- bilgiday : re-entrant version
		  v.x.rstate := trap; -- just stay in trap state w/o doing anything.
		  xc_wreg := '0'; 
		  --v.w.s.et := '1';
		  v.x.annul_all := '1';
		  xc_exception := '1';
		  xc_trap_address(31 downto 2) := r.w.s.tba & "01100000" & "00";
		  else
		    v.x.rstate := run;
          if (not CWPOPT) and (r.w.s.cwp = CWPMIN) then v.w.s.cwp := CWPMAX;
          else v.w.s.cwp := r.w.s.cwp - 1 ; end if;
		  end if;
    elsif r.w.s.et = '1' then
      -- if r.w.s.et = '1' then
        v.w.s.et := '0'; v.x.rstate := run;
        if (not CWPOPT) and (r.w.s.cwp = CWPMIN) then v.w.s.cwp := CWPMAX;
        else v.w.s.cwp := r.w.s.cwp - 1 ; end if;
    else
        v.x.rstate := dsu1; xc_wreg := '0'; vp.error := '1';
    end if;
    when dsu1 =>
      xc_exception := '1'; v.x.annul_all := '1';
      xc_trap_address(31 downto PCLOW) := r.f.pc;
      if DBGUNIT or PWRD2 or (smp /= 0)
      then 
        xc_trap_address(31 downto PCLOW) := ir.addr; 
        vir.addr := npc_gen(r)(31 downto PCLOW);
        v.x.rstate := dsu2;
      end if;
      if DBGUNIT then v.x.debug := r.x.debug; end if;
    when dsu2 =>      
      xc_exception := '1'; v.x.annul_all := '1';
      xc_trap_address(31 downto PCLOW) := r.f.pc;
      if DBGUNIT or PWRD2 or (smp /= 0)
      then
        sidle := (rp.pwd or rp.error) and ico.idle and dco.idle and not r.x.debug;
        if DBGUNIT then
          if dbgi.reset = '1' then 
            if smp /=0 then vp.pwd := not irqi.run; else vp.pwd := '0'; end if;
            vp.error := '0';
          end if;
          if (dbgi.dsuen and dbgi.dbreak) = '1'then v.x.debug := '1'; end if;
          diagwr(r, calibr, dsur, ir, dbgi, wpr, v.w.s, vwpr, vdsu.asi, xc_trap_address, -- bilgiday calibration support
          vir.addr, vdsu.tbufcnt, xc_wreg, xc_waddr, xc_result, v.trigger, vcalib, fpcdbgwr); --bilgiday_trigger_support, calibration
          xc_halt := dbgi.halt;
        end if;
        if r.x.ipend = '1' then vp.pwd := '0'; end if;
        if (rp.error or rp.pwd or r.x.debug or xc_halt) = '0' then
          v.x.rstate := run; v.x.annul_all := '0'; vp.error := '0';
          xc_trap_address(31 downto PCLOW) := ir.addr; v.x.debug := '0';
          vir.pwd := '1';
        end if;
        if (smp /= 0) and (irqi.rst = '1') then 
          vp.pwd := '0'; vp.error := '0'; 
        end if;
      end if;
    when others =>
    end case;

    dci.flushl <= xc_dflushl;
    
    irq_intack(r, holdn, v.x.intack);          
    itrace(r, dsur, vdsu, xc_result, xc_exception, dbgi, rp.error, xc_trap, tbufcntx, tbufi, '0', xc_dcperr);    
    vdsu.tbufcnt := tbufcntx;
	
    v.w.except := xc_exception; v.w.result := xc_result;
    if (r.x.rstate = dsu2) then v.w.except := '0'; end if;
    --v.w.wa := xc_waddr(RFBITS-1 downto 0); v.w.wreg := xc_wreg and holdn;
	v.w.wa := xc_waddr(RFBITS-1 downto 0); 
	v.w.wreg := xc_wreg and (alarm or holdn); --chinmay
	

    rfi.diag <= dco.testen & dco.scanen & "00";
    rfi.wdata <= xc_result; rfi.waddr <= xc_waddr;
	

    irqo.intack <= r.x.intack and holdn;
    irqo.irl <= r.w.s.tt(3 downto 0);
    irqo.pwd <= rp.pwd;
    irqo.fpen <= r.w.s.ef;
    irqo.idle <= '0';
    dbgo.halt <= xc_halt;
    dbgo.pwd  <= rp.pwd;
    dbgo.idle <= sidle;
    dbgo.icnt <= icnt;
    dbgo.fcnt <= fcnt;
    dbgo.optype <= r.x.ctrl.inst(31 downto 30) & r.x.ctrl.inst(24 downto 21);
    dci.intack <= r.x.intack and holdn;    
    
    if (not RESET_ALL) and (xc_rstn = '0') then 
      v.w.except := RRES.w.except; v.w.s.et := RRES.w.s.et;
      v.w.s.svt := RRES.w.s.svt; v.w.s.dwt := RRES.w.s.dwt;
      v.w.s.ef := RRES.w.s.ef;
      if need_extra_sync_reset(fabtech) /= 0 then 
        v.w.s.cwp := RRES.w.s.cwp;
        v.w.s.icc := RRES.w.s.icc;
      end if;
      v.w.s.dbp := RRES.w.s.dbp;
      v.x.ipmask := RRES.x.ipmask;
      v.w.s.tba := RRES.w.s.tba;
      v.x.annul_all := RRES.x.annul_all;
      v.x.rstate := RRES.x.rstate; vir.pwd := IRES.pwd; 
      vp.pwd := PRES.pwd; v.x.debug := RRES.x.debug; 
      v.x.nerror := RRES.x.nerror;
      if svt = 1 then v.w.s.tt := RRES.w.s.tt; end if;
      if DBGUNIT then
        if (dbgi.dsuen and dbgi.dbreak) = '1' then
          v.x.rstate := dsu1; v.x.debug := '1';
        end if;
      end if;
      if (index /= 0) and (irqi.run = '0') and (rstn = '0') then 
        v.x.rstate := dsu1; vp.pwd := '1'; 
      end if;
      v.x.npc := "100";
    end if;
    
    -- kill off unused regs
    if not FPEN then v.w.s.ef := '0'; end if;
    if not CPEN then v.w.s.ec := '0'; end if;
	
-----------------------------------------------------------------------
-- MEMORY STAGE
-----------------------------------------------------------------------

	v.x.op1 := r.m.op1; v.x.op2 := r.m.op2; 
    v.x.ctrl := r.m.ctrl; v.x.dci := r.m.dci;
    v.x.ctrl.rett := r.m.ctrl.rett and not r.m.ctrl.annul;
    v.x.mac := r.m.mac; v.x.laddr := r.m.result(1 downto 0);
    v.x.ctrl.annul := r.m.ctrl.annul or v.x.annul_all; 
    st := '0'; 
    
    if CASAEN and (r.m.casa = '1') and (r.m.ctrl.cnt = "00") then
      v.x.ctrl.inst(4 downto 0) := r.a.ctrl.inst(4 downto 0); -- restore rs2 for trace log
    end if;
	-- PK: selects the result of the mul / div
    mul_res(r, v.w.s.asr18, v.x.result, v.x.y, me_asr18, me_icc);


    mem_trap(r, wpr, v.x.ctrl.annul, holdn, v.x.ctrl.trap, me_iflush,
             me_nullify, v.m.werr, v.x.ctrl.tt);
    me_newtt := v.x.ctrl.tt;

    irq_trap(r, ir, irqi.irl, v.x.ctrl.annul, v.x.ctrl.pv, v.x.ctrl.trap, me_newtt, me_nullify,
             v.m.irqen, v.m.irqen2, me_nullify2, v.x.ctrl.trap,
             v.x.ipend, v.x.ctrl.tt);   

	v.x.ctrl.trap := v.x.ctrl.trap or alarm; -- bilgiday
	
    if (r.m.ctrl.ld or st or not dco.mds) = '1' then          
      for i in 0 to dsets-1 loop
        v.x.data(i) := dco.data(i);
      end loop;
      v.x.set := dco.set(DSETMSB downto 0); 
      if dco.mds = '0' then
        me_size := r.x.dci.size; me_laddr := r.x.laddr; me_signed := r.x.dci.signed;
      else
        me_size := v.x.dci.size; me_laddr := v.x.laddr; me_signed := v.x.dci.signed;
      end if;
      if (lddel /= 2) then
        v.x.data(0) := ld_align(v.x.data, v.x.set, me_size, me_laddr, me_signed);
      end if;
    end if;
    if (not RESET_ALL) and (is_fpga(fabtech) = 0) and (xc_rstn = '0') then
      v.x.data := (others => (others => '0')); --v.x.ldc := '0';
    end if;
    v.x.mexc := dco.mexc;

    v.x.icc := me_icc;
    v.x.ctrl.wicc := r.m.ctrl.wicc and not v.x.annul_all;
    
    if MACEN and ((v.x.ctrl.annul or v.x.ctrl.trap) = '0') then
      v.w.s.asr18 := me_asr18;
    end if;

    if (r.x.rstate = dsu2)
    then      
      me_nullify2 := '0'; v.x.set := dco.set(DSETMSB downto 0);
    end if;


    if (not RESET_ALL) and (xc_rstn = '0') then 
        v.x.ctrl.trap := '0'; v.x.ctrl.annul := '1';
    end if;
    
    dci.maddress <= r.m.result;
    dci.enaddr   <= r.m.dci.enaddr and (not alarm);
    dci.asi      <= r.m.dci.asi;
    dci.size     <= r.m.dci.size;
    dci.lock     <= (r.m.dci.lock and not r.m.ctrl.annul);
    dci.read     <= r.m.dci.read; -- bilgiday
    dci.write    <= r.m.dci.write and (not alarm);
    -- dci.flush    <= me_iflush;
    dci.flush    <= me_iflush; -- bilgiday
    dci.dsuen    <= r.m.dci.dsuen;
    dci.msu    <= r.m.su;
    dci.esu    <= r.e.su;
    dbgo.ipend <= v.x.ipend;
	
	-- if ((ce0 = '1') and (ce1 = '0')) then -- bilgiday
		  -- v.x.pc0 := v.x.ctrl.pc;
		  -- v.x.pc1 := r.x.pc1;
	-- elsif ((ce0 = '0') and (ce1 = '1')) then -- bilgiday 
		  -- v.x.pc1 := v.x.ctrl.pc;
		  -- v.x.pc0 := r.x.pc0;
	-- elsif ((ce0 = '0') and (ce1 = '0')) then -- bilgiday 
		  -- v.x.pc1 := r.x.pc1;
		  -- v.x.pc0 := r.x.pc0;
	-- end if;
    
-----------------------------------------------------------------------
-- EXECUTE STAGE
-----------------------------------------------------------------------

	v.m.op1 := r.e.op1; v.m.op2 := r.e.op2; 
    v.m.ctrl := r.e.ctrl; ex_op1 := r.e.op1; ex_op2 := r.e.op2;
    v.m.ctrl.rett := r.e.ctrl.rett and not r.e.ctrl.annul;
    v.m.ctrl.wreg := r.e.ctrl.wreg and not v.x.annul_all;
    ex_ymsb := r.e.ymsb; mul_op2 := ex_op2; ex_shcnt := r.e.shcnt;
    v.e.cwp := r.a.cwp; ex_sari := r.e.sari;
    v.m.su := r.e.su;
    if MULTYPE = 3 then v.m.mul := r.e.mul; else v.m.mul := '0'; end if;
    if lddel = 1 then
      if r.e.ldbp1 = '1' then 
        ex_op1 := r.x.data(0); 
        ex_sari := r.x.data(0)(31) and r.e.ctrl.inst(19) and r.e.ctrl.inst(20);
      end if;
      if r.e.ldbp2 = '1' then 
        ex_op2 := r.x.data(0); ex_ymsb := r.x.data(0)(0); 
        mul_op2 := ex_op2; ex_shcnt := r.x.data(0)(4 downto 0);
        if r.e.invop2 = '1' then 
          ex_op2 := not ex_op2; ex_shcnt := not ex_shcnt;
        end if;
      end if;
    end if;


    ex_add_res := (ex_op1 & '1') + (ex_op2 & r.e.alucin);

    if ex_add_res(2 downto 1) = "00" then v.m.nalign := '0';
    else v.m.nalign := '1'; end if;

    dcache_gen(r, v, ex_dci, ex_link_pc, ex_jump, ex_force_a2, ex_load, v.m.casa);
    ex_jump_address := ex_add_res(32 downto PCLOW+1);
    logic_op(r, ex_op1, ex_op2, v.x.y, ex_shift_res, ex_ymsb, ex_logic_res, v.m.y);
	-- PK
	shift_op(r, ex_op1, ex_op2, ex_shcnt, ex_sari, ex_shift_res);
	-----------------
    misc_op(r, wpr, ex_op1, ex_op2, xc_df_result, v.x.y, ex_misc_res, ex_edata);
    ex_add_res(3):= ex_add_res(3) or ex_force_a2;    
    alu_select(r, ex_add_res, ex_op1, ex_op2, ex_shift_res, ex_logic_res,
        ex_misc_res, ex_result, me_icc, v.m.icc, v.m.divz, v.m.casaz);    
    dbg_cache(holdn, dbgi, r, dsur, ex_result, ex_dci, ex_result2, v.m.dci);
    fpstdata(r, ex_edata, ex_result2, fpo.data, ex_edata2, ex_result3);
    v.m.result := ex_result3;
    cwp_ex(r, v.m.wcwp);    

    if CASAEN and (r.e.ctrl.cnt = "10") and ((r.m.casa and not v.m.casaz) = '1') then
      me_nullify2 := '1';
    end if;
    -- dci.nullify  <= me_nullify2; 
    dci.nullify  <= me_nullify2 or alarm; -- bilgiday

    ex_mulop1 := (ex_op1(31) and r.e.ctrl.inst(19)) & ex_op1;
    ex_mulop2 := (mul_op2(31) and r.e.ctrl.inst(19)) & mul_op2;

    if is_fpga(fabtech) = 0 and (r.e.mul = '0') then     -- power-save for mul
--    if (r.e.mul = '0') then
        ex_mulop1 := (others => '0'); ex_mulop2 := (others => '0');
    end if;

      
    v.m.ctrl.annul := v.m.ctrl.annul or v.x.annul_all;
    v.m.ctrl.wicc := r.e.ctrl.wicc and not v.x.annul_all; 
    v.m.mac := r.e.mac;
    if (DBGUNIT and (r.x.rstate = dsu2)) then v.m.ctrl.ld := '1'; end if;
    dci.eenaddr  <= v.m.dci.enaddr;
    dci.eaddress <= ex_add_res(32 downto 1);
    dci.edata <= ex_edata2;
    bp_miss_ex(r, r.m.icc, ex_bpmiss, ra_bpannul);
    
-----------------------------------------------------------------------
-- REGFILE STAGE
-----------------------------------------------------------------------

    v.e.ctrl := r.a.ctrl; v.e.jmpl := r.a.jmpl and not r.a.ctrl.trap;
    v.e.ctrl.annul := r.a.ctrl.annul or ra_bpannul or v.x.annul_all;
    v.e.ctrl.rett := r.a.ctrl.rett and not r.a.ctrl.annul and not r.a.ctrl.trap;
    v.e.ctrl.wreg := r.a.ctrl.wreg and not (ra_bpannul or v.x.annul_all);    
    v.e.su := r.a.su; v.e.et := r.a.et;
    v.e.ctrl.wicc := r.a.ctrl.wicc and not (ra_bpannul or v.x.annul_all);
    v.e.rfe1 := r.a.rfe1; v.e.rfe2 := r.a.rfe2;
    
    exception_detect(r, wpr, dbgi, r.a.ctrl.trap, r.a.ctrl.tt, 
                     v.e.ctrl.trap, v.e.ctrl.tt);
    op_mux(r, rfo.data1, ex_result3, v.x.result, xc_df_result, zero32, 
        r.a.rsel1, v.e.ldbp1, ra_op1, '0');
    op_mux(r, rfo.data2,  ex_result3, v.x.result, xc_df_result, r.a.imm, 
        r.a.rsel2, ex_ldbp2, ra_op2, '1');
    alu_op(r, ra_op1, ra_op2, v.m.icc, v.m.y(0), ex_ldbp2, v.e.op1, v.e.op2,
           v.e.aluop, v.e.alusel, v.e.aluadd, v.e.shcnt, v.e.sari, v.e.shleft,
           v.e.ymsb, v.e.mul, ra_div, v.e.mulstep, v.e.mac, v.e.ldbp2, v.e.invop2
    );
    cin_gen(r, v.m.icc(0), v.e.alucin);
    bp_miss_ra(r, ra_bpmiss, de_bpannul);
    v.e.bp := r.a.bp and not ra_bpmiss;
    
-----------------------------------------------------------------------
-- DECODE STAGE
-----------------------------------------------------------------------

    if ISETS > 1 then de_inst := r.d.inst(conv_integer(r.d.set));
    else de_inst := r.d.inst(0); end if;

    de_icc := r.m.icc; v.a.cwp := r.d.cwp;
    su_et_select(r, v.w.s.ps, v.w.s.s, v.w.s.et, v.a.su, v.a.et);
    wicc_y_gen(de_inst, v.a.ctrl.wicc, v.a.ctrl.wy);
    cwp_ctrl(r, v.w.s.wim, de_inst, de_cwp, v.a.wovf, v.a.wunf, de_wcwp);

    -- bilgiday: for correct cwp after trap
    if (de_inst(24 downto 19) = RETT and 
         r.w.s.tt = "01100000" and
         alarm = '1') then -- RETT is still in pipeline
      de_cwp := r.w.s.cwp;
    end if;
    --
    if CASAEN and (de_inst(31 downto 30) = LDST) and (de_inst(24 downto 19) = CASA) then
      case r.d.cnt is
      when "00" | "01" => de_inst(4 downto 0) := "00000"; -- rs2=0
      when others =>
      end case;
    end if;
    rs1_gen(r, de_inst, v.a.rs1, de_rs1mod); 
    de_rs2 := de_inst(4 downto 0);
    de_raddr1 := (others => '0'); de_raddr2 := (others => '0');
    
    if RS1OPT then
      if de_rs1mod = '1' then
        regaddr(r.d.cwp, de_inst(29 downto 26) & v.a.rs1(0), de_raddr1(RFBITS-1 downto 0));
      else
        regaddr(r.d.cwp, de_inst(18 downto 15) & v.a.rs1(0), de_raddr1(RFBITS-1 downto 0));
      end if;
    else
      regaddr(r.d.cwp, v.a.rs1, de_raddr1(RFBITS-1 downto 0));
    end if;
    regaddr(r.d.cwp, de_rs2, de_raddr2(RFBITS-1 downto 0));
    v.a.rfa1 := de_raddr1(RFBITS-1 downto 0); 
    v.a.rfa2 := de_raddr2(RFBITS-1 downto 0); 

    rd_gen(r, de_inst, v.a.ctrl.wreg, v.a.ctrl.ld, de_rd);  
	regaddr(de_cwp, de_rd, v.a.ctrl.rd);
    
    fpbranch(de_inst, fpo.cc, de_fbranch);
    fpbranch(de_inst, cpo.cc, de_cbranch);
    v.a.imm := imm_data(r, de_inst);
      de_iperr := '0';
    lock_gen(r, de_rs2, de_rd, v.a.rfa1, v.a.rfa2, v.a.ctrl.rd, de_inst, 
        fpo.ldlock, v.e.mul, ra_div, de_wcwp, v.a.ldcheck1, v.a.ldcheck2, de_ldlock, 
        v.a.ldchkra, v.a.ldchkex, v.a.bp, v.a.nobp, de_fins_hold, de_iperr);
    ic_ctrl(r, de_inst, v.x.annul_all, de_ldlock, branch_true(de_icc, de_inst), 
        de_fbranch, de_cbranch, fpo.ccv, cpo.ccv, v.d.cnt, v.d.pc, de_branch,
        v.a.ctrl.annul, v.d.annul, v.a.jmpl, de_inull, v.d.pv, v.a.ctrl.pv,
        de_hold_pc, v.a.ticc, v.a.ctrl.rett, v.a.mulstart, v.a.divstart, 
        ra_bpmiss, ex_bpmiss, de_iperr);

    v.a.bp := v.a.bp and not v.a.ctrl.annul;
    v.a.nobp := v.a.nobp and not v.a.ctrl.annul;

    v.a.ctrl.inst := de_inst;

    cwp_gen(r, v, v.a.ctrl.annul, de_wcwp, de_cwp, v.d.cwp);
    -- bilgiday: for correct cwp after trap
    if ((r.a.ctrl.rett or r.e.ctrl.rett or r.m.ctrl.rett or r.x.ctrl.rett) = '1' and 
         r.w.s.tt = "01100000" and
         alarm = '1') then -- RETT is still in pipeline
      v.d.cwp := r.w.s.cwp;
    end if;
    --       
    de_inull := de_inull or alarm; -- bilgiday: to solve bug
    v.d.inull := ra_inull_gen(r, v);
     
    
    op_find(r, v.a.ldchkra, v.a.ldchkex, v.a.rs1, v.a.rfa1, 
            false, v.a.rfe1, v.a.rsel1, v.a.ldcheck1);  
     

    op_find(r, v.a.ldchkra, v.a.ldchkex, de_rs2, v.a.rfa2, 
            imm_select(de_inst), v.a.rfe2, v.a.rsel2, v.a.ldcheck2);  


    v.a.ctrl.wicc := v.a.ctrl.wicc and (not v.a.ctrl.annul) 
    ;
    v.a.ctrl.wreg := v.a.ctrl.wreg and (not v.a.ctrl.annul) 
    ;
    v.a.ctrl.rett := v.a.ctrl.rett and (not v.a.ctrl.annul) 
    ;
    v.a.ctrl.wy := v.a.ctrl.wy and (not v.a.ctrl.annul) 
    ;

    v.a.ctrl.trap := r.d.mexc 
    ;
    v.a.ctrl.tt := "000000";
      if r.d.mexc = '1' then
        v.a.ctrl.tt := "000001";
      end if;
    v.a.ctrl.pc := r.d.pc;
    v.a.ctrl.cnt := r.d.cnt;
    v.a.step := r.d.step;
    
    if holdn = '0' then 
      de_raddr1(RFBITS-1 downto 0) := r.a.rfa1;
      de_raddr2(RFBITS-1 downto 0) := r.a.rfa2;
      de_ren1 := r.a.rfe1; de_ren2 := r.a.rfe2;
    else
      de_ren1 := v.a.rfe1; de_ren2 := v.a.rfe2;
    end if;

    if DBGUNIT then
      if (dbgi.denable = '1') and (r.x.rstate = dsu2) then        
        de_raddr1(RFBITS-1 downto 0) := dbgi.daddr(RFBITS+1 downto 2); de_ren1 := '1';
        de_raddr2 := de_raddr1; de_ren2 := '1';
      end if;
      v.d.step := dbgi.step and not r.d.annul;      
    end if;
	
    rfi.wren <= (xc_wreg and (alarm or holdn)) and not dco.scanen; --chinmay
    rfi.raddr1 <= de_raddr1; rfi.raddr2 <= de_raddr2;
    rfi.ren1 <= (de_ren1 and (not dco.scanen)) or (not rstn);
    rfi.ren2 <= (de_ren2 and (not dco.scanen)) or (not rstn);
    ici.inull <= de_inull
    ;
    ici.flush <= me_iflush;
    v.d.divrdy := divo.nready;
    ici.fline <= r.x.ctrl.pc(31 downto 3);
    dbgo.bpmiss <= bpmiss and holdn;
    if (xc_rstn = '0') then
      v.d.cnt := (others => '0');
      if need_extra_sync_reset(fabtech) /= 0 then 
        v.d.cwp := (others => '0');
      end if;
    end if;

-----------------------------------------------------------------------
-- FETCH STAGE
-----------------------------------------------------------------------

    bpmiss := ex_bpmiss or ra_bpmiss;
    npc := r.f.pc; fe_pc := r.f.pc;
    if ra_bpmiss = '1' then fe_pc := r.d.pc; end if;
    if ex_bpmiss = '1' then fe_pc := r.a.ctrl.pc; end if;
    fe_npc := zero32(31 downto PCLOW);
    fe_npc(31 downto 2) := fe_pc(31 downto 2) + 1;    -- Address incrementer

    if (xc_rstn = '0') then
      if (not RESET_ALL) then 
        v.f.pc := (others => '0'); v.f.branch := '0';
        if DYNRST then v.f.pc(31 downto 12) := irqi.rstvec;
        else
          v.f.pc(31 downto 12) := conv_std_logic_vector(rstaddr, 20);
          v.f.pc(28) := boot_select; -- bilgiday: selective boot
        end if;
      end if;
    elsif xc_exception = '1' then       -- exception
      v.f.branch := '1'; v.f.pc := xc_trap_address;
      npc := v.f.pc;
    elsif de_hold_pc = '1' then
      v.f.pc := r.f.pc; v.f.branch := r.f.branch;
      if bpmiss = '1' then
        v.f.pc := fe_npc; v.f.branch := '1';
        npc := v.f.pc;
      elsif ex_jump = '1' then
        v.f.pc := ex_jump_address; v.f.branch := '1';
        npc := v.f.pc;
      end if;
    elsif (ex_jump and not bpmiss) = '1' then
      v.f.pc := ex_jump_address; v.f.branch := '1';
      npc := v.f.pc;
    elsif (de_branch and not bpmiss
        ) = '1'
    then
      v.f.pc := branch_address(de_inst, r.d.pc); v.f.branch := '1';
      npc := v.f.pc;
    else
      v.f.branch := bpmiss; v.f.pc := fe_npc; npc := v.f.pc;
    end if;

    ici.dpc <= r.d.pc(31 downto 2) & "00";
    ici.fpc <= r.f.pc(31 downto 2) & "00";
    ici.rpc <= npc(31 downto 2) & "00";
    ici.fbranch <= r.f.branch;
    ici.rbranch <= v.f.branch;
    ici.su <= v.a.su;

    
    if (ico.mds and de_hold_pc) = '0' then
      for i in 0 to isets-1 loop
        v.d.inst(i) := ico.data(i);                     -- latch instruction
      end loop;
      v.d.set := ico.set(ISETMSB downto 0);             -- latch instruction
      v.d.mexc := ico.mexc;                             -- latch instruction

    end if;

-----------------------------------------------------------------------
-----------------------------------------------------------------------

    if DBGUNIT then -- DSU diagnostic read    
      diagread(dbgi, r, obsr, calibr, dsur, ir, wpr, dco, tbo, diagdata); -- bilgiday calibration observation support
      diagrdy(dbgi.denable, dsur, r.m.dci, dco.mds, ico, vdsu.crdy);
    end if;
    
-----------------------------------------------------------------------
-- OUTPUTS
-----------------------------------------------------------------------
	
   v.a.branch := r.f.branch;
   v.e.branch := r.a.branch;
   v.m.branch := r.e.branch;
   v.x.branch := r.m.branch;
   v.w.branch := r.x.branch;
   

   if ((ce0 = '1') and (ce1 = '0')) then -- bilgiday
      if(v.x.ctrl.annul = '0') then
		  v.x.pc0 := v.x.ctrl.pc;
		  v.x.pc1 := r.x.pc1;
		  v.x.wicc0 := v.x.ctrl.wicc;
		  v.x.wicc1 := r.x.wicc1;
		  v.x.ld0 := v.x.ctrl.ld;
		  v.x.ld1 := r.x.ld1;
		  v.x.pv0 := v.x.ctrl.pv;
		  v.x.pv1 := r.x.pv1;
		  v.x.annul0 := v.x.ctrl.annul;
		  v.x.annul1 := r.x.annul1;
		  v.x.branch0 := v.x.branch;
		  v.x.branch1 := r.x.branch1;
       end if;
       
       if (r.x.ctrl.annul = '0') then
                  v.w.s.tt0 := v.w.s.tt;
		  v.w.s.tt1 := r.w.s.tt1;
		  v.w.s.cwp0 := v.w.s.cwp;
		  v.w.s.cwp1 := r.w.s.cwp1;
		  v.w.s.icc0 := v.w.s.icc;
		  v.w.s.icc1 := r.w.s.icc1;
		  v.w.rdest0 := r.x.ctrl.inst(29 downto 25);
		  v.w.rdest1 := r.w.rdest1;
		  v.w.wreg0 := v.w.wreg;
		  v.w.wreg1 := r.w.wreg1;
		  v.w.result0 := v.w.result;
		  v.w.result1 := r.w.result1;
		  v.w.wa0 := v.w.wa;
		  v.w.wa1 := r.w.wa1;
		  v.w.pc0 := r.x.ctrl.pc;
		  v.w.pc1 := r.w.pc1;
		  v.w.inst0 := r.x.ctrl.inst(31 downto 30) & r.x.ctrl.inst(21);
		  v.w.inst1 := r.w.inst1;
		  v.w.wicc0 := r.x.ctrl.wicc;
		  v.w.wicc1 := r.w.wicc1;
		  v.w.ld0 := r.x.ctrl.ld;
		  v.w.ld1 := r.w.ld1;
		  v.w.pv0 := r.x.ctrl.pv;
		  v.w.pv1 := r.w.pv1;
		  v.w.annul0 := r.x.ctrl.annul;
		  v.w.annul1 := r.w.annul1;
		  v.w.et0 := v.w.s.et;
		  v.w.et1 := r.w.et1;
		  v.w.branch0 := v.x.branch;
		  v.w.branch1 := r.x.branch1;
        end if;

	elsif ((ce0 = '0') and (ce1 = '1')) then -- bilgiday 
        if(v.x.ctrl.annul = '0') then
		  v.x.pc1 := v.x.ctrl.pc;
		  v.x.pc0 := r.x.pc0;
		  v.x.wicc1 := v.x.ctrl.wicc;
		  v.x.wicc0 := r.x.wicc0;
		  v.x.ld1 := v.x.ctrl.ld;
		  v.x.ld0 := r.x.ld0;
		  v.x.pv1 := v.x.ctrl.pv;
		  v.x.pv0 := r.x.pv0;
		  v.x.annul1 := v.x.ctrl.annul;
		  v.x.annul0 := r.x.annul0;
		  v.x.branch1 := v.x.branch;
		  v.x.branch0 := r.x.branch0;
        end if;

        if (r.x.ctrl.annul = '0') then
		  v.w.s.tt1 := v.w.s.tt;
		  v.w.s.tt0 := r.w.s.tt0;
		  v.w.s.cwp1 := v.w.s.cwp;
		  v.w.s.cwp0 := r.w.s.cwp0;
		  v.w.s.icc1 := v.w.s.icc;
		  v.w.s.icc0 := r.w.s.icc0;
		  v.w.rdest1 := r.x.ctrl.inst(29 downto 25);
		  v.w.rdest0 := r.w.rdest0;
		  v.w.wreg1 := v.w.wreg;
		  v.w.wreg0 := r.w.wreg0;
		  v.w.result1 := v.w.result;
		  v.w.result0 := r.w.result0;
		  v.w.wa1 := v.w.wa;
		  v.w.wa0 := r.w.wa0;
		  
		  v.w.pc1 := r.x.ctrl.pc;
		  v.w.pc0 := r.w.pc0;
		  v.w.inst1 := r.x.ctrl.inst(31 downto 30) & r.x.ctrl.inst(21);
		  v.w.inst0 := r.w.inst1;
		  v.w.wicc1 := r.x.ctrl.wicc;
		  v.w.wicc0 := r.w.wicc0;
		  v.w.ld1 := r.x.ctrl.ld;
		  v.w.ld0 := r.w.ld0;
		  v.w.pv1 := r.x.ctrl.pv;
		  v.w.pv0 := r.w.pv0;
		  v.w.annul1 := r.x.ctrl.annul;
		  v.w.annul0 := r.w.annul0;
		  v.w.et1 := v.w.s.et;
		  v.w.et0 := r.w.et0;
		  v.w.branch1 := v.w.branch;
		  v.w.branch0 := r.w.branch0;
         end if;
	elsif ((ce0 = '0') and (ce1 = '0')) then -- bilgiday 
		  v.w.s.tt0 := r.w.s.tt0;
		  v.w.s.tt1 := r.w.s.tt1;
		  v.w.s.cwp0 := r.w.s.cwp0;
		  v.w.s.cwp1 := r.w.s.cwp1;
		  v.w.s.icc0 := r.w.s.icc0;
		  v.w.s.icc1 := r.w.s.icc1;
		  v.w.rdest0 := r.w.rdest0;
		  v.w.rdest1 := r.w.rdest1;
		  v.w.wreg0 := r.w.wreg0;
		  v.w.wreg1 := r.w.wreg1;
		  v.w.result0 := r.w.result0;
		  v.w.result1 := r.w.result1;
		  v.w.wa0 := r.w.wa0;
		  v.w.wa1 := r.w.wa1;
		  v.x.pc1 := r.x.pc1;
		  v.x.pc0 := r.x.pc0;
		  v.x.wicc1 := r.x.wicc1;
		  v.x.wicc0 := r.x.wicc0;
		  v.x.ld1 := r.x.ld1;
		  v.x.ld0 := r.x.ld0;
		  v.x.pv1 := r.x.pv1;
		  v.x.pv0 := r.x.pv0;
		  v.x.annul1 := r.x.annul1;
		  v.x.annul0 := r.x.annul0;
		  v.x.branch1 := r.x.branch1;
		  v.x.branch0 := r.x.branch0;
		  
		  v.w.pc0 := r.w.pc0;
		  v.w.pc1 := r.w.pc1;
		  v.w.inst0 := r.w.inst0;
		  v.w.inst1 := r.w.inst1;
		  v.w.wicc1 := r.w.wicc1;
		  v.w.wicc0 := r.w.wicc0;
		  v.w.ld1 := r.w.ld1;
		  v.w.ld0 := r.w.ld0;
		  v.w.pv1 := r.w.pv1;
		  v.w.pv0 := r.w.pv0;
		  v.w.annul1 := r.w.annul1;
		  v.w.annul0 := r.w.annul0;
		  v.w.et1 := r.w.et1;
		  v.w.et0 := r.w.et0;
		  v.w.branch1 := r.w.branch1;
		  v.w.branch0 := r.w.branch0;
	end if;
	
    calibrin <= vcalib; -- bilgiday calibration support
    rin <= v; wprin <= vwpr; dsuin <= vdsu; irin <= vir;
    muli.start <= r.a.mulstart and not r.a.ctrl.annul and 
        not r.a.ctrl.trap and not ra_bpannul;
    muli.signed <= r.e.ctrl.inst(19);
    muli.op1 <= ex_mulop1; --(ex_op1(31) and r.e.ctrl.inst(19)) & ex_op1;
    muli.op2 <= ex_mulop2; --(mul_op2(31) and r.e.ctrl.inst(19)) & mul_op2;
    muli.mac <= r.e.ctrl.inst(24);
    if MACPIPE then muli.acc(39 downto 32) <= r.w.s.y(7 downto 0);
    else muli.acc(39 downto 32) <= r.x.y(7 downto 0); end if;
    muli.acc(31 downto 0) <= r.w.s.asr18;
    muli.flush <= r.x.annul_all;
    divi.start <= r.a.divstart and not r.a.ctrl.annul and 
        not r.a.ctrl.trap and not ra_bpannul;
    divi.signed <= r.e.ctrl.inst(19);
    divi.flush <= r.x.annul_all;
    divi.op1 <= (ex_op1(31) and r.e.ctrl.inst(19)) & ex_op1;
    divi.op2 <= (ex_op2(31) and r.e.ctrl.inst(19)) & ex_op2;
    if (r.a.divstart and not r.a.ctrl.annul) = '1' then 
      dsign :=  r.a.ctrl.inst(19);
    else dsign := r.e.ctrl.inst(19); end if;
    divi.y <= (r.m.y(31) and dsign) & r.m.y;
    rpin <= vp;

    if DBGUNIT then
      dbgo.dsu <= '1'; dbgo.dsumode <= r.x.debug; dbgo.crdy <= dsur.crdy(2);
      dbgo.data <= diagdata;
      if TRACEBUF then tbi <= tbufi; else
        tbi.addr <= (others => '0'); tbi.data <= (others => '0');
        tbi.enable <= '0'; tbi.write <= (others => '0'); tbi.diag <= "0000";
      end if;
    else
      dbgo.dsu <= '0'; dbgo.data <= (others => '0'); dbgo.crdy  <= '0';
      dbgo.dsumode <= '0'; tbi.addr <= (others => '0'); 
      tbi.data <= (others => '0'); tbi.enable <= '0';
      tbi.write <= (others => '0'); tbi.diag <= "0000";
    end if;
    dbgo.error <= dummy and not r.x.nerror;
    dbgo.wbhold <= '0'; --dco.wbhold;
    dbgo.su <= r.w.s.s;
    dbgo.istat <= ('0', '0', '0', '0');
    dbgo.dstat <= ('0', '0', '0', '0');


    if FPEN then
      if (r.x.rstate = dsu2) then vfpi.flush := '1'; else vfpi.flush := v.x.annul_all and holdn; end if;
      vfpi.exack := xc_fpexack; vfpi.a_rs1 := r.a.rs1; vfpi.d.inst := de_inst;
      vfpi.d.cnt := r.d.cnt;
      vfpi.d.annul := v.x.annul_all or de_bpannul or r.d.annul or de_fins_hold
        ;
      vfpi.d.trap := r.d.mexc;
      vfpi.d.pc(1 downto 0) := (others => '0'); vfpi.d.pc(31 downto PCLOW) := r.d.pc(31 downto PCLOW); 
      vfpi.d.pv := r.d.pv;
      vfpi.a.pc(1 downto 0) := (others => '0'); vfpi.a.pc(31 downto PCLOW) := r.a.ctrl.pc(31 downto PCLOW); 
      vfpi.a.inst := r.a.ctrl.inst; vfpi.a.cnt := r.a.ctrl.cnt; vfpi.a.trap := r.a.ctrl.trap;
      vfpi.a.annul := r.a.ctrl.annul or (ex_bpmiss and r.e.ctrl.inst(29))
        ;
      vfpi.a.pv := r.a.ctrl.pv;
      vfpi.e.pc(1 downto 0) := (others => '0'); vfpi.e.pc(31 downto PCLOW) := r.e.ctrl.pc(31 downto PCLOW); 
      vfpi.e.inst := r.e.ctrl.inst; vfpi.e.cnt := r.e.ctrl.cnt; vfpi.e.trap := r.e.ctrl.trap; vfpi.e.annul := r.e.ctrl.annul;
      vfpi.e.pv := r.e.ctrl.pv;
      vfpi.m.pc(1 downto 0) := (others => '0'); vfpi.m.pc(31 downto PCLOW) := r.m.ctrl.pc(31 downto PCLOW); 
      vfpi.m.inst := r.m.ctrl.inst; vfpi.m.cnt := r.m.ctrl.cnt; vfpi.m.trap := r.m.ctrl.trap; vfpi.m.annul := r.m.ctrl.annul;
      vfpi.m.pv := r.m.ctrl.pv;
      vfpi.x.pc(1 downto 0) := (others => '0'); vfpi.x.pc(31 downto PCLOW) := r.x.ctrl.pc(31 downto PCLOW); 
      vfpi.x.inst := r.x.ctrl.inst; vfpi.x.cnt := r.x.ctrl.cnt; vfpi.x.trap := xc_trap;
      vfpi.x.annul := r.x.ctrl.annul; vfpi.x.pv := r.x.ctrl.pv;
      if (lddel = 2) then vfpi.lddata := r.x.data(conv_integer(r.x.set)); else vfpi.lddata := r.x.data(0); end if;
      if (r.x.rstate = dsu2)
      then vfpi.dbg.enable := dbgi.denable;
      else vfpi.dbg.enable := '0'; end if;      
      vfpi.dbg.write := fpcdbgwr;
      vfpi.dbg.fsr := dbgi.daddr(22); -- IU reg access
      vfpi.dbg.addr := dbgi.daddr(6 downto 2);
      vfpi.dbg.data := dbgi.ddata;      
      fpi <= vfpi;
      cpi <= vfpi;      -- dummy, just to kill some warnings ...
    end if;
  end process;
  
  invalidbufx : process (clk) -- bilgiday to solve bug
  begin 
    if rising_edge(clk) then 
      if rstn = '0' then
        invalid_bufcnt_x <= '0';
      elsif (cnten and (not rin.x.ctrl.annul) and (not alarm)) = '1' then
        invalid_bufcnt_x <= bufcnt;-- inverse for backward-compatibility
      else
        invalid_bufcnt_x <= invalid_bufcnt_x;
      end if;
   end if;
  end process;

  invalidbufw : process (clk) -- bilgiday to solve bug
  begin 
    if rising_edge(clk) then 
      if rstn = '0' then
        invalid_bufcnt_w <= '0';
      elsif (cnten and (not r.x.ctrl.annul) and (not alarm)) = '1' then
        invalid_bufcnt_w <= bufcnt;
      else
        invalid_bufcnt_w <= invalid_bufcnt_w;
      end if;
   end if;
  end process;

 alarmreg : process (clk) -- bilgiday to solve bug
  begin 
    if rising_edge(clk) then 
      if rstn = '0' then
        alarm_reg <= '0';
      elsif (calibr.r0(30)) = '0' then
        alarm_reg <= '0';
      else
 --      if (r.x.rstate) = trap then
 --        alarm_reg <= '0';
        if (holdn) = '1' then
          alarm_reg <= '0';
        elsif (alarm_sensors and (not holdn)) = '1' then
          alarm_reg <= '1';
          --alarm_reg <= '0';
        else
	  alarm_reg <= alarm_reg;
	  --alarm_reg <= '0';
        end if;
      end if;
   end if;
  end process;
  
  calibrate : process (clk) -- bilgiday calibration support
  begin 
    if rising_edge(clk) then 
      if rstn = '0' then
        calibr <= calibration_reg_res;
      else
		calibr <= calibrin;
	  end if;
   end if;
  end process;
  
  chip_boundary: process (clk)
  begin
	if rising_edge(clk) then 
      if rstn = '0' then
        chip_boundary_reg <= (others => '0');
	  else
	  
		case r.x.rstate is
			when run =>
				chip_boundary_reg(56 downto 55) <= "00"; -- FSM
			when trap =>
				chip_boundary_reg(56 downto 55) <= "01"; -- FSM
			when dsu1 =>
				chip_boundary_reg(56 downto 55) <= "10"; -- FSM
			when dsu2 =>
				chip_boundary_reg(56 downto 55) <= "11"; -- FSM
		end case;
		
		chip_boundary_reg(54) <= bufcnt; -- PingPong indicator
		
		chip_boundary_reg(53) <= r.x.ctrl.wicc; -- control
		chip_boundary_reg(52) <= r.x.ctrl.annul; -- control
		chip_boundary_reg(51) <= r.x.ctrl.pv; -- control
		chip_boundary_reg(50) <= r.x.ctrl.ld; -- control
		chip_boundary_reg(49) <= r.x.ctrl.wreg; -- control
		chip_boundary_reg(48) <= r.x.branch; -- control
		
		chip_boundary_reg(47 downto 40) <= r.f.pc(9 downto 2); -- fetch pc
		chip_boundary_reg(39 downto 32) <= r.x.pc0(9 downto 2); -- return pc from pp0
		chip_boundary_reg(31 downto 24) <= r.x.pc1(9 downto 2); -- return pc from pp1
		
		chip_boundary_reg(23 downto 12) <= r.x.data(0)(11 downto 0); -- data in/out from memory
		chip_boundary_reg(11 downto 0) <= r.x.result(30) & r.x.result(7 downto 0) & r.x.result(31) & r.x.result(29 downto 28); -- data address to memory
		--chip_boundary_reg(11 downto 0) <= r.x.result(31 downto 28) & r.x.result(7 downto 0); -- data address to memory
	  end if;
	end if;
  end process;

  observe : process (clk) -- pipeline_read_support
  begin 
    if rising_edge(clk) then 
      if rstn = '0' then
        obsr <= obs_reg_res;
      elsif ((r.trigger.r2 = (r.f.pc(31 downto 2) & "00")) or (extsave = '1')) then
		obsr.r0 <= r.f.pc(31 downto 2) & "00";
		obsr.r1 <= r.d.pc(31 downto 2) & "00";
		obsr.r2 <= r.d.inst(0);
		obsr.r3 <= r.d.cwp & r.d.mexc & r.d.cnt & r.d.pv & r.d.annul & r.d.inull & r.d.step & "0000000000000000000000";
		obsr.r4 <= r.a.ctrl.pc(31 downto 2) & "00";
		obsr.r5 <= r.a.ctrl.inst;
		obsr.r6 <= r.a.ctrl.cnt & r.a.ctrl.rd & r.a.ctrl.tt & r.a.ctrl.trap & r.a.ctrl.annul & r.a.ctrl.wreg & r.a.ctrl.wicc & r.a.ctrl.wy & r.a.ctrl.ld & r.a.ctrl.pv & r.a.ctrl.rett & "00000000";
		obsr.r7 <= r.a.rs1 & r.a.rfa1 & r.a.rfa2 & r.a.rsel1 & r.a.rsel2 & r.a.rfe1 & r.a.rfe2 & r.a.cwp;
		obsr.r8 <= r.a.imm;
		obsr.r9 <= r.a.ldcheck1 & r.a.ldcheck2 & r.a.ldchkra & r.a.ldchkex & r.a.su & r.a.et & r.a.wovf & r.a.wunf & r.a.ticc & r.a.jmpl & r.a.step & r.a.mulstart & r.a.divstart & r.a.bp & r.a.nobp & "00000000000000000";
		obsr.r10 <= r.e.ctrl.pc(31 downto 2) & "00"; 
		obsr.r11 <= r.e.ctrl.inst;
		obsr.r12 <= r.e.ctrl.cnt & r.e.ctrl.rd & r.e.ctrl.tt & r.e.ctrl.trap & r.e.ctrl.annul & r.e.ctrl.wreg & r.e.ctrl.wicc & r.e.ctrl.wy & r.e.ctrl.ld & r.e.ctrl.pv & r.e.ctrl.rett & "00000000";
		obsr.r13 <= r.e.op1;
		obsr.r14 <= r.e.op2;
		obsr.r15 <= r.e.aluop & r.e.alusel & r.e.aluadd & r.e.alucin & r.e.ldbp1 & r.e.ldbp2 & r.e.invop2 & r.e.shcnt & r.e.sari & r.e.shleft & r.e.ymsb & r.e.rd & r.e.jmpl & r.e.su & r.e.et & r.e.cwp & "00"; -- Pantea "000"->"00"
		obsr.r16 <= r.e.icc & r.e.mulstep & r.e.mul & r.e.mac & r.e.bp & r.e.rfe1 & r.e.rfe2 & "0000000000000000000000";
		obsr.r17 <= r.m.ctrl.pc(31 downto 2) & "00";
		obsr.r18 <= r.m.ctrl.inst;
		obsr.r19 <= r.m.ctrl.cnt & r.m.ctrl.rd & r.m.ctrl.tt & r.m.ctrl.trap & r.m.ctrl.annul & r.m.ctrl.wreg & r.m.ctrl.wicc & r.m.ctrl.wy & r.m.ctrl.ld & r.m.ctrl.pv & r.m.ctrl.rett & "00000000";
		obsr.r20 <= r.m.result;
		obsr.r21 <= r.m.icc & r.m.nalign & r.m.dci.signed & r.m.dci.enaddr & r.m.dci.read & r.m.dci.write & r.m.dci.lock & r.m.dci.dsuen & r.m.dci.size & r.m.dci.asi & r.m.werr & r.m.wcwp & r.m.irqen & r.m.irqen2 & r.m.mac & r.m.divz & r.m.su & r.m.mul & r.m.casa & r.m.casaz & "1";
		obsr.r22 <= r.x.result;
		obsr.r23 <= r.x.data(0);
		case r.x.rstate is
			when run =>
				obsr.r24 <= r.x.annul_all & r.x.mexc & r.x.dci.signed & r.x.dci.enaddr & r.x.dci.read & r.x.dci.write & r.x.dci.lock & r.x.dci.dsuen & r.x.dci.size & r.x.dci.asi & r.x.laddr & "00" & r.x.npc & r.x.intack & r.x.ipend & r.x.mac & r.x.debug & r.x.nerror & r.x.ipmask & "0";
			when trap =>
				obsr.r24 <= r.x.annul_all & r.x.mexc & r.x.dci.signed & r.x.dci.enaddr & r.x.dci.read & r.x.dci.write & r.x.dci.lock & r.x.dci.dsuen & r.x.dci.size & r.x.dci.asi & r.x.laddr & "01" & r.x.npc & r.x.intack & r.x.ipend & r.x.mac & r.x.debug & r.x.nerror & r.x.ipmask & "0";
			when dsu1 =>
				obsr.r24 <= r.x.annul_all & r.x.mexc & r.x.dci.signed & r.x.dci.enaddr & r.x.dci.read & r.x.dci.write & r.x.dci.lock & r.x.dci.dsuen & r.x.dci.size & r.x.dci.asi & r.x.laddr & "10" & r.x.npc & r.x.intack & r.x.ipend & r.x.mac & r.x.debug & r.x.nerror & r.x.ipmask & "0";
			when dsu2 =>
				obsr.r24 <= r.x.annul_all & r.x.mexc & r.x.dci.signed & r.x.dci.enaddr & r.x.dci.read & r.x.dci.write & r.x.dci.lock & r.x.dci.dsuen & r.x.dci.size & r.x.dci.asi & r.x.laddr & "11" & r.x.npc & r.x.intack & r.x.ipend & r.x.mac & r.x.debug & r.x.nerror & r.x.ipmask & "0";
		end case;
		obsr.r25 <= r.w.result;
		obsr.r26 <= r.w.wa & r.w.wreg & r.w.except & "0000000000000000000000";
	end if;
   end if;
  end process;
  
  preg : process (sclk)
  begin 
    if rising_edge(sclk) then 
      rp <= rpin;
      if rstn = '0' then
        rp.error <= PRES.error;
        if RESET_ALL then
          if (index /= 0) and (irqi.run = '0') then
            rp.pwd <= '1';
          else
            rp.pwd <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  reg : process (clk)
  begin
    if rising_edge(clk) then
      -- alarmin synchronizer bilgiday
      alarmin1 <= alarmin(0);
      alarmin2 <= alarmin1;
      alarmin3 <= alarmin1;
      --if ((holdn = '1') or ((holdn = '0') and (alarm = '1') and (r.w.s.et = '1'))) then -- bilgiday
      if (holdn = '1') then 
        r <= rin;
      else
        r.x.ipend <= rin.x.ipend;
        r.m.werr <= rin.m.werr;
		
        --if (alarm and not r.w.s.et) = '1' then -- bilgiday (commented out for re-entrant)
		  --r.x.rstate <= dsu2;
		  --r.x.nerror <= rin.x.nerror;
        --end if;
		if (holdn or ico.mds) = '0' then
          r.d.inst <= rin.d.inst; r.d.mexc <= rin.d.mexc; 
          r.d.set <= rin.d.set;
        end if;
        if (holdn or dco.mds) = '0' then
          r.x.data <= rin.x.data; r.x.mexc <= rin.x.mexc; 
          r.x.set <= rin.x.set;
        end if;
      end if;
      if rstn = '0' then
        if RESET_ALL then
          r <= RRES;
          r.f.pc(28) <= boot_select; -- bilgiday: selective boot
          if DYNRST then
            r.f.pc(31 downto 12) <= irqi.rstvec;
            r.w.s.tba <= irqi.rstvec;
          end if;
          if DBGUNIT then
            if (dbgi.dsuen and dbgi.dbreak) = '1' then
              r.x.rstate <= dsu1; r.x.debug <= '1';
            end if;
          end if;
          if (index /= 0) and irqi.run = '0' then
            r.x.rstate <= dsu1;
          end if;
        else  
          r.w.s.s <= '1'; r.w.s.ps <= '1'; 
          if need_extra_sync_reset(fabtech) /= 0 then 
            r.d.inst <= (others => (others => '0'));
            r.x.mexc <= '0';
          end if; 
        end if;
      end if; 
    end if;
  end process;


  dsugen : if DBGUNIT generate
    dsureg : process(clk) begin
      if rising_edge(clk) then 
        if holdn = '1' then
          dsur <= dsuin;
        else
          dsur.crdy <= dsuin.crdy;
        end if;
        if rstn = '0' then
          if RESET_ALL then
            dsur <= DRES;
          elsif need_extra_sync_reset(fabtech) /= 0 then
            dsur.err <= '0'; dsur.tbufcnt <= (others => '0'); dsur.tt <= (others => '0');
            dsur.asi <= (others => '0'); dsur.crdy <= (others => '0');
          end if;
        end if;
      end if;
    end process;
  end generate;

  nodsugen : if not DBGUNIT generate
    dsur.err <= '0'; dsur.tbufcnt <= (others => '0'); dsur.tt <= (others => '0');
    dsur.asi <= (others => '0'); dsur.crdy <= (others => '0');
  end generate;

  irreg : if DBGUNIT or PWRD2
  generate
    dsureg : process(clk) begin
      if rising_edge(clk) then 
        if holdn = '1' then ir <= irin; end if;
        if RESET_ALL and rstn = '0' then ir <= IRES; end if;
      end if;
    end process;
  end generate;

  nirreg : if not (DBGUNIT or PWRD2
    )
  generate
    ir.pwd <= '0'; ir.addr <= (others => '0');
  end generate;
  
  wpgen : for i in 0 to 3 generate
    wpg0 : if nwp > i generate
      wpreg : process(clk) begin
        if rising_edge(clk) then
          if holdn = '1' then wpr(i) <= wprin(i); end if;
          if rstn = '0' then
            if RESET_ALL then
              wpr(i) <= wpr_none;
            else
              wpr(i).exec <= '0'; wpr(i).load <= '0'; wpr(i).store <= '0';
            end if;
          end if;
        end if;
      end process;
    end generate;
    wpg1 : if nwp <= i generate
      wpr(i) <= wpr_none;
    end generate;
  end generate;

-- pragma translate_off
  trc : process(clk)
    variable valid : boolean;
    variable op : std_logic_vector(1 downto 0);
    variable op3 : std_logic_vector(5 downto 0);
    variable fpins, fpld : boolean;    
  begin
    if (fpu /= 0) then
      op := r.x.ctrl.inst(31 downto 30); op3 := r.x.ctrl.inst(24 downto 19);
      fpins := (op = FMT3) and ((op3 = FPOP1) or (op3 = FPOP2));
      fpld := (op = LDST) and ((op3 = LDF) or (op3 = LDDF) or (op3 = LDFSR));
    else
      fpins := false; fpld := false;
    end if;
      valid := (((not r.x.ctrl.annul) and r.x.ctrl.pv) = '1') and (not ((fpins or fpld) and (r.x.ctrl.trap = '0')));
      valid := valid and (holdn = '1');
    if (disas = 1) and rising_edge(clk) and (rstn = '1') then
      print_insn (index, r.x.ctrl.pc(31 downto 2) & "00", r.x.ctrl.inst, 
                  rin.w.result, valid, r.x.ctrl.trap = '1', rin.w.wreg = '1',
        rin.x.ipmask = '1');
    end if;
  end process;
-- pragma translate_on

  dis0 : if disas < 2 generate dummy <= '1'; end generate;

  dis2 : if disas > 1 generate
      disasen <= '1' when disas /= 0 else '0';
      cpu_index <= conv_std_logic_vector(index, 4);
      x0 : cpu_disasx
      port map (clk, rstn, dummy, r.x.ctrl.inst, r.x.ctrl.pc(31 downto 2),
        rin.w.result, cpu_index, rin.w.wreg, r.x.ctrl.annul, holdn,
        r.x.ctrl.pv, r.x.ctrl.trap, disasen);
  end generate;

end;

