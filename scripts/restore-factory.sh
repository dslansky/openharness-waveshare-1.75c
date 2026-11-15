#!/usr/bin/env bash
# Escape hatch: put the board back exactly as it was before Harness was flashed.
#
#   scripts/restore-factory.sh /dev/cu.usbmodemXXXX path/to/factory-backup.bin
#
# The backup is the full-flash image made with `esptool read_flash 0 ALL` before the first flash
# (docs/bring-up.md, step 2). Writing it back replaces everything: bootloader, partition table, app.
#
# If the board does not show up as a serial port: hold BOOT, plug in USB (or tap PWR), release BOOT.
# That starts the loader built into the chip itself, which no firmware can remove.
set -euo pipefail

port="${1:?usage: restore-factory.sh PORT BACKUP.bin}"
image="${2:?usage: restore-factory.sh PORT BACKUP.bin}"
[ -f "$image" ] || { echo "no such file: $image"; exit 1; }

size=$(stat -f %z "$image" 2>/dev/null || stat -c %s "$image")
echo "Restoring $image ($size bytes) to $port. This overwrites the whole flash."
python -m esptool --chip esp32s3 -p "$port" -b 921600 write_flash --flash_mode keep --flash_freq keep --flash_size keep 0x0 "$image"
echo "Done. Unplug and replug the board; it should boot the original firmware."
