# Pin map: Harness dial vs Waveshare ESP32-S3-Touch-AMOLED-1.75C

Sources:

- Upstream: `devices/harness-device/firmware/main/board/pins_dial.h` and `board_table.c` at the pinned commit.
- Waveshare BSP: ESP component `waveshare/esp32_s3_touch_amoled_1_75c` v3.0.0, file `include/bsp/esp32_s3_touch_amoled_1_75c.h`.
- Waveshare schematic: `hardware/schematic/ESP32-S3-Touch-AMOLED-1.75C-schematic.pdf` in
  [waveshareteam/ESP32-S3-Touch-AMOLED-1.75C](https://github.com/waveshareteam/ESP32-S3-Touch-AMOLED-1.75C) (commit `4bfdc80`).

| Signal | Harness (board A) | Waveshare 1.75C | Same? |
|---|---|---|---|
| QSPI CS | 12 | 12 | yes |
| QSPI SCLK | 38 | 38 | yes |
| QSPI D0..D3 | 4, 5, 6, 7 | 4, 5, 6, 7 | yes |
| Panel column gap | 6 | 6 | yes |
| **Panel reset** | **39** | **1** (`LCD_RESET`) | **no** |
| **Touch reset** | **40** | **2** (`TP_RESET`) | **no** |
| Touch INT | 11 | 11 | yes |
| Touch mirror | X and Y (180 degrees) | X and Y (BSP default) | yes |
| I2C SDA / SCL | 15 / 14 | 15 / 14 | yes |
| I2S MCLK | 16 | 16 | yes |
| I2S BCLK | 9 | 9 | yes |
| I2S WS (LRCK) | 45 | 45 | yes |
| I2S data, codec to ESP | 10 (per BSP: `DSIN`) | 10 | yes |
| I2S data, ESP to codec | 8 | 8 | yes |
| Speaker amp enable (NS4150B) | 46 | 46 | yes |
| BOOT button | 0 | 0 (Key1, "BOOT") | yes |
| PWR button | AXP2101 PWRON | AXP2101 PWRON (Key2, "PWR") | yes |

Note on the two I2S data lines: upstream's comments for `BSP_I2S_DOUT` and `BSP_I2S_DIN` read the
opposite way round from the schematic (schematic: GPIO8 = `I2S_DSDIN`, ESP to ES8311; GPIO10 =
`I2S_ASDOUT`, ES7210 to ESP). The numbers match Waveshare's BSP exactly, so the code is fine; only the
comments are swapped. Worth a look during audio bring-up.

## I2C bus

| Address | Chip | Harness (board A) | Waveshare 1.75C |
|---|---|---|---|
| 0x18 | ES8311 codec | yes | yes |
| 0x34 | AXP2101 PMIC | yes | yes |
| 0x40 | ES7210 mic ADC | yes | yes |
| 0x5A | CST9217 touch | yes | yes |
| 0x6B | QMI8658 IMU | no (full scan by upstream: `34 5A 18 40`) | yes (SA0 pulled up) |

The IMU is the only bus difference, so the patch uses it to pick the Waveshare row.

## Things the brief expected that are not on this board

- **No TCA9554 I/O expander.** That chip is on other Waveshare AMOLED boards (the 1.8" and 2.06" ones).
  On the 1.75C both resets are direct GPIOs, so no expander driver is needed.
- **No PCF85063 RTC** on this schematic.
- GPIO 39, 40, 41, 42 go only to test pads. Upstream pulsing 39/40 at boot is harmless here.

## Flash size

The schematic shows an XM25QH128 (16 MB). The Amazon listing and Waveshare's examples say 32 MB.
Either way the firmware is built for 16 MB (`CONFIG_ESPTOOLPY_FLASHSIZE_16MB`) and the partition table
(two 7.9 MB app slots) fits. On a 32 MB part the top half is simply unused. Measured image size at the
pinned commit: 0x335960 (3.2 MB), 59% of the slot free.

## Power rails

Upstream only reads the AXP2101 (battery, charge state, PWR key) and never changes a rail. The panel
runs from the 3.3 V DCDC1 rail, which is on by default on the Waveshare board. So the Waveshare
factory rail setup is what the firmware runs on, same as Waveshare's own BSP.
