#!/bin/sh

set -eu

mkdir -p zephyr

cat > zephyr/module.yml <<'EOF'
build:
  cmake: .
  kconfig: Kconfig
  settings:
    board_root: .
    dts_root: .
EOF
