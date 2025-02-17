#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/helpers.sh"

cpu_percentage_format="%3.1f%%"

print_cpu_percentage() {
    cpu_percentage_format=$(get_tmux_option "@cpu_percentage_format" "$cpu_percentage_format")

    if command_exists "iostat"; then

        if is_linux_iostat; then
            cached_eval iostat -c 1 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
        elif is_osx; then
            cached_eval iostat -c 2 disk0 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$6} END {printf(format, usage)}' | sed 's/,/./'
        elif is_freebsd || is_openbsd; then
            cached_eval iostat -c 2 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
        else
            echo "Unknown iostat version please create an issue"
        fi
    elif command_exists "sar"; then
        cached_eval sar -u 1 1 | sed '/^\s*$/d' | tail -n 1 | awk -v format="$cpu_percentage_format" '{usage=100-$NF} END {printf(format, usage)}' | sed 's/,/./'
    else
        if is_cygwin; then
            usage="$(cached_eval WMIC cpu get LoadPercentage | grep -Eo '^[0-9]+')"
            printf "$cpu_percentage_format" "$usage"
        else
            load=$(cached_eval ps -aux | awk '{print $3}' | tail -n+2 | awk '{s+=$1} END {print s}')
            cpus=$(cpus_number)
            echo "$load $cpus" | awk -v format="$cpu_percentage_format" '{printf format, $1/$2}'
        fi
    fi
}

main() {
    local update_interval=$(get_tmux_option $cpu_update_interval_option $cpu_update_interval_default)
    local current_time=$(date "+%s")
    local previous_update=$(get_tmux_option "@cpupercentage_previous_update_time")
    local delta=$((current_time - previous_update))

    if [[ -z "$previous_update" ]] || [[ $delta -ge $update_interval ]]; then
        local value=$(
            print_cpu_percentage
        )

        if [ "$?" -eq 0 ]; then
            set_tmux_option "@cpupercentage_previous_update_time" "$current_time"
            set_tmux_option "@cpupercentage_previous_value" "$value"
        fi
    fi

    echo -n "$(get_tmux_option "@cpupercentage_previous_value")"
}

main
