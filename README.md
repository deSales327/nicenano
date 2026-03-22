# TPS65 ZMK Firmware for nice!nano-Compatible Pro Micro nRF52840 Boards

This repository is a ZMK config plus a small repo-root module for Sofle/TPS65 shield wiring.

The actual IQS5xx trackpad driver is pulled in as an external ZMK module from
[`AYM1607/zmk-driver-azoteq-iqs5xx`](https://github.com/AYM1607/zmk-driver-azoteq-iqs5xx),
pinned in `config/west.yml`.

The sample build matrix is aimed at a Sofle using nice!nano controllers:

- `tps65_breadboard`: single-board breadboard test target for a nice!nano-compatible Pro Micro
  nRF52840 and a TPS65.
- `sofle_left tps65_central` + `sofle_right`: trackpad mounted on the central half.
- `sofle_left tps65_listener` + `sofle_right tps65_peripheral`: trackpad mounted on the right
  peripheral half and forwarded to the central over ZMK input split.

## Wiring Assumptions

The add-on shields assume the following defaults in
`boards/shields/tps65_common/tps65_device.dtsi`:

- `SDA`: Pro Micro `D2`
- `SCL`: Pro Micro `D3`
- `RDY`: Pro Micro `D8`
- `RST`: Pro Micro `D9`
- `VCC`: `3V3`
- `GND`: `GND`

This is intentional:

- In the ZMK `nice_nano` board definition used by this repo, `pro_micro_i2c` maps to `D2`/`D3`.
- `D8`/`D9` are then a clean choice for the TPS65 `RDY` and `RST` lines.

If your wiring or physical orientation differs, adjust
`boards/shields/tps65_common/tps65_device.dtsi`:

- Change `rdy-gpios` / `reset-gpios` to match your wiring.
- Add `flip-x;`, `flip-y;`, `switch-xy;`, `natural-scroll-x;`, or `natural-scroll-y;` on the
  `tps65` node if needed.

## Driver Features

The pinned IQS5xx module supports:

- Trackpad movement.
- Single-finger tap as left click.
- Two-finger tap as right click.
- Press-and-hold for click-drag.
- Vertical and horizontal scroll.

The default node in this repo enables all of those except any axis inversion that depends on your
physical mounting.

## Recommended First Wiring

For an initial breadboard test with a nice!nano-compatible `V1940 ProMicro NRF52840`:

- TPS65 `VCC` -> controller `3V3`
- TPS65 `GND` -> controller `GND`
- TPS65 `SDA` -> controller `D2`
- TPS65 `SCL` -> controller `D3`
- TPS65 `RDY` -> controller `D8`
- TPS65 `RST` -> controller `D9`

The single-board `tps65_breadboard` shield also defines one dummy key on `D4` with an internal
pull-up. You do not need to wire anything to `D4`; it exists only so ZMK has a stable one-key
matrix while you test the trackpad.

For first bring-up, I recommend using the dedicated breadboard target:

- build: `tps65_breadboard`

If you want to move on to a real Sofle half after that:

- left build: `sofle_left tps65_central`
- right build: `sofle_right`

## Advanced Split-Peripheral Build

If you specifically want the trackpad on the right split peripheral, use:

```sh
west init -l config
west update
west zephyr-export
west build -s zmk/app -d build/sofle-left-rightpad -b nice_nano -- \
  -DSHIELD="sofle_left tps65_listener" \
  -DZMK_CONFIG="$PWD/config" \
  -DZMK_EXTRA_MODULES="$PWD"
west build -s zmk/app -d build/sofle-right-rightpad -b nice_nano -- \
  -DSHIELD="sofle_right tps65_peripheral" \
  -DZMK_CONFIG="$PWD/config" \
  -DZMK_EXTRA_MODULES="$PWD"
```

For initial breadboard testing, ignore this section and use the dedicated `tps65_breadboard`
commands in `Producing The UF2` below.

## Producing The UF2

There are two practical ways to get the `.uf2`:

### GitHub Actions

This is the easiest path if you do not already have the full ZMK toolchain installed.

1. Put this repository on GitHub.
2. Push to your branch.
3. Open the Actions tab and run or wait for the `Build Firmware` workflow in
   `.github/workflows/build.yml`.
4. Download the workflow artifact zip.
5. Inside the zip, use the matching `.uf2` file:
   - `tps65-breadboard` for the single-board breadboard test
   - `sofle-left-tps65-central` for the left/central trackpad test
   - `sofle-right-no-trackpad` for the matching right half

The workflow creates the repo-root `zephyr/module.yml` file on the runner by calling
`./scripts/prepare-module.sh`, so you do not need to commit your local `west update` checkout.

### Local Build

If you want to build locally, install ZMK's normal local prerequisites first: `west`, `cmake`,
Python dependencies, Zephyr SDK/toolchain, etc.

Then run:

```sh
west init -l config
west update
west zephyr-export
west packages pip --install

sh ./scripts/prepare-module.sh

cd zephyr
west sdk install --toolchains arm-zephyr-eabi
cd ..

west build -s zmk/app -d build/breadboard -b nice_nano -- \
  -DSHIELD="tps65_breadboard" \
  -DZMK_CONFIG="$PWD/config" \
  -DZMK_EXTRA_MODULES="$PWD"

west build -s zmk/app -d build/left -b nice_nano -- \
  -DSHIELD="sofle_left tps65_central" \
  -DZMK_CONFIG="$PWD/config" \
  -DZMK_EXTRA_MODULES="$PWD"

west build -s zmk/app -d build/right -b nice_nano -- \
  -DSHIELD="sofle_right" \
  -DZMK_CONFIG="$PWD/config" \
  -DZMK_EXTRA_MODULES="$PWD"
```

The resulting files will be in:

- `build/breadboard/zephyr/zmk.uf2`
- `build/left/zephyr/zmk.uf2`
- `build/right/zephyr/zmk.uf2`

To flash a nice!nano-compatible board, double-tap reset so it mounts as a UF2 drive, then copy the
appropriate `zmk.uf2` onto it.

If `west sdk install` errors with `ModuleNotFoundError: No module named 'patoolib'`, it means the
Zephyr Python requirements were not installed yet; run `west packages pip --install` first.

## Board Choice

If your controller is a `V1940 ProMicro NRF52840`, it is typically a nice!nano-v2-compatible clone,
so this repo intentionally builds with `board: nice_nano`.
