#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

print_fan_speed() {
    speed=$(istats fan speed --no-graphs --no-labels | head -1 | sed 's/ RPM/rpm/')
    echo -n $speed
}

main() {
    print_fan_speed
}

main
