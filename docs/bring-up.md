# Bring-up checklist (first time on a real board)

Do these in order. Each step tells you what "good" looks like in the serial log, so a failure points at
one thing.

## 0. Before plugging in

- Activate ESP-IDF: `. ~/esp/esp-idf-v5.5.4/export.sh`
- Build: `scripts/setup.sh --build`
- If the Harness daemon is running, stop its device connection. Only one program can use the serial
  port at a time.

## 1. Find the port

Plug the board into the Mac with USB-C. Then:

```bash
ls /dev/cu.usbmodem*
```

If nothing shows up, hold BOOT, tap PWR (or replug), release BOOT. That forces the chip into download
mode.

## 2. Back up the Waveshare factory firmware (optional, recommended)

This only reads. It lets you go back to the stock demo later.

```bash
python -m esptool --chip esp32s3 -p /dev/cu.usbmodemXXXX read_flash 0 ALL waveshare-factory.bin
```

## 3. First flash (writes bootloader + partition table + app)

**Confirmation point.** The first flash has to replace the Waveshare bootloader and partition table,
because the stock layout (one 8 MB app + 7 MB storage) is different from the Harness layout (two app
slots for updates). This writes flash only. It does not touch eFuses (the one-time-programmable
settings that can actually brick a chip). The ESP32-S3's built-in ROM loader always survives, so a bad
flash is recoverable over USB by repeating step 1 and flashing again.

```bash
cd work/openharness/devices/harness-device/firmware
idf.py -p /dev/cu.usbmodemXXXX flash monitor
```

Later flashes of just the app can use `idf.py -p PORT app-flash` which leaves the bootloader alone.

## 4. Read the boot log

| Look for | Means |
|---|---|
| `board waveshare-1.75c: touch=cst9217 pmic=yes rst=1/2 (ack 34,5A,6B)` | Detection worked. |
| `board cst9217+axp2101: ... rst=39/40` | IMU did not answer. Run the probe build (step 7) and report the `ack` line. |
| Panel lights up with the Harness UI | Display reset on GPIO1 is right. |
| Black panel, log otherwise fine | Check the panel reset; try the probe build. |

## 5. Touch

Tap and swipe. If taps land on the opposite side of the screen, the touch mirror is wrong for this
module: flip `touch_mirror` for the Waveshare row in `board_table.c`.

## 6. Buttons, power, audio

- PWR short tap: should act as the Harness side button (back / stop / screen off).
- PWR long press: AXP2101 hardware restart (by design, firmware never sees it).
- BOOT held at power-on: factory reset of saved settings.
- Battery icon: only meaningful with a LiPo on the BAT connector; on USB alone it should show "on
  external power".
- Push-to-talk / voice: speak a task. If capture is silent or garbled, the ES7210 slot layout is the
  suspect (Waveshare wires mics to MIC1/MIC2 and the speaker loopback to MIC3 for echo cancelling).

## 7. Probe build (only if something above failed)

```bash
idf.py -DBOARD_PROBE=1 build && idf.py -p PORT app-flash monitor
```

It scans the whole I2C bus, pulses each candidate reset pin and reads the touch chip raw. Paste the
output into an issue.

## 8. Connect to Harness

Exit the monitor (Ctrl-]). Start the daemon on the Mac (`harness start`). The device should show your
Claude Code, Codex and agy sessions.

Check the daemon log for a firmware offer. There should be none: it only offers updates to boards it
knows by name, and `waveshare-1.75c` is not on that list (`cli/src/cable/fwPush.ts`, `otaKeyForBoard`).
