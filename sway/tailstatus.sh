#!/bin/sh
i3status | while IFS= read -r line; do
    case "$line" in
        '['|'{'*'}'|'')
            echo "$line"
            ;;
        *)
            ts=$(tailscale ip -4 2>/dev/null)
            [ -n "$ts" ] && ts="T: $ts" || ts="T: down"
            printf '%s' "$line" | sed "s/^\(\[\|,\)/\1{\"name\":\"tailscale\",\"full_text\":\"$ts\"},/"
            ;;
    esac
done
