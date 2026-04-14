# DE2i-150 PicoRV32 clean bring-up

This directory is a fresh minimal bring-up project for DE2i-150:

- `rtl/picorv32.v`: upstream PicoRV32 core copied from the cloned source tree
- `rtl/de2i_150_pico_blink.v`: minimal top-level with BRAM and LED MMIO only
- `firmware/`: bare-metal RV32I firmware that blinks LEDs
- `de2i_150_pico_blink.sdc`: 50 MHz clock constraint
- `PIN_ASSIGNMENTS.md`: pin list to enter in Quartus Pin Planner

## Memory map

- `0x0000_0000` to `0x0000_7fff`: on-chip BRAM, 32 KB
- `0x0300_0000`: LED register, low 8 bits drive `ledr[7:0]`

Board note:

- The design exposes all `18` red LEDs to the top level.
- Only `ledr[7:0]` are used by firmware in this bring-up.
- `ledr[17:8]` are driven low intentionally so they do not float and glow dimly on the board.

## Firmware build

From this directory:

```bash
cd firmware
make
```

This generates:

- `firmware/firmware.hex`
- `firmware/firmware_byte0.hex`
- `firmware/firmware_byte1.hex`
- `firmware/firmware_byte2.hex`
- `firmware/firmware_byte3.hex`

The top-level RTL loads the four byte-lane files. This is intentional: Quartus Standard on Cyclone IV is more likely to infer real `M9K` RAM blocks from four 8-bit memories than from one preinitialized 32-bit byte-enabled RAM.

## Quartus project creation

1. Open Quartus Prime and create a new project in this directory.
2. Project name: `de2i_150_pico_blink`.
3. Top-level entity: `de2i_150_pico_blink`.
4. Device: `EP4CGX150DF31C7` (`Cyclone IV GX`).
5. Add these files:
   - `rtl/picorv32.v`
   - `rtl/de2i_150_pico_blink.v`
   - `de2i_150_pico_blink.sdc`
6. Open Pin Planner and enter the pins from `PIN_ASSIGNMENTS.md`.
7. Compile once. Fix only project setup issues first, not feature work.
8. Program the FPGA and release `KEY0`.

## Expected behavior

- `LEDG0` blinks slowly as a heartbeat from hardware logic.
- `LEDG1` stays low in the normal case. If it turns on, the core trapped.
- `LEDR[7:0]` shifts one lit LED left continuously when the CPU and firmware are running.
- `LEDR[17:8]` stay off.

## Reset behavior

- `reset_n` is connected to `KEY0`.
- `KEY0` is active-low: press to reset, release to run.

## Suggested next step

After this LED-only bring-up is stable, add UART as the first peripheral extension.
