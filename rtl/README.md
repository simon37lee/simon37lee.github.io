# AXI4 Asynchronous CDC Bridge

Synthesizable Verilog for bridging a full AXI4 (5-channel: AW, W, B, AR, R)
master and slave that live in **different, unrelated clock domains**. Two
interchangeable implementations are provided so their throughput/latency/area
tradeoffs can be compared:

| | `axi4_async_bridge_fifo.v` (Version A) | `axi4_async_bridge_handshake.v` (Version B) |
|---|---|---|
| CDC mechanism | Dual-clock async FIFO per channel, Gray-coded pointers | 2-flop synchronizer + toggle req/ack handshake per channel |
| Outstanding beats/channel | `FIFO_DEPTH` (default 16) | 1 |
| Area | Higher (5x dual-port RAM + Gray logic) | Lower (registers only, no RAM) |
| Throughput | Up to 1 beat/cycle, buffered across the clock gap | Capped at 1 beat per full CDC round trip (~4+ sync cycles) |
| Latency (light load) | Lower (pipelined) | Higher (round trip per beat) |

Both modules expose **identical port lists** (verified: same parameters,
same signal names/widths) so either can be dropped in without touching the
surrounding integration.

## Directory layout

```
rtl/
  include/
    axi4_defs.vh          Shared AXI4 field widths, encodings, per-channel
                           payload-width macros. Included by both bridges so
                           the channel payload packing order is defined once.
    axi4_clog2.vh          ceil(log2()) helper function (included per-module).
  common/
    cdc_reset_sync.v       Async-assert / sync-deassert reset synchronizer.
    cdc_2ff_sync.v          Generic 1-bit 2-flop synchronizer.
    gray_sync_ptr.v        N-bit 2-flop synchronizer for a Gray-coded pointer.
    async_fifo.v            Parameterized Cummings-style dual-clock FIFO.
    cdc_pulse_toggle.v      Toggle-based req/ack pulse CDC primitive.
  axi4_cdc_channel_fifo.v        1 AXI channel over async_fifo (Version A).
  axi4_cdc_channel_handshake.v   1 AXI channel over cdc_pulse_toggle (Version B).
  axi4_async_bridge_fifo.v       TOP: Version A (5x channel_fifo).
  axi4_async_bridge_handshake.v  TOP: Version B (5x channel_handshake).
  tb/
    axi4_bfm_slave.v                    Memory-model AXI4 slave BFM.
    tb_axi4_common_body.vh              Shared testbench body (`DUT_MODULE macro).
    tb_axi4_async_bridge_fifo.v         Thin wrapper -> Version A.
    tb_axi4_async_bridge_handshake.v    Thin wrapper -> Version B.
    Makefile                            iverilog/vvp simulation targets.
```

Each AXI4 channel (AW/W/B/AR/R) is structurally identical from a CDC point of
view: N-bit payload + valid + ready, crossing one clock domain to another in
one direction. Rather than hand-duplicating CDC logic 5x per bridge, each
channel's fields are concatenated into one flat payload bus and passed
through one generic `axi4_cdc_channel_*` instance. AW/W/AR flow
`s_axi_aclk -> m_axi_aclk`; B/R flow the opposite direction.

## Port list

Parameters: `DATA_WIDTH` (64), `ADDR_WIDTH` (32), `ID_WIDTH` (4),
`AWUSER_WIDTH`/`WUSER_WIDTH`/`BUSER_WIDTH`/`ARUSER_WIDTH`/`RUSER_WIDTH` (1),
`FIFO_DEPTH` (16, Version A only -- accepted but unused in Version B, kept
for interface parity).

Ports: `s_axi_aclk`/`s_axi_aresetn` + the full standard AXI4 slave-facing
signal set (AWID/AWADDR/AWLEN/AWSIZE/AWBURST/AWLOCK/AWCACHE/AWPROT/AWQOS/
AWUSER/AWVALID/AWREADY, W*, B*, AR*, R*), and symmetrically
`m_axi_aclk`/`m_axi_aresetn` + the master-facing signal set. See the top of
either bridge file for the exact signal list.

## Correctness notes

- **Reset**: each clock domain gets its own `cdc_reset_sync` instance
  (async assert / sync deassert). If a reset is asserted on only one side
  while transactions are in flight, the other side's in-progress state is
  **not** guaranteed to unwind cleanly -- reset both `s_axi_aresetn` and
  `m_axi_aresetn` together for a clean restart.
- **AW/W ordering**: not required by AXI4 and not enforced by the bridge --
  AW and W are independent, parallel CDC paths; matching them is the
  downstream slave's responsibility, same as in a single-clock system.
- **B/R ordering**: preserved automatically, since each channel's CDC path
  (FIFO or handshake) is strictly in-order in Version A and B alike.
- **No combinational cross-domain paths**: the only signals that cross a
  clock boundary are the Gray-coded FIFO pointers (Version A, via
  `gray_sync_ptr`) or the single-bit toggle wires (Version B, via
  `cdc_pulse_toggle`) -- both go through dedicated 2-flop synchronizers.
  Multi-bit payload buses never cross combinationally: Version A stores them
  in dual-port RAM; Version B holds the source-side register stable for the
  whole round trip and only samples it after the synchronized toggle
  confirms 2+ cycles of stability.
- **Metastability**: minimum 2-flop synchronization on every CDC signal.

## Running the testbenches

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`/`vvp`),
e.g. `apt-get install iverilog` on Debian/Ubuntu.

```sh
cd rtl/tb
make sim_fifo        # Version A only
make sim_handshake    # Version B only
make sim_all          # both
```

Each testbench drives `s_axi_aclk` at 100 MHz and `m_axi_aclk` at a
deliberately non-harmonic ~143 MHz, issues randomized AXI4 write+read-back
bursts (INCR/FIXED/WRAP, random length/ID/address, random backpressure on
both sides via the memory-model slave BFM), and self-checks data integrity,
`BRESP`/`RRESP`, `BID`/`RID`, and `RLAST` placement. A run ends with
`TEST PASSED: N transactions, 0 errors` or `TEST FAILED: ... M errors`.

RTL synthesizability is sanity-checked by construction: no `initial` blocks,
no `#delay`, no `$display`/`$finish` appear anywhere under `rtl/` outside
`rtl/tb/`. If [Verilator](https://verilator.org/) is available, an
additional lint pass can be run, e.g.:

```sh
verilator --lint-only -Wall -Iinclude \
  common/*.v axi4_cdc_channel_fifo.v axi4_cdc_channel_handshake.v \
  axi4_async_bridge_fifo.v --top-module axi4_async_bridge_fifo
```
