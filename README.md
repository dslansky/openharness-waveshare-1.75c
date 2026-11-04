# OpenHarness on the Waveshare ESP32-S3-Touch-AMOLED-1.75C

Run the open-source [Harness](https://github.com/autonomous-ai/openharness) desk device firmware on a
stock Waveshare ESP32-S3-Touch-AMOLED-1.75C. No soldering, USB-C only.

## Status

**Builds, not yet tested on hardware.** The firmware compiles and all upstream host tests pass with the
patch applied. A board arrives Nov 8-13, 2026; this README will be updated after bring-up.

| Check | State |
|---|---|
| Pin map cross-checked (upstream vs Waveshare BSP vs schematic) | done, see [docs/pin-map.md](docs/pin-map.md) |
| Firmware builds (ESP-IDF 5.5.4, esp32s3) | done, 3.2 MB image, 59% of the update slot free |
| Upstream host tests (`make device-test`) | pass |
| Boot, display, touch | not yet |
| PWR / BOOT buttons, battery | not yet |
| Microphones, speaker | not yet |
| Shows agents from the Harness daemon | not yet |
| Daemon does not overwrite this firmware | expected (see below), to confirm |

## Why this is a small patch

The Harness dial turns out to be nearly the same board as the Waveshare one. Same chips (CO5300
display, CST9217 touch, AXP2101 power chip, ES8311 + ES7210 audio) and the same pins for the display
bus, I2C, audio and speaker. Upstream's partition table even names this Waveshare board.

The one real difference: the display and touch **reset pins** are GPIO 1 and 2 on the Waveshare board,
versus 39 and 40 on the Harness board. Stock upstream firmware would mistake a Waveshare board for a
Harness board and send resets to the wrong pins.

The patch adds a third row to upstream's board-detection table. Firmware decides which board it is on
at boot by asking which chips answer on the I2C bus (the shared two-wire bus the chips sit on). The
Waveshare board has a motion sensor (QMI8658, address 0x6B) that the Harness board does not, so:
CST9217 touch + motion sensor = Waveshare, use resets 1/2. That is the whole change:
[patches/0001-waveshare-1.75c-board-variant.patch](patches/0001-waveshare-1.75c-board-variant.patch).

Things the original plan expected but turned out unnecessary: no I/O expander chip on this board
(TCA9554 is on other Waveshare models), and the 16 MB partition table fits as-is.

## Build

Needs macOS or Linux, git, and [ESP-IDF 5.5.4](https://docs.espressif.com/projects/esp-idf/en/v5.5.4/esp32s3/get-started/)
(Espressif's toolchain for this chip).

```bash
git clone https://github.com/dslansky/openharness-waveshare-1.75c.git
cd openharness-waveshare-1.75c
. ~/esp/esp-idf-v5.5.4/export.sh
scripts/setup.sh --build
```

`setup.sh` clones upstream at the pinned commit in [UPSTREAM_COMMIT](UPSTREAM_COMMIT)
(`e0d1e6fe4170a6b084cede1aa24905b1523412e5`, Nov 3 2026), applies the patch, and builds.

## Flash

```bash
cd work/openharness/devices/harness-device/firmware
idf.py -p /dev/cu.usbmodemXXXX flash monitor
```

The first flash replaces the Waveshare bootloader and partition table (needed for Harness's two-slot
update layout). It does not touch eFuses, and the chip's built-in ROM loader can always reflash it over
USB. Back up the factory image first if you want to return to the Waveshare demo; the full first-time
checklist is in [docs/bring-up.md](docs/bring-up.md).

Stop the Harness daemon's device connection before flashing; only one program can hold the serial port.

## Buttons

| Waveshare button | Harness role |
|---|---|
| PWR, short tap | Side button: back / stop / screen off (read through the AXP2101) |
| PWR, long press | Hardware restart (handled by the AXP2101 itself) |
| BOOT, held at power-on | Factory reset of saved settings |

Same mapping as the original Harness board, which wires its buttons the same way.

## Will the Harness daemon overwrite this firmware?

It should not. The daemon only offers firmware updates to boards it recognizes by name
(`otaKeyForBoard` in `cli/src/cable/fwPush.ts`), and this firmware reports itself as `waveshare-1.75c`,
which is not on that list. If upstream later adds the name and publishes images for it, updates would
start flowing, which is the point of upstreaming.

## Host side

Install the Harness app or daemon on the Mac the board is plugged into:

```bash
curl -fsSL https://harness.autonomous.ai/cli/install.sh | bash && harness login && harness start
```

Claude Code, Codex and Antigravity CLI (agy) are supported by the daemon directly. Known agy limit: you
cannot start a new agy session with a first message from the device.

## Upstreaming

The patch is written in upstream's style (code comments, host test, README table row) so it can go in
as a PR once it is confirmed on hardware.

## License

MIT, same as upstream. See [LICENSE](LICENSE).
