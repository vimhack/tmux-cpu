#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

ram_percentage_format="%3.1f%%"

sum_macos_vm_stats() {
    grep -Eo '[0-9]+' |
        awk '{ a += $1 * 4096 } END { print a }'
}

print_ram_percentage() {
    ram_percentage_format=$(get_tmux_option "@ram_percentage_format" "$ram_percentage_format")

    if command_exists "free"; then
        cached_eval free | awk -v format="$ram_percentage_format" '$1 ~ /Mem/ {printf(format, 100*$3/$2)}'
    elif command_exists "vm_stat"; then
        # page size of 4096 bytes
        stats="$(cached_eval vm_stat)"

        used_and_cached=$(
            echo "$stats" |
                grep -E "(Pages active|Pages inactive|Pages speculative|Pages wired down|Pages occupied by compressor)" |
                sum_macos_vm_stats
        )

        cached=$(
            echo "$stats" |
                grep -E "(Pages purgeable|File-backed pages)" |
                sum_macos_vm_stats
        )

        free=$(
            echo "$stats" |
                grep -E "(Pages free)" |
                sum_macos_vm_stats
        )

        used=$(($used_and_cached - $cached))
        total=$(($used_and_cached + $free))

        echo "$used $total" | awk -v format="$ram_percentage_format" '{printf(format, 100*$1/$2)}'
    fi
}

main() {
    local update_interval=$(get_tmux_option $cpu_update_interval_option $cpu_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@rampercentage_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            print_ram_percentage
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@rampercentage_previous_update_time" "$current_time"
            set_tmux_option "@rampercentage_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@rampercentage_previous_value")"
}

main
