# Pin assignments for first bring-up

Use these assignments in Quartus Pin Planner for the first clean build.

| Top-level port | Board signal | FPGA pin | I/O standard |
| --- | --- | --- | --- |
| `clock_50` | `CLOCK_50` | `PIN_AJ16` | `3.3-V LVTTL` |
| `reset_n` | `KEY0` | `PIN_AA26` | `2.5-V` |
| `ledr[0]` | `LEDR0` | `PIN_T23` | `2.5-V` |
| `ledr[1]` | `LEDR1` | `PIN_T24` | `2.5-V` |
| `ledr[2]` | `LEDR2` | `PIN_V27` | `2.5-V` |
| `ledr[3]` | `LEDR3` | `PIN_W25` | `2.5-V` |
| `ledr[4]` | `LEDR4` | `PIN_T21` | `2.5-V` |
| `ledr[5]` | `LEDR5` | `PIN_T26` | `2.5-V` |
| `ledr[6]` | `LEDR6` | `PIN_R25` | `2.5-V` |
| `ledr[7]` | `LEDR7` | `PIN_T27` | `2.5-V` |
| `ledr[8]` | `LEDR8` | `PIN_P25` | `2.5-V` |
| `ledr[9]` | `LEDR9` | `PIN_R24` | `2.5-V` |
| `ledr[10]` | `LEDR10` | `PIN_P21` | `2.5-V` |
| `ledr[11]` | `LEDR11` | `PIN_N24` | `2.5-V` |
| `ledr[12]` | `LEDR12` | `PIN_N21` | `2.5-V` |
| `ledr[13]` | `LEDR13` | `PIN_M25` | `2.5-V` |
| `ledr[14]` | `LEDR14` | `PIN_K24` | `2.5-V` |
| `ledr[15]` | `LEDR15` | `PIN_L25` | `2.5-V` |
| `ledr[16]` | `LEDR16` | `PIN_M21` | `2.5-V` |
| `ledr[17]` | `LEDR17` | `PIN_M22` | `2.5-V` |
| `ledg[0]` | `LEDG0` heartbeat | `PIN_AA25` | `2.5-V` |
| `ledg[1]` | `LEDG1` trap | `PIN_AB25` | `2.5-V` |

Optional UART pins for the next step:

| Future port | Board signal | FPGA pin | I/O standard |
| --- | --- | --- | --- |
| `uart_tx` | `UART_TXD` | `PIN_H24` | `3.3-V LVTTL` |
| `uart_rx` | `UART_RXD` | `PIN_B27` | `3.3-V LVTTL` |
