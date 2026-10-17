# FPGA-Based 8051 Soft-Core System (Beta)

An educational FPGA project combining an existing Verilog 8051 soft-core, UART communication, writable program-memory infrastructure, and early CPU/memory integration work for the EDGE Artix-7 FPGA kit.

> **Beta / work in progress:** UART echo was tested on the physical FPGA board. The standalone memory-controller testbench and basic CPU smoke tests passed in the developer's Vivado 2023.2 environment. The complete CPU + UART loader + writable program BRAM path has **not** yet been integrated or verified end-to-end.

## Current status

| Area | Status | Evidence |
|---|---|---|
| UART TX/RX | Board-tested byte echo | Developer observed `PASS: FPGA echoed A successfully!` on the physical board |
| UART memory controller | Simulation passed | Writes to addresses `000`, `001`, `002` acknowledged and readback matched |
| R8051 instruction smoke test | Simulation passed | `MOV A,#55h` resulted in accumulator `55h` |
| R8051 internal-RAM write | Simulation passed | `MOV 30h,A` resulted in RAM address `30h` containing `55h` |
| CPU + writable program memory + UART loader together | Not verified | Integration module is experimental |
| Keil C51 firmware loaded and executed end-to-end | Not verified | Future milestone |
| Physical LCD / complete SFR behavior | Not implemented/verified | Future milestone |

## Structure

```text
rtl/third_party/r8051/  Upstream R8051 core and instruction include
rtl/uart/              UART RX, UART TX, UART echo top
rtl/memory/            UART memory controller and program BRAM
rtl/system/            Experimental CPU-memory subsystem wrapper
sim/                   Memory-controller and CPU smoke testbenches
constraints/            EDGE Artix-7 UART echo pin constraints
```

## Toolchain

- Xilinx Vivado 2023.2
- EDGE Artix-7 FPGA kit
- Verilog-2001 RTL
- USB-UART serial connection

## Open in Vivado

1. Create an RTL project for the correct EDGE Artix-7 part.
2. Add `rtl/uart/uart_rx.v`, `rtl/uart/uart_tx.v`, and `rtl/uart/uart_echo_top.v` as design sources.
3. Add `constraints/edge_artix7_uart_echo.xdc` as a constraints file.
4. Set **`uart_echo_top`** as the top for the currently board-tested UART echo design.
5. For memory-controller simulation, add `sim/tb_memory_controller.v` as simulation top with `rtl/memory/memory_controller.v`, `rtl/memory/program_bram.v`, `rtl/uart/uart_rx.v`, and `rtl/uart/uart_tx.v`.
6. For CPU simulation, add `rtl/third_party/r8051/r8051.v` and `rtl/third_party/r8051/instruction.v` as design sources, plus `sim/tb_r8051_smoke.v` as simulation top. Keep `instruction.v` beside `r8051.v` so the include resolves.
7. **Do not use `r8051_memory_subsystem` as the FPGA top yet.** Its full memory timing and system integration are not validated.

## Hardware notes

The XDC uses the user-supplied mapping: clock `N11`, USB-UART TX `C4`, USB-UART RX `D4`, reset button `M14`, LEDs `J3,H3,J1,K1,L3,L2,K3,K2`. The pin document did not state the oscillator frequency; the XDC assumes 100 MHz. Confirm the exact board revision and clock frequency before relying on timing results. Reset is assumed active-high.

## UART memory-controller protocol

- Write: ASCII `W`, address-high nibble byte, address-low byte, data byte; response `0x06` (ACK).
- Read: ASCII `R`, address-high nibble byte, address-low byte; response is the stored byte.

This protocol has been tested as a **standalone memory controller**. It is not yet connected to the R8051 CPU.

## Attribution

The CPU core in `rtl/third_party/r8051/` is by **Li Xinbing** and is distributed under Apache License 2.0. The original license is included alongside the RTL. Upstream: <https://github.com/risclite/R8051>. This third-party core is not original work by this project maintainer; preserve its copyright and license notice.

## Resume wording — accurate beta description

**FPGA-Based 8051 Soft-Core Integration (Beta) — Verilog, Vivado, Artix-7, UART**
- Integrated and simulated an open-source 8051 soft-core at RTL level; developed UART communication and a byte-oriented program-memory controller.
- Verified UART echo on an Artix-7 board and tested memory-controller read/write behavior and basic CPU instruction/RAM operations in simulation.
- Developing writable program-memory integration and a UART firmware-loading path; end-to-end Keil C51 execution remains in progress.

Do not describe the UART bootloader or complete 8051 computer as finished until CPU, writable program BRAM, and UART loader work together.
