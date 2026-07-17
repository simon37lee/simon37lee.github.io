IVERILOG ?= iverilog
VVP      ?= vvp
INCDIRS  := -I ../include -I .
RTL_COMMON := ../common/cdc_reset_sync.v ../common/cdc_2ff_sync.v ../common/gray_sync_ptr.v \
              ../common/async_fifo.v ../common/cdc_pulse_toggle.v
RTL_CHAN   := ../axi4_cdc_channel_fifo.v ../axi4_cdc_channel_handshake.v

.PHONY: all sim_fifo sim_handshake sim_all clean

all: sim_all

sim_fifo:
	$(IVERILOG) -g2005 -Wall $(INCDIRS) -o sim_fifo.vvp \
		$(RTL_COMMON) $(RTL_CHAN) ../axi4_async_bridge_fifo.v \
		axi4_bfm_slave.v tb_axi4_async_bridge_fifo.v
	$(VVP) sim_fifo.vvp

sim_handshake:
	$(IVERILOG) -g2005 -Wall $(INCDIRS) -o sim_handshake.vvp \
		$(RTL_COMMON) $(RTL_CHAN) ../axi4_async_bridge_handshake.v \
		axi4_bfm_slave.v tb_axi4_async_bridge_handshake.v
	$(VVP) sim_handshake.vvp

sim_all: sim_fifo sim_handshake

clean:
	rm -f sim_fifo.vvp sim_handshake.vvp
