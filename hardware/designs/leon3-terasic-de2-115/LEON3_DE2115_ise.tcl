project new LEON3_DE2115.ise
project set family ""
project set device
project set speed
project set package
puts "Adding files to project"
lib_vhdl new grlib
xfile add "../../lib/grlib/stdlib/version.vhd" -lib_vhdl grlib
puts "../../lib/grlib/stdlib/version.vhd"
xfile add "../../lib/grlib/stdlib/config_types.vhd" -lib_vhdl grlib
puts "../../lib/grlib/stdlib/config_types.vhd"
xfile add "../../lib/grlib/stdlib/config.vhd" -lib_vhdl grlib
puts "../../lib/grlib/stdlib/config.vhd"
xfile add "../../lib/grlib/stdlib/stdlib.vhd" -lib_vhdl grlib
puts "../../lib/grlib/stdlib/stdlib.vhd"
xfile add "../../lib/grlib/sparc/sparc.vhd" -lib_vhdl grlib
puts "../../lib/grlib/sparc/sparc.vhd"
xfile add "../../lib/grlib/modgen/multlib.vhd" -lib_vhdl grlib
puts "../../lib/grlib/modgen/multlib.vhd"
xfile add "../../lib/grlib/modgen/leaves.vhd" -lib_vhdl grlib
puts "../../lib/grlib/modgen/leaves.vhd"
xfile add "../../lib/grlib/amba/amba.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/amba.vhd"
xfile add "../../lib/grlib/amba/devices.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/devices.vhd"
xfile add "../../lib/grlib/amba/defmst.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/defmst.vhd"
xfile add "../../lib/grlib/amba/apbctrl.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/apbctrl.vhd"
xfile add "../../lib/grlib/amba/ahbctrl.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/ahbctrl.vhd"
xfile add "../../lib/grlib/amba/dma2ahb_pkg.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/dma2ahb_pkg.vhd"
xfile add "../../lib/grlib/amba/dma2ahb.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/dma2ahb.vhd"
xfile add "../../lib/grlib/amba/ahbmst.vhd" -lib_vhdl grlib
puts "../../lib/grlib/amba/ahbmst.vhd"
lib_vhdl new synplify
lib_vhdl new techmap
xfile add "../../lib/techmap/gencomp/gencomp.vhd" -lib_vhdl techmap
puts "../../lib/techmap/gencomp/gencomp.vhd"
xfile add "../../lib/techmap/gencomp/netcomp.vhd" -lib_vhdl techmap
puts "../../lib/techmap/gencomp/netcomp.vhd"
xfile add "../../lib/techmap/inferred/memory_inferred.vhd" -lib_vhdl techmap
puts "../../lib/techmap/inferred/memory_inferred.vhd"
xfile add "../../lib/techmap/inferred/ddr_inferred.vhd" -lib_vhdl techmap
puts "../../lib/techmap/inferred/ddr_inferred.vhd"
xfile add "../../lib/techmap/inferred/mul_inferred.vhd" -lib_vhdl techmap
puts "../../lib/techmap/inferred/mul_inferred.vhd"
xfile add "../../lib/techmap/inferred/ddr_phy_inferred.vhd" -lib_vhdl techmap
puts "../../lib/techmap/inferred/ddr_phy_inferred.vhd"
xfile add "../../lib/techmap/inferred/ddrphy_datapath.vhd" -lib_vhdl techmap
puts "../../lib/techmap/inferred/ddrphy_datapath.vhd"
xfile add "../../lib/techmap/maps/allclkgen.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/allclkgen.vhd"
xfile add "../../lib/techmap/maps/allddr.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/allddr.vhd"
xfile add "../../lib/techmap/maps/allmem.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/allmem.vhd"
xfile add "../../lib/techmap/maps/allmul.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/allmul.vhd"
xfile add "../../lib/techmap/maps/allpads.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/allpads.vhd"
xfile add "../../lib/techmap/maps/alltap.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/alltap.vhd"
xfile add "../../lib/techmap/maps/clkgen.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkgen.vhd"
xfile add "../../lib/techmap/maps/clkmux.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkmux.vhd"
xfile add "../../lib/techmap/maps/clkinv.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkinv.vhd"
xfile add "../../lib/techmap/maps/clkand.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkand.vhd"
xfile add "../../lib/techmap/maps/ddr_ireg.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/ddr_ireg.vhd"
xfile add "../../lib/techmap/maps/ddr_oreg.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/ddr_oreg.vhd"
xfile add "../../lib/techmap/maps/ddrphy.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/ddrphy.vhd"
xfile add "../../lib/techmap/maps/syncram.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram.vhd"
xfile add "../../lib/techmap/maps/syncram64.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram64.vhd"
xfile add "../../lib/techmap/maps/syncram_2p.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram_2p.vhd"
xfile add "../../lib/techmap/maps/syncram_dp.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram_dp.vhd"
xfile add "../../lib/techmap/maps/syncfifo_2p.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncfifo_2p.vhd"
xfile add "../../lib/techmap/maps/regfile_3p.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/regfile_3p.vhd"
xfile add "../../lib/techmap/maps/tap.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/tap.vhd"
xfile add "../../lib/techmap/maps/techbuf.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/techbuf.vhd"
xfile add "../../lib/techmap/maps/nandtree.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/nandtree.vhd"
xfile add "../../lib/techmap/maps/clkpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkpad.vhd"
xfile add "../../lib/techmap/maps/clkpad_ds.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkpad_ds.vhd"
xfile add "../../lib/techmap/maps/inpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/inpad.vhd"
xfile add "../../lib/techmap/maps/inpad_ds.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/inpad_ds.vhd"
xfile add "../../lib/techmap/maps/iodpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/iodpad.vhd"
xfile add "../../lib/techmap/maps/iopad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/iopad.vhd"
xfile add "../../lib/techmap/maps/iopad_ds.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/iopad_ds.vhd"
xfile add "../../lib/techmap/maps/lvds_combo.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/lvds_combo.vhd"
xfile add "../../lib/techmap/maps/odpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/odpad.vhd"
xfile add "../../lib/techmap/maps/outpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/outpad.vhd"
xfile add "../../lib/techmap/maps/outpad_ds.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/outpad_ds.vhd"
xfile add "../../lib/techmap/maps/toutpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/toutpad.vhd"
xfile add "../../lib/techmap/maps/skew_outpad.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/skew_outpad.vhd"
xfile add "../../lib/techmap/maps/grlfpw_net.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/grlfpw_net.vhd"
xfile add "../../lib/techmap/maps/grfpw_net.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/grfpw_net.vhd"
xfile add "../../lib/techmap/maps/leon4_net.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/leon4_net.vhd"
xfile add "../../lib/techmap/maps/mul_61x61.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/mul_61x61.vhd"
xfile add "../../lib/techmap/maps/cpu_disas_net.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/cpu_disas_net.vhd"
xfile add "../../lib/techmap/maps/ringosc.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/ringosc.vhd"
xfile add "../../lib/techmap/maps/system_monitor.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/system_monitor.vhd"
xfile add "../../lib/techmap/maps/grgates.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/grgates.vhd"
xfile add "../../lib/techmap/maps/inpad_ddr.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/inpad_ddr.vhd"
xfile add "../../lib/techmap/maps/outpad_ddr.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/outpad_ddr.vhd"
xfile add "../../lib/techmap/maps/iopad_ddr.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/iopad_ddr.vhd"
xfile add "../../lib/techmap/maps/syncram128bw.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram128bw.vhd"
xfile add "../../lib/techmap/maps/syncram256bw.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram256bw.vhd"
xfile add "../../lib/techmap/maps/syncram128.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram128.vhd"
xfile add "../../lib/techmap/maps/syncram156bw.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram156bw.vhd"
xfile add "../../lib/techmap/maps/techmult.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/techmult.vhd"
xfile add "../../lib/techmap/maps/spictrl_net.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/spictrl_net.vhd"
xfile add "../../lib/techmap/maps/scanreg.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/scanreg.vhd"
xfile add "../../lib/techmap/maps/syncrambw.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncrambw.vhd"
xfile add "../../lib/techmap/maps/syncram_2pbw.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncram_2pbw.vhd"
xfile add "../../lib/techmap/maps/sdram_phy.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/sdram_phy.vhd"
xfile add "../../lib/techmap/maps/syncreg.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/syncreg.vhd"
xfile add "../../lib/techmap/maps/clkinv.vhd" -lib_vhdl techmap
puts "../../lib/techmap/maps/clkinv.vhd"
lib_vhdl new eth
xfile add "../../lib/eth/comp/ethcomp.vhd" -lib_vhdl eth
puts "../../lib/eth/comp/ethcomp.vhd"
xfile add "../../lib/eth/core/greth_pkg.vhd" -lib_vhdl eth
puts "../../lib/eth/core/greth_pkg.vhd"
xfile add "../../lib/eth/core/eth_rstgen.vhd" -lib_vhdl eth
puts "../../lib/eth/core/eth_rstgen.vhd"
xfile add "../../lib/eth/core/eth_edcl_ahb_mst.vhd" -lib_vhdl eth
puts "../../lib/eth/core/eth_edcl_ahb_mst.vhd"
xfile add "../../lib/eth/core/eth_ahb_mst.vhd" -lib_vhdl eth
puts "../../lib/eth/core/eth_ahb_mst.vhd"
xfile add "../../lib/eth/core/greth_tx.vhd" -lib_vhdl eth
puts "../../lib/eth/core/greth_tx.vhd"
xfile add "../../lib/eth/core/greth_rx.vhd" -lib_vhdl eth
puts "../../lib/eth/core/greth_rx.vhd"
xfile add "../../lib/eth/core/grethc.vhd" -lib_vhdl eth
puts "../../lib/eth/core/grethc.vhd"
xfile add "../../lib/eth/wrapper/greth_gen.vhd" -lib_vhdl eth
puts "../../lib/eth/wrapper/greth_gen.vhd"
xfile add "../../lib/eth/wrapper/greth_gbit_gen.vhd" -lib_vhdl eth
puts "../../lib/eth/wrapper/greth_gbit_gen.vhd"
lib_vhdl new opencores
xfile add "../../lib/opencores/can/cancomp.vhd" -lib_vhdl opencores
puts "../../lib/opencores/can/cancomp.vhd"
xfile add "../../lib/opencores/can/can_top.vhd" -lib_vhdl opencores
puts "../../lib/opencores/can/can_top.vhd"
xfile add "../../lib/opencores/i2c/i2c_master_bit_ctrl.vhd" -lib_vhdl opencores
puts "../../lib/opencores/i2c/i2c_master_bit_ctrl.vhd"
xfile add "../../lib/opencores/i2c/i2c_master_byte_ctrl.vhd" -lib_vhdl opencores
puts "../../lib/opencores/i2c/i2c_master_byte_ctrl.vhd"
xfile add "../../lib/opencores/i2c/i2coc.vhd" -lib_vhdl opencores
puts "../../lib/opencores/i2c/i2coc.vhd"
lib_vhdl new gaisler
xfile add "../../lib/gaisler/grdmac/grdmac_pkg.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_pkg.vhd"
xfile add "../../lib/gaisler/grdmac/apbmem.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/apbmem.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_ahbmst.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_ahbmst.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_alignram.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_alignram.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_1p.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_1p.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_memory.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_memory.vhd"
xfile add "../../lib/gaisler/arith/arith.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/arith/arith.vhd"
xfile add "../../lib/gaisler/arith/mul32.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/arith/mul32.vhd"
xfile add "../../lib/gaisler/arith/div32.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/arith/div32.vhd"
xfile add "../../lib/gaisler/memctrl/memctrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/memctrl/memctrl.vhd"
xfile add "../../lib/gaisler/memctrl/sdctrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/memctrl/sdctrl.vhd"
xfile add "../../lib/gaisler/memctrl/sdctrl64.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/memctrl/sdctrl64.vhd"
xfile add "../../lib/gaisler/memctrl/sdmctrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/memctrl/sdmctrl.vhd"
xfile add "../../lib/gaisler/memctrl/srctrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/memctrl/srctrl.vhd"
xfile add "../../lib/gaisler/srmmu/mmuconfig.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmuconfig.vhd"
xfile add "../../lib/gaisler/srmmu/mmuiface.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmuiface.vhd"
xfile add "../../lib/gaisler/srmmu/libmmu.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/libmmu.vhd"
xfile add "../../lib/gaisler/srmmu/mmutlbcam.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmutlbcam.vhd"
xfile add "../../lib/gaisler/srmmu/mmulrue.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmulrue.vhd"
xfile add "../../lib/gaisler/srmmu/mmulru.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmulru.vhd"
xfile add "../../lib/gaisler/srmmu/mmutlb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmutlb.vhd"
xfile add "../../lib/gaisler/srmmu/mmutw.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmutw.vhd"
xfile add "../../lib/gaisler/srmmu/mmu.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/srmmu/mmu.vhd"
xfile add "../../lib/gaisler/leon3/leon3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3/leon3.vhd"
xfile add "../../lib/gaisler/leon3/grfpushwx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3/grfpushwx.vhd"
xfile add "../../lib/gaisler/leon3v3/tbufmem.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/tbufmem.vhd"
xfile add "../../lib/gaisler/leon3v3/dsu3x.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/dsu3x.vhd"
xfile add "../../lib/gaisler/leon3v3/dsu3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/dsu3.vhd"
xfile add "../../lib/gaisler/leon3v3/dsu3_mb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/dsu3_mb.vhd"
xfile add "../../lib/gaisler/leon3v3/libfpu.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/libfpu.vhd"
xfile add "../../lib/gaisler/leon3v3/libiu.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/libiu.vhd"
xfile add "../../lib/gaisler/leon3v3/libcache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/libcache.vhd"
xfile add "../../lib/gaisler/leon3v3/libleon3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/libleon3.vhd"
xfile add "../../lib/gaisler/leon3v3/regfile_3p_l3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/regfile_3p_l3.vhd"
xfile add "../../lib/gaisler/leon3v3/mmu_acache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/mmu_acache.vhd"
xfile add "../../lib/gaisler/leon3v3/mmu_icache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/mmu_icache.vhd"
xfile add "../../lib/gaisler/leon3v3/mmu_dcache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/mmu_dcache.vhd"
xfile add "../../lib/gaisler/leon3v3/cachemem.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/cachemem.vhd"
xfile add "../../lib/gaisler/leon3v3/mmu_cache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/mmu_cache.vhd"
xfile add "../../lib/gaisler/leon3v3/grfpwx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/grfpwx.vhd"
xfile add "../../lib/gaisler/leon3v3/grlfpwx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/grlfpwx.vhd"
xfile add "../../lib/gaisler/leon3v3/ff.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/ff.vhd"
xfile add "../../lib/gaisler/leon3v3/canary.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/canary.vhd"
xfile add "../../lib/gaisler/leon3v3/canary2.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/canary2.vhd"
xfile add "../../lib/gaisler/leon3v3/count_bil.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/count_bil.vhd"
xfile add "../../lib/gaisler/leon3v3/iu3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/iu3.vhd"
xfile add "../../lib/gaisler/leon3v3/proc3.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/proc3.vhd"
xfile add "../../lib/gaisler/leon3v3/leon3cg.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/leon3cg.vhd"
xfile add "../../lib/gaisler/leon3v3/leon3s.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/leon3s.vhd"
xfile add "../../lib/gaisler/leon3v3/leon3sh.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/leon3sh.vhd"
xfile add "../../lib/gaisler/leon3v3/leon3x.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/leon3x.vhd"
xfile add "../../lib/gaisler/leon3v3/grfpwxsh.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/grfpwxsh.vhd"
xfile add "../../lib/gaisler/leon3v3/secReg.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/leon3v3/secReg.vhd"
xfile add "../../lib/gaisler/irqmp/irqmp.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/irqmp/irqmp.vhd"
xfile add "../../lib/gaisler/l2cache/v2-pkg/l2cache.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/l2cache/v2-pkg/l2cache.vhd"
xfile add "../../lib/gaisler/can/can.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/can.vhd"
xfile add "../../lib/gaisler/can/can_mod.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/can_mod.vhd"
xfile add "../../lib/gaisler/can/can_oc.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/can_oc.vhd"
xfile add "../../lib/gaisler/can/can_mc.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/can_mc.vhd"
xfile add "../../lib/gaisler/can/canmux.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/canmux.vhd"
xfile add "../../lib/gaisler/can/can_rd.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/can/can_rd.vhd"
xfile add "../../lib/gaisler/misc/misc.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/misc.vhd"
xfile add "../../lib/gaisler/misc/rstgen.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/rstgen.vhd"
xfile add "../../lib/gaisler/misc/gptimer.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/gptimer.vhd"
xfile add "../../lib/gaisler/misc/ahbram.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbram.vhd"
xfile add "../../lib/gaisler/misc/ahbdpram.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbdpram.vhd"
xfile add "../../lib/gaisler/misc/ahbtrace_mmb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbtrace_mmb.vhd"
xfile add "../../lib/gaisler/misc/ahbtrace_mb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbtrace_mb.vhd"
xfile add "../../lib/gaisler/misc/ahbtrace.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbtrace.vhd"
xfile add "../../lib/gaisler/misc/grgpio.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/grgpio.vhd"
xfile add "../../lib/gaisler/misc/ahbstat.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahbstat.vhd"
xfile add "../../lib/gaisler/misc/logan.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/logan.vhd"
xfile add "../../lib/gaisler/misc/apbps2.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/apbps2.vhd"
xfile add "../../lib/gaisler/misc/charrom_package.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/charrom_package.vhd"
xfile add "../../lib/gaisler/misc/charrom.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/charrom.vhd"
xfile add "../../lib/gaisler/misc/apbvga.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/apbvga.vhd"
xfile add "../../lib/gaisler/misc/svgactrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/svgactrl.vhd"
xfile add "../../lib/gaisler/misc/grsysmon.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/grsysmon.vhd"
xfile add "../../lib/gaisler/misc/gracectrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/gracectrl.vhd"
xfile add "../../lib/gaisler/misc/grgpreg.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/grgpreg.vhd"
xfile add "../../lib/gaisler/misc/ahb_mst_iface.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/ahb_mst_iface.vhd"
xfile add "../../lib/gaisler/misc/grgprbank.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/misc/grgprbank.vhd"
xfile add "../../lib/gaisler/net/net.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/net/net.vhd"
xfile add "../../lib/gaisler/uart/uart.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/uart.vhd"
xfile add "../../lib/gaisler/uart/libdcom.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/libdcom.vhd"
xfile add "../../lib/gaisler/uart/apbuart.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/apbuart.vhd"
xfile add "../../lib/gaisler/uart/dcom.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/dcom.vhd"
xfile add "../../lib/gaisler/uart/dcom_uart.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/dcom_uart.vhd"
xfile add "../../lib/gaisler/uart/ahbuart.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/uart/ahbuart.vhd"
xfile add "../../lib/gaisler/jtag/jtag.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/jtag.vhd"
xfile add "../../lib/gaisler/jtag/libjtagcom.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/libjtagcom.vhd"
xfile add "../../lib/gaisler/jtag/jtagcom.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/jtagcom.vhd"
xfile add "../../lib/gaisler/jtag/ahbjtag.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/ahbjtag.vhd"
xfile add "../../lib/gaisler/jtag/ahbjtag_bsd.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/ahbjtag_bsd.vhd"
xfile add "../../lib/gaisler/jtag/bscanregs.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/bscanregs.vhd"
xfile add "../../lib/gaisler/jtag/bscanregsbd.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/bscanregsbd.vhd"
xfile add "../../lib/gaisler/jtag/jtagcom2.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/jtag/jtagcom2.vhd"
xfile add "../../lib/gaisler/greth/ethernet_mac.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/ethernet_mac.vhd"
xfile add "../../lib/gaisler/greth/greth.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/greth.vhd"
xfile add "../../lib/gaisler/greth/greth_mb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/greth_mb.vhd"
xfile add "../../lib/gaisler/greth/greth_gbit.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/greth_gbit.vhd"
xfile add "../../lib/gaisler/greth/greth_gbit_mb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/greth_gbit_mb.vhd"
xfile add "../../lib/gaisler/greth/grethm.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/grethm.vhd"
xfile add "../../lib/gaisler/greth/rgmii.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/greth/rgmii.vhd"
xfile add "../../lib/gaisler/i2c/i2c.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c.vhd"
xfile add "../../lib/gaisler/i2c/i2cmst.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2cmst.vhd"
xfile add "../../lib/gaisler/i2c/i2cmst_gen.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2cmst_gen.vhd"
xfile add "../../lib/gaisler/i2c/i2cslv.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2cslv.vhd"
xfile add "../../lib/gaisler/i2c/i2c2ahbx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c2ahbx.vhd"
xfile add "../../lib/gaisler/i2c/i2c2ahb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c2ahb.vhd"
xfile add "../../lib/gaisler/i2c/i2c2ahb_apb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c2ahb_apb.vhd"
xfile add "../../lib/gaisler/i2c/i2c2ahb_gen.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c2ahb_gen.vhd"
xfile add "../../lib/gaisler/i2c/i2c2ahb_apb_gen.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/i2c/i2c2ahb_apb_gen.vhd"
xfile add "../../lib/gaisler/spi/spi.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spi.vhd"
xfile add "../../lib/gaisler/spi/spimctrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spimctrl.vhd"
xfile add "../../lib/gaisler/spi/spictrlx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spictrlx.vhd"
xfile add "../../lib/gaisler/spi/spictrl.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spictrl.vhd"
xfile add "../../lib/gaisler/spi/spi2ahbx.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spi2ahbx.vhd"
xfile add "../../lib/gaisler/spi/spi2ahb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spi2ahb.vhd"
xfile add "../../lib/gaisler/spi/spi2ahb_apb.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/spi/spi2ahb_apb.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_pkg.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_pkg.vhd"
xfile add "../../lib/gaisler/grdmac/apbmem.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/apbmem.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_ahbmst.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_ahbmst.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_alignram.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_alignram.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_1p.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_1p.vhd"
xfile add "../../lib/gaisler/grdmac/grdmac_memory.vhd" -lib_vhdl gaisler
puts "../../lib/gaisler/grdmac/grdmac_memory.vhd"
lib_vhdl new esa
xfile add "../../lib/esa/memoryctrl/memoryctrl.vhd" -lib_vhdl esa
puts "../../lib/esa/memoryctrl/memoryctrl.vhd"
xfile add "../../lib/esa/memoryctrl/mctrl.vhd" -lib_vhdl esa
puts "../../lib/esa/memoryctrl/mctrl.vhd"
lib_vhdl new coprocessors
xfile add "../../lib/coprocessors/examplevhd/examplevhd.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/examplevhd/examplevhd.vhd"
xfile add "../../lib/coprocessors/examplevhd/apb_example.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/examplevhd/apb_example.vhd"
xfile add "../../lib/coprocessors/aes/vlog_aes_wrap.v"
puts "../../lib/coprocessors/aes/vlog_aes_wrap.v"
xfile add "../../lib/coprocessors/aes/aes_core.v"
puts "../../lib/coprocessors/aes/aes_core.v"
xfile add "../../lib/coprocessors/aes/aes_encipher_block.v"
puts "../../lib/coprocessors/aes/aes_encipher_block.v"
xfile add "../../lib/coprocessors/aes/aes_key_mem.v"
puts "../../lib/coprocessors/aes/aes_key_mem.v"
xfile add "../../lib/coprocessors/aes/aes_decipher_block.v"
puts "../../lib/coprocessors/aes/aes_decipher_block.v"
xfile add "../../lib/coprocessors/aes/aes_inv_sbox.v"
puts "../../lib/coprocessors/aes/aes_inv_sbox.v"
xfile add "../../lib/coprocessors/aes/aes_sbox.v"
puts "../../lib/coprocessors/aes/aes_sbox.v"
xfile add "../../lib/coprocessors/aes/aes.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes/aes.vhd"
xfile add "../../lib/coprocessors/aes/apb_aes.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes/apb_aes.vhd"
xfile add "../../lib/coprocessors/aes_em/vlog_aes_em.v"
puts "../../lib/coprocessors/aes_em/vlog_aes_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_cipher_top_em.v"
puts "../../lib/coprocessors/aes_em/aes_cipher_top_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_inv_cipher_top_em.v"
puts "../../lib/coprocessors/aes_em/aes_inv_cipher_top_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_inv_sbox_em.v"
puts "../../lib/coprocessors/aes_em/aes_inv_sbox_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_em_sbox.v"
puts "../../lib/coprocessors/aes_em/aes_em_sbox.v"
xfile add "../../lib/coprocessors/aes_em/aes_key_expand_128_em.v"
puts "../../lib/coprocessors/aes_em/aes_key_expand_128_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_rcon_em.v"
puts "../../lib/coprocessors/aes_em/aes_rcon_em.v"
xfile add "../../lib/coprocessors/aes_em/aes_sensor.v"
puts "../../lib/coprocessors/aes_em/aes_sensor.v"
xfile add "../../lib/coprocessors/aes_em/aes_sensor_32.v"
puts "../../lib/coprocessors/aes_em/aes_sensor_32.v"
xfile add "../../lib/coprocessors/aes_em/aes_em.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_em/aes_em.vhd"
xfile add "../../lib/coprocessors/aes_em/apb_aes_em.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_em/apb_aes_em.vhd"
xfile add "../../lib/coprocessors/emsensor/sensorcell.v"
puts "../../lib/coprocessors/emsensor/sensorcell.v"
xfile add "../../lib/coprocessors/emsensor/sensor32.v"
puts "../../lib/coprocessors/emsensor/sensor32.v"
xfile add "../../lib/coprocessors/emsensor/sensor_grlib.v"
puts "../../lib/coprocessors/emsensor/sensor_grlib.v"
xfile add "../../lib/coprocessors/emsensor/timing_sensor32.v"
puts "../../lib/coprocessors/emsensor/timing_sensor32.v"
xfile add "../../lib/coprocessors/emsensor/apb_sensor.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/emsensor/apb_sensor.vhd"
xfile add "../../lib/coprocessors/emsensor/emsensor.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/emsensor/emsensor.vhd"
xfile add "../../lib/coprocessors/emsensor/tsensor.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/emsensor/tsensor.vhd"
xfile add "../../lib/coprocessors/emsensor/tsensor_inv.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/emsensor/tsensor_inv.vhd"
xfile add "../../lib/coprocessors/keymill/vlog_keymill.v"
puts "../../lib/coprocessors/keymill/vlog_keymill.v"
xfile add "../../lib/coprocessors/keymill/LR_Keymill_8.v"
puts "../../lib/coprocessors/keymill/LR_Keymill_8.v"
xfile add "../../lib/coprocessors/keymill/fifo.v"
puts "../../lib/coprocessors/keymill/fifo.v"
xfile add "../../lib/coprocessors/keymill/keymill.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/keymill/keymill.vhd"
xfile add "../../lib/coprocessors/keymill/apb_keymill_vlog.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/keymill/apb_keymill_vlog.vhd"
xfile add "../../lib/coprocessors/acorn/vlog_acorn.v"
puts "../../lib/coprocessors/acorn/vlog_acorn.v"
xfile add "../../lib/coprocessors/acorn/fifo_acorn.v"
puts "../../lib/coprocessors/acorn/fifo_acorn.v"
xfile add "../../lib/coprocessors/acorn/AEAD_pkg.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn/AEAD_pkg.vhd"
xfile add "../../lib/coprocessors/acorn/apb_acorn_vlog.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn/apb_acorn_vlog.vhd"
xfile add "../../lib/coprocessors/acorn/acorn.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn/acorn.vhd"
xfile add "../../lib/coprocessors/acorn/acorn_stateUpdate32.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn/acorn_stateUpdate32.vhd"
xfile add "../../lib/coprocessors/acorn/CipherCore.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn/CipherCore.vhd"
xfile add "../../lib/coprocessors/reedsolomon/RS_core.v"
puts "../../lib/coprocessors/reedsolomon/RS_core.v"
xfile add "../../lib/coprocessors/reedsolomon/reedsolomon_wrapper.v"
puts "../../lib/coprocessors/reedsolomon/reedsolomon_wrapper.v"
xfile add "../../lib/coprocessors/reedsolomon/reedsolomon.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/reedsolomon/reedsolomon.vhd"
xfile add "../../lib/coprocessors/reedsolomon/apb_reedsolomon.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/reedsolomon/apb_reedsolomon.vhd"
xfile add "../../lib/coprocessors/nist_comb/comb_NISTSBOX.v"
puts "../../lib/coprocessors/nist_comb/comb_NISTSBOX.v"
xfile add "../../lib/coprocessors/nist_comb/comb_NISTINVSBOX.v"
puts "../../lib/coprocessors/nist_comb/comb_NISTINVSBOX.v"
xfile add "../../lib/coprocessors/nist_comb/comb_sbox_LUT.v"
puts "../../lib/coprocessors/nist_comb/comb_sbox_LUT.v"
xfile add "../../lib/coprocessors/nist_comb/comb_inv_sbox.v"
puts "../../lib/coprocessors/nist_comb/comb_inv_sbox.v"
xfile add "../../lib/coprocessors/nist_comb/comb_sbox_comp.v"
puts "../../lib/coprocessors/nist_comb/comb_sbox_comp.v"
xfile add "../../lib/coprocessors/nist_comb/comb_K3LRsbox.v"
puts "../../lib/coprocessors/nist_comb/comb_K3LRsbox.v"
xfile add "../../lib/coprocessors/nist_comb/comb_GF2to8Mult.v"
puts "../../lib/coprocessors/nist_comb/comb_GF2to8Mult.v"
xfile add "../../lib/coprocessors/nist_comb/comb_GF2to8Inv_s103_d18.v"
puts "../../lib/coprocessors/nist_comb/comb_GF2to8Inv_s103_d18.v"
xfile add "../../lib/coprocessors/nist_comb/comb_GF2to16Mult.v"
puts "../../lib/coprocessors/nist_comb/comb_GF2to16Mult.v"
xfile add "../../lib/coprocessors/nist_comb/comb_GF2to16Inv.v"
puts "../../lib/coprocessors/nist_comb/comb_GF2to16Inv.v"
xfile add "../../lib/coprocessors/nist_comb/comb_64bitmult.v"
puts "../../lib/coprocessors/nist_comb/comb_64bitmult.v"
xfile add "../../lib/coprocessors/nist_comb/fifo_comb.v"
puts "../../lib/coprocessors/nist_comb/fifo_comb.v"
xfile add "../../lib/coprocessors/nist_comb/nist_comb_wrapper.v"
puts "../../lib/coprocessors/nist_comb/nist_comb_wrapper.v"
xfile add "../../lib/coprocessors/nist_comb/apb_nist_comb.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/nist_comb/apb_nist_comb.vhd"
xfile add "../../lib/coprocessors/nist_comb/nist_comb.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/nist_comb/nist_comb.vhd"
xfile add "../../lib/coprocessors/aes_nist/vlog_aes_nist_wrap.v"
puts "../../lib/coprocessors/aes_nist/vlog_aes_nist_wrap.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_core.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_core.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_encipher_block.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_encipher_block.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_key_mem.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_key_mem.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_decipher_block.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_decipher_block.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_inv_sbox.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_inv_sbox.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist_sbox.v"
puts "../../lib/coprocessors/aes_nist/aes_nist_sbox.v"
xfile add "../../lib/coprocessors/aes_nist/aes_nist.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_nist/aes_nist.vhd"
xfile add "../../lib/coprocessors/aes_nist/apb_aes_nist.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_nist/apb_aes_nist.vhd"
xfile add "../../lib/coprocessors/aes_comp/vlog_aes_comp_wrap.v"
puts "../../lib/coprocessors/aes_comp/vlog_aes_comp_wrap.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_core.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_core.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_encipher_block.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_encipher_block.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_key_mem.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_key_mem.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_decipher_block.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_decipher_block.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_inv_sbox.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_inv_sbox.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp_sbox.v"
puts "../../lib/coprocessors/aes_comp/aes_comp_sbox.v"
xfile add "../../lib/coprocessors/aes_comp/comp_sbox.v"
puts "../../lib/coprocessors/aes_comp/comp_sbox.v"
xfile add "../../lib/coprocessors/aes_comp/aes_comp.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_comp/aes_comp.vhd"
xfile add "../../lib/coprocessors/aes_comp/apb_aes_comp.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aes_comp/apb_aes_comp.vhd"
xfile add "../../lib/coprocessors/sbox_em/vlog_sbox_em.v"
puts "../../lib/coprocessors/sbox_em/vlog_sbox_em.v"
xfile add "../../lib/coprocessors/sbox_em/sbox_sensor_32.v"
puts "../../lib/coprocessors/sbox_em/sbox_sensor_32.v"
xfile add "../../lib/coprocessors/sbox_em/aes_sbox_em.v"
puts "../../lib/coprocessors/sbox_em/aes_sbox_em.v"
xfile add "../../lib/coprocessors/sbox_em/sbox_em.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/sbox_em/sbox_em.vhd"
xfile add "../../lib/coprocessors/sbox_em/apb_sbox_em.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/sbox_em/apb_sbox_em.vhd"
xfile add "../../lib/coprocessors/sbox_em/sbox_sensor.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/sbox_em/sbox_sensor.vhd"
xfile add "../../lib/coprocessors/aegis/fifo_aegis.v"
puts "../../lib/coprocessors/aegis/fifo_aegis.v"
xfile add "../../lib/coprocessors/aegis/fifo_out_aegis.v"
puts "../../lib/coprocessors/aegis/fifo_out_aegis.v"
xfile add "../../lib/coprocessors/aegis/vlog_aegis.v"
puts "../../lib/coprocessors/aegis/vlog_aegis.v"
xfile add "../../lib/coprocessors/aegis/AEAD_pkg_aegis.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AEAD_pkg_aegis.vhd"
xfile add "../../lib/coprocessors/aegis/AES_pkg_aegis.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_pkg_aegis.vhd"
xfile add "../../lib/coprocessors/aegis/AES_invmap.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_invmap.vhd"
xfile add "../../lib/coprocessors/aegis/AES_map.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_map.vhd"
xfile add "../../lib/coprocessors/aegis/AES_mul.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_mul.vhd"
xfile add "../../lib/coprocessors/aegis/AES_MixColumn.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_MixColumn.vhd"
xfile add "../../lib/coprocessors/aegis/AES_MixColumns.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_MixColumns.vhd"
xfile add "../../lib/coprocessors/aegis/AES_Sbox_aegis.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_Sbox_aegis.vhd"
xfile add "../../lib/coprocessors/aegis/AES_SubBytes.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_SubBytes.vhd"
xfile add "../../lib/coprocessors/aegis/AES_ShiftRows.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_ShiftRows.vhd"
xfile add "../../lib/coprocessors/aegis/AES_Round.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/AES_Round.vhd"
xfile add "../../lib/coprocessors/aegis/aegis_update.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/aegis_update.vhd"
xfile add "../../lib/coprocessors/aegis/aegis_cipher_core.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/aegis_cipher_core.vhd"
xfile add "../../lib/coprocessors/aegis/apb_aegis_vlog.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/apb_aegis_vlog.vhd"
xfile add "../../lib/coprocessors/aegis/aegis.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/aegis/aegis.vhd"
xfile add "../../lib/coprocessors/morus/fifo_morus.v"
puts "../../lib/coprocessors/morus/fifo_morus.v"
xfile add "../../lib/coprocessors/morus/fifo_out_morus.v"
puts "../../lib/coprocessors/morus/fifo_out_morus.v"
xfile add "../../lib/coprocessors/morus/vlog_morus.v"
puts "../../lib/coprocessors/morus/vlog_morus.v"
xfile add "../../lib/coprocessors/morus/AEAD_pkg_morus.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/morus/AEAD_pkg_morus.vhd"
xfile add "../../lib/coprocessors/morus/morus_round.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/morus/morus_round.vhd"
xfile add "../../lib/coprocessors/morus/morus_cipher_core.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/morus/morus_cipher_core.vhd"
xfile add "../../lib/coprocessors/morus/apb_morus_vlog.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/morus/apb_morus_vlog.vhd"
xfile add "../../lib/coprocessors/morus/morus.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/morus/morus.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/fifo_in_acorn_8bit.v"
puts "../../lib/coprocessors/acorn_8bit/fifo_in_acorn_8bit.v"
xfile add "../../lib/coprocessors/acorn_8bit/fifo_out_acorn_8bit.v"
puts "../../lib/coprocessors/acorn_8bit/fifo_out_acorn_8bit.v"
xfile add "../../lib/coprocessors/acorn_8bit/vlog_acorn_8bit.v"
puts "../../lib/coprocessors/acorn_8bit/vlog_acorn_8bit.v"
xfile add "../../lib/coprocessors/acorn_8bit/AEAD_pkg_acorn_8bit.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/AEAD_pkg_acorn_8bit.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/AEAD_acorn_8bit.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/AEAD_acorn_8bit.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/acorn_stateUpdate8.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/acorn_stateUpdate8.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/CipherCore_acorn_8bit.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/CipherCore_acorn_8bit.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/apb_acorn_8bit_vlog.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/apb_acorn_8bit_vlog.vhd"
xfile add "../../lib/coprocessors/acorn_8bit/acorn_8bit.vhd" -lib_vhdl coprocessors
puts "../../lib/coprocessors/acorn_8bit/acorn_8bit.vhd"
lib_vhdl new work
xfile add "config.vhd" -lib_vhdl work
puts "config.vhd"
xfile add "leon3mp.vhd" -lib_vhdl work
puts "leon3mp.vhd"
xfile add "ahbrom.vhd" -lib_vhdl work
puts "ahbrom.vhd"
project set top "rtl" "LEON3_DE2115"
project set "Bus Delimiter" ()
project set "FSM Encoding Algorithm" None
project set "Pack I/O Registers into IOBs" yes
project set "Verilog Macros" ""
project set "Other XST Command Line Options" "" -process "Synthesize - XST"
project set "Allow Unmatched LOC Constraints" true -process "Translate"
project set "Macro Search Path" "../../netlists/xilinx/" -process "Translate"
project set "Pack I/O Registers/Latches into IOBs" {For Inputs and Outputs}
project set "Other MAP Command Line Options" "-timing" -process Map
project set "Drive Done Pin High" true -process "Generate Programming File"
project set "Create ReadBack Data Files" true -process "Generate Programming File"
project set "Create Mask File" true -process "Generate Programming File"
project set "Run Design Rules Checker (DRC)" false -process "Generate Programming File"
project close
exit
