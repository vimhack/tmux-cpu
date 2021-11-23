#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

cpu_temp_low_fg_color=""
cpu_temp_medium_fg_color=""
cpu_temp_high_fg_color=""

cpu_temp_low_default_fg_color="#[fg=green]"
cpu_temp_medium_default_fg_color="#[fg=yellow]"
cpu_temp_high_default_fg_color="#[fg=red]"

get_fg_color_settings() {
    cpu_temp_low_fg_color=$(get_tmux_option "@cpu_temp_low_fg_color" "$cpu_temp_low_default_fg_color")
    cpu_temp_medium_fg_color=$(get_tmux_option "@cpu_temp_medium_fg_color" "$cpu_temp_medium_default_fg_color")
    cpu_temp_high_fg_color=$(get_tmux_option "@cpu_temp_high_fg_color" "$cpu_temp_high_default_fg_color")
}

print_fg_color() {
    local cpu_temp=$($CURRENT_DIR/cpu_temp.sh | sed -e 's/[^0-9.]//')
    local cpu_temp_status=$(temp_status $cpu_temp)
    if [ $cpu_temp_status == "low" ]; then
        echo "$cpu_temp_low_fg_color"
    elif [ $cpu_temp_status == "medium" ]; then
        echo "$cpu_temp_medium_fg_color"
    elif [ $cpu_temp_status == "high" ]; then
        echo "$cpu_temp_high_fg_color"
    fi
}

main() {
    local update_interval=$(get_tmux_option $cpu_update_interval_option $cpu_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@cputempfgcolor_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            get_fg_color_settings
            print_fg_color
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@cputempfgcolor_previous_update_time" "$current_time"
            set_tmux_option "@cputempfgcolor_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@cputempfgcolor_previous_value")"
}

main
