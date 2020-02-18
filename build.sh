#!/bin/bash

export ltop=$PWD
export lib_leon3=$ltop/lib
export gaisler_lib=$lib_leon3/gaisler
export processor=$gaisler_lib/leon3v3
export grlib_leon3=$lib_leon3/grlib
export acorn=$coprocessors/acorn
export aes_leon3=$coprocessors/aes
export aes_nist=$coprocessors/aes_nist
export aes_comp=$coprocessors/aes_comp
export sbox_em=$coprocessors/sbox_em
export nist_comb=$coprocessors/nist_comb
export keymill=$coprocessors/keymill
export emsensor=$coprocessors/emsensor
export amba=$grlib_leon3/amba
export sparc=$grlib_leon3/sparc
export techmap=$lib_leon3/techmap
export gencomp=$techmap/gencomp
export designs=$ltop/designs
export leon3_asic=$designs/leon3-asic
export simulation=$leon3_asic/simulation
export software_leon3=$ltop/software
export test_soft=$software_leon3/test_soft_nistchip
export util_nistchip=$ltop/../util
export icc_scripts=$leon3_asic/icc_scripts
export icc_reports=$leon3_asic/icc_reports
export tempscripts=$leon3_asic/tempscripts_nistchip
export pt_scripts=$leon3_asic/pt_scripts
export power_analysis=$leon3_asic/icc_reports/power_analysis
export fsdb_waveforms=$tempscripts/waveforms

export tsmc_gpio=/opt/libs/tsmc180/extracted/gpio
export tsmc_gpio_mw=/opt/libs/tsmc180/extracted/gpio/TPZ018NV/TS02IG502/fb_tpz018nv_280a_r6p0-02eac0/milkyway
export tsmc_lib=/opt/libs/tsmc180/extracted/tsmc/cl018g/sc9_base_rvt/2008q3v01
export tsmc_mw=/opt/libs/tsmc180/extracted/tsmc/cl018g/sc9_base_rvt/2008q3v01/milkyway


echo "Finished Setting up environment variables..."
