# Beta release checklist

- [x] UART echo tested on physical FPGA board (reported by developer)
- [x] Memory-controller testbench passed in Vivado (reported by developer)
- [x] R8051 `MOV A,#55h` smoke test passed in Vivado (reported by developer)
- [x] R8051 internal RAM write smoke test passed in Vivado (reported by developer)
- [ ] Confirm RAM-read handshake with a dedicated assertion/counter
- [ ] Connect CPU instruction fetch to the same writable program memory used by host loader
- [ ] Add CPU halt/program/restart sequence to loader
- [ ] Add PC firmware uploader and packet/checksum protocol
- [ ] Run a Keil C51-compiled firmware image end-to-end
- [ ] Complete SFR/GPIO semantics and physical GPIO
- [ ] Add LCD driver and validate on board
- [ ] Confirm clock frequency and timing constraints for exact board revision

This is a transparent beta snapshot, not a claim of a completed 8051 system.
