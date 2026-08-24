#!/bin/sh
last=0
ts="T: down"
i3status | while IFS= read -r line; do
    now=$(date +%s)
    if [ "$now" -ne "$last" ]; then
        ip=$(tailscale ip -4 2>/dev/null)
        [ -n "$ip" ] && ts="T: $ip" || ts="T: down"
        last="$now"
    fi
    case "$line" in
        '['|'{'*'}'|'')
            echo "$line"
            ;;
        *)
            printf '%s\n' "$line" | sed "s/^\(\[\|,\)/\1{\"name\":\"tailscale\",\"full_text\":\"$ts\"},/"
            ;;
    esac
done
