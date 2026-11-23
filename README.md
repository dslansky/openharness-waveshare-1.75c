# OpenHarness on the Waveshare ESP32-S3-Touch-AMOLED-1.75C

Run the open-source [Harness](https://github.com/autonomous-ai/openharness) desk device firmware on a
stock Waveshare ESP32-S3-Touch-AMOLED-1.75C. No soldering, USB-C only.

## Status

**Working on real hardware** (first board, Nov 14 2026). It boots, detects itself, drives the display,
links over USB and shows agents; touch, the BOOT button and the microphone are checked too.

| Check | State |
|---|---|
| Pin map cross-checked (upstream vs Waveshare BSP vs schematic) | done, see [docs/pin-map.md](docs/pin-map.md) |
| Firmware builds (ESP-IDF 5.5.4, esp32s3) | done, 3.2 MB image, 59% of the update slot free |
| Upstream host tests (`make device-test`) | pass |
| Boot and board detection (`waveshare-1.75c`, resets 1/2, IMU at 0x6B) | done, clean boot log |
| Display | done; turns 180° for hanging from the cable (patch 0005), and stays on when told to (patch 0006) |
| Touch | done: swipes switch agents, taps answer on-screen buttons (patch 0002), swipe up reads the latest reply (patch 0003), a finished agent has a hide button (patch 0009), pull down for controls (patch 0007), swipes read from the whole stroke (patch 0008) |
| BOOT button | done: stops the agent on screen |
| PWR button, battery | not yet checked |
| Wi-Fi | joins the home network and links to agent-dial with the shared secret (patch 0004) |
| Microphones | done: voice turns transcribed and delivered to agents |
| Speaker | done: notice beep heard, and spoken replies played and understood by speech-to-text on the Mac (patch 0003) |
| Shows agents | done, from the Harness daemon (inside `hn`) and from [agent-dial](#which-agents-show-up) |
| Daemon does not overwrite this firmware | confirmed: log says `not offering firmware — board "waveshare-1.75c" has no image channel` |
| Restore to Waveshare factory firmware | tested: full backup written back, stock demo boots |

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

A second, optional patch, [patches/0002-tap-face-to-answer-question.patch](patches/0002-tap-face-to-answer-question.patch),
lets a touch on the face open an agent's open question so it can be answered with buttons on the glass
(when the host advertises `question.review`). Without it the stock firmware only shows questions.

A third, optional patch, [patches/0003-read-and-hear-replies.patch](patches/0003-read-and-hear-replies.patch),
is for hosts with no terminal to scroll (agent-dial). With `reply.read`, a swipe up on an agent's face opens
upstream's "latest result" reader for its whole reply (about 1,000 characters). With `speak`, the reader's
**[listen]** asks the host to read the reply aloud: the host sends 16 kHz audio down the cable and the dial
plays it on its speaker. It also lets questions carry about 1,000 characters instead of 255. A host that
advertises neither feature sees the stock behavior.

A fourth, optional patch, [patches/0004-wifi-beside-the-cable.patch](patches/0004-wifi-beside-the-cable.patch),
adds Wi-Fi next to the cable so the dial can sit on a charger anywhere in the house. Upstream has no radio on
purpose (the cable is the authorization), so this keeps the cable in charge: the network and a 32-byte secret are
given over the cable only, both sides prove the secret before anything else moves, and firmware updates are refused
over Wi-Fi. A dial never given a network never turns the radio on. It also trims Wi-Fi's buffers to fit the
internal memory the screen leaves free.

A fifth, optional patch, [patches/0005-turn-the-picture-180.patch](patches/0005-turn-the-picture-180.patch),
turns the picture and touch 180° for a dial hung from its cable (the cable comes out of the bottom). The host sends
`display.flip`; the dial keeps the choice.

A sixth, optional patch, [patches/0006-keep-the-screen-on.patch](patches/0006-keep-the-screen-on.patch),
makes the screen's turn-off time a setting. Upstream turns the screen off after 5 minutes without a touch; the
host sends `display.sleep` {minutes}, and `0` keeps it on. The dial keeps the choice.

A seventh, optional patch, [patches/0007-remove-from-dial.patch](patches/0007-remove-from-dial.patch),
adds "Remove from dial" to the controls menu for an agent that is not working. The dial sends `agent.hide`
{agentId}, and the host keeps that agent off the wheel until it has something new. Pulling down on a face opens
that menu (nothing on the glass opened it before). Both show only when the host lists `agent.hide` in its welcome,
so the stock Harness daemon never sees them.

An eighth, optional patch, [patches/0008-steadier-swipes.patch](patches/0008-steadier-swipes.patch), decides
a swipe on a face from the whole stroke instead of its first millimetre, where a thumb's up or down swipe often
leans sideways and used to do nothing.

A ninth, optional patch, [patches/0009-hide-button.patch](patches/0009-hide-button.patch), puts a `[ hide ]`
button at the foot of a finished agent's face (one that is not working or asking), from a host that lists
`agent.hide`. It sends the same `agent.hide` as the menu row.

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

## Getting back to stock firmware

Before the first flash, back up the whole flash (read-only):

```bash
python -m esptool --chip esp32s3 -p /dev/cu.usbmodemXXXX read_flash 0 ALL waveshare-factory.bin
```

To undo everything later:

```bash
scripts/restore-factory.sh /dev/cu.usbmodemXXXX waveshare-factory.bin
```

This firmware never burns eFuses (secure boot and flash encryption are off), so the ESP32-S3's built-in
ROM loader always stays available: hold BOOT while plugging in USB and the board accepts a new image
no matter what is in flash. The restore was tested on the first board.

## Which agents show up

With the **Harness daemon**, only agents started inside its own terminal show: run `hn` (or use the
Harness desktop app's terminal tiles), then `claude`, `codex` or `agy` inside it. Sessions started in a
plain terminal, the Claude desktop app, or other front ends (such as T3 Code) do not appear. This is how
the Harness daemon works, not a limit of this port.

The first board now runs **agent-dial** instead, a separate Mac-side app (github.com/dslansky/agent-dial,
private for now) that drives the same firmware: T3 Code conversations (Claude, Codex, Antigravity),
the Antigravity desktop app, and a second Mac over Tailscale, with local speech-to-text and its own
animated Antigravity character. It speaks the stock cable protocol, so the firmware is the same either way.

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
