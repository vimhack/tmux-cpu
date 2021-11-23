#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

cpu_temp_format="%2.0f"
cpu_temp_unit="C"

print_cpu_temp() {
    cpu_temp_format=$(get_tmux_option "@cpu_temp_format" "$cpu_temp_format")
    cpu_temp_unit=$(get_tmux_option "@cpu_temp_unit" "$cpu_temp_unit")

    if command_exists "istats"; then
        temp=$(istats cpu temp --no-graphs --no-labels)
        echo -n $temp
    elif command_exists "sensors"; then
        ([ "$cpu_temp_unit" == F ] && sensors -f || sensors) | sed -e 's/^Tccd/Core /' | awk -v format="$cpu_temp_format$cpu_temp_unit" '/^Core [0-9]+/ {gsub("[^0-9.]", "", $3); sum+=$3; n+=1} END {printf(format, sum/n)}'
    fi
}

main() {
    local update_interval=$(get_tmux_option $cpu_update_interval_option $cpu_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@cputemp_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            print_cpu_temp
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@cputemp_previous_update_time" "$current_time"
            set_tmux_option "@cputemp_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@cputemp_previous_value")"
}

main
