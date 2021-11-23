#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

print_fan_speed() {
    speed=$(istats fan speed --no-graphs --no-labels | head -1 | sed 's/ RPM/rpm/')
    echo -n $speed
}

main() {
    local update_interval=$(get_tmux_option $cpu_update_interval_option $cpu_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@fanspeed_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            print_fan_speed
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@fanspeed_previous_update_time" "$current_time"
            set_tmux_option "@fanspeed_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@fanspeed_previous_value")"
}

main
