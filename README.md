# Hive ESP8266 (NodeMCU)

Small set of Lua scripts for NodeMCU (ESP8266): LED control, SSD1306 display fetcher for HSL stops, and helper tooling to upload and manage files on the device.

## Quick overview
- Flash NodeMCU firmware (see `Makefile` `flash` target).
- Upload Lua sources and GraphQL query (`Makefile` `upload` / `upload-c`).
- Manage `init.lua` and open a serial terminal (`Makefile` `rm-init`, `term`).
- Example scripts live in `archive/` (blink, color, wifi examples).

## Prerequisites
- Python + `esptool.py` (for flashing firmware).
- `nodemcu-uploader` (recommended for uploading files and opening a REPL). Install with:

```bash
pip install nodemcu-uploader
```

- If using a CH341 USB-serial adapter on macOS, install the driver: https://www.wch.cn/downloads/CH341SER_MAC_ZIP.html

- An I2C SSD1306 display (128x64) and a NodeMCU/ESP8266 board.

## Hardware wiring
- Display (SSD1306) defaults in the code to I2C address `0x3C`.
- Pins used in `parse.lua` / `hsl.lua`: SDA = GPIO2, SCL = GPIO1.
- RGB LED pins (in `led.lua`): RED=7, GREEN=5, BLUE=6 (PWM-aware).

## Build & upload (Makefile)
The included `Makefile` provides convenience targets. Typical workflow:

- Format file storage and upload compiled scripts:

```bash
make format      # remote file format/check
make upload-c    # upload .gql and compile+upload .lua files
```

- Upload plain files (no compile):

```bash
make upload
```

- Remove `init.lua` (useful when debugging) and restart the node:

```bash
make rm-init
```

- Flash firmware to the device (replace `PORT` and `FIRMWARE` variables in the Makefile if needed):

```bash
make flash
# or run esptool manually:
esptool.py --port /dev/ttyUSB0 write_flash -fm dio -fs 4MB 0x00000 firmware/nodemcu-*.bin
# Press RST when instructed
```

- Open a terminal to the device:

```bash
make term
# or use screen:
screen /dev/ttyUSB0 115200
```

- List files on device:

```bash
make ls
```

## Running the HSL display example
- Customize `query.gql` (the GraphQL `StopDetails` query) if you want to use a different stop ID.
- The `hsl.lua` module posts the GraphQL query to Digitransit and uses a subscription key (embedded) to fetch stop times. Edit `_payload` in `hsl.lua` to change the `stopId` if needed.

Typical flow:
1. Upload files to the device (`make upload-c`).
2. Restart the node (`make restart` or remove `init.lua` + start manually).
3. Open a terminal (`make term`) to watch logs and confirm `hsl.fetch()` is called periodically.

Notes:
- The display update code is in `parse.lua` and targets a 128x64 SSD1306 using `u8g2`.
- If `rtctime` is not synced, arrival times show `?` — the `init.lua` performs SNTP sync at startup.

## Examples & archive
See the `archive/` folder for small example scripts:
- `blink.lua` — simple LED blink sample
- `color.lua` / `led_gpio.lua` — LED demos
- `parse2.lua`, `wifi.lua`, `screen.lua` — helper examples

## Troubleshooting
- Serial port not found?
  - Run `make where` to list recognized `/dev/` serial devices and update `PORT` in the `Makefile`.
- Upload fails?
  - Verify device is in normal mode (not in flash mode), try `make rm-init` then `make upload`.
- Firmware flashing issues?
  - Double-check the correct `FIRMWARE` file and port, and press RST when prompted.

## Security & keys
Do **not** commit secrets to the repository. Use the included `.env.example` as a template and create a local `.env` with your private values (now including Wi‑Fi creds):

- Copy `.env.example` → `.env` and fill in `DIGITRANSIT_KEY`, `WIFI_SSID`, and `WIFI_PWD`.
- `.env` is ignored by Git; `secrets.lua` is generated from `.env` and is also ignored.

### Generate & upload secrets locally
```bash
cp .env.example .env      # edit .env
make upload-secrets       # generates secrets.lua and uploads it to the device
```

`init.lua` will read `WIFI_SSID` and `WIFI_PWD` from `secrets.lua` when present; otherwise it falls back to the previous defaults (for local dev only).

### Generate secrets in CI (GitHub Actions)
You can generate `secrets.lua` in GitHub Actions and download it as an artifact:
1. Add repository Secrets: `DIGITRANSIT_KEY`, `WIFI_SSID`, `WIFI_PWD` in your repo settings.
2. Run the `Generate Secrets` workflow (Actions → Generate Secrets) — it will produce a downloadable `secrets` artifact containing `secrets.lua`.

### Automated deploy script
For convenience, there's `scripts/deploy.sh` which:
- Generates `secrets.lua` locally
- Uploads `secrets.lua` to the device
- Uploads compiled Lua files and restarts the node

Usage:
```bash
./scripts/deploy.sh /dev/ttyUSB0  # specify port (optional, defaults to Makefile PORT)
```

This keeps secrets out of source control while making it easy to deploy them to your hardware.
