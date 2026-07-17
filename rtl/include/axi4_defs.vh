// AXI4 shared field widths, encodings and channel payload-width macros.
// Included by both CDC bridge implementations so that the packing order of
// each channel's payload bus is defined exactly once and stays identical
// across axi4_async_bridge_fifo and axi4_async_bridge_handshake.
`ifndef AXI4_DEFS_VH
`define AXI4_DEFS_VH

// Fixed-width AXI4 sub-fields (spec-defined, independent of module parameters)
`define AXI4_LEN_W    8
`define AXI4_SIZE_W   3
`define AXI4_BURST_W  2
`define AXI4_LOCK_W   1
`define AXI4_CACHE_W  4
`define AXI4_PROT_W   3
`define AXI4_QOS_W    4
`define AXI4_RESP_W   2

// AxBURST encodings
`define AXI4_BURST_FIXED 2'b00
`define AXI4_BURST_INCR  2'b01
`define AXI4_BURST_WRAP  2'b10

// xRESP encodings
`define AXI4_RESP_OKAY   2'b00
`define AXI4_RESP_EXOKAY 2'b01
`define AXI4_RESP_SLVERR 2'b10
`define AXI4_RESP_DECERR 2'b11

// Channel payload widths. Args: *_W are the module's DATA_WIDTH/ADDR_WIDTH/
// ID_WIDTH/xUSER_WIDTH parameters. Both bridges must instantiate their
// per-channel FIFO/handshake wrapper with exactly these widths.
`define AXI4_AW_WIDTH(ID_W, ADDR_W, USER_W) \
  (ID_W + ADDR_W + `AXI4_LEN_W + `AXI4_SIZE_W + `AXI4_BURST_W + \
   `AXI4_LOCK_W + `AXI4_CACHE_W + `AXI4_PROT_W + `AXI4_QOS_W + USER_W)

`define AXI4_AR_WIDTH(ID_W, ADDR_W, USER_W) \
  `AXI4_AW_WIDTH(ID_W, ADDR_W, USER_W)

`define AXI4_W_WIDTH(DATA_W, USER_W) \
  (DATA_W + (DATA_W/8) + 1 + USER_W)

`define AXI4_B_WIDTH(ID_W, USER_W) \
  (ID_W + `AXI4_RESP_W + USER_W)

`define AXI4_R_WIDTH(ID_W, DATA_W, USER_W) \
  (ID_W + DATA_W + `AXI4_RESP_W + 1 + USER_W)

// Packing order (MSB -> LSB) used by both bridges when concatenating a
// channel's fields into its flat payload bus, and when slicing it back out:
//
//   AW/AR : { xID, xADDR, xLEN, xSIZE, xBURST, xLOCK, xCACHE, xPROT, xQOS, xUSER }
//   W     : { WDATA, WSTRB, WLAST, WUSER }
//   B     : { BID, BRESP, BUSER }
//   R     : { RID, RDATA, RRESP, RLAST, RUSER }

`endif // AXI4_DEFS_VH
