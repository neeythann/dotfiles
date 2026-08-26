#!/bin/sh
last=0
ts="T: down"
i3status | while IFS= read -r line; do
    now=$(date +%s)
    if [ "$now" -ne "$last" ]; then
        ip=$(tailscale ip -4 2>/dev/null)
        [ -n "$ip" ] && ts="T: $ip" || ts="T: down"
        out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
        case "$out" in
            *Muted*)
                vs="MUTED"
                ;;
            *Volume:*[0-9.]*)
                vs=$(printf '%s\n' "$out" | sed 's/.*Volume: *//')
                vs=$(awk -v v="$vs" 'BEGIN{printf "%.0f%%", v*100}')
                ;;
            *)
                vs="n/a"
                ;;
        esac
        last="$now"
    fi
    case "$line" in
        '['|'{'|'}'|'')
            echo "$line"
            ;;
        *)
            printf '%s\n' "$line" | sed "s/^\(,\?\)\[/\1[{\"name\":\"tailscale\",\"full_text\":\"$ts\"},{\"name\":\"sound\",\"full_text\":\"S: $vs\"},/"
            ;;
    esac
done
