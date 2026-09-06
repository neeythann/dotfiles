#!/bin/sh
last=0
ts="T: down"
wt="W: n/a"
wloc=""
wtz=""
wlast=0
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
        if [ $(( now - wlast )) -ge 600 ]; then
            wloc=$(curl -s -m 10 "ipinfo.io/json" 2>/dev/null | jq -r '.city + ", " + .region' 2>/dev/null)
            wtz=$(curl -s -m 10 "ipinfo.io/json" 2>/dev/null | jq -r '.timezone // empty' 2>/dev/null)
            [ -n "$wloc" ] && [ "$wloc" != "null, null" ] || wloc=""
            [ -n "$wtz" ] && [ "$wtz" != "null" ] || wtz=""
            wj=""
            if [ -n "$wloc" ]; then
                wenc=$(printf '%s' "$wloc" | sed 's/ /+/g; s/,/%2C/g')
                wj=$(curl -s -m 10 "wttr.in/${wenc}?format=j1" 2>/dev/null)
            fi
            wlast="$now"
            t=$(printf '%s' "$wj" | jq -r '.current_condition[0].temp_F // empty' 2>/dev/null)
            desc=$(printf '%s' "$wj" | jq -r '.current_condition[0].weatherDesc[0].value // "?"' 2>/dev/null | tr -d ' ')
            if [ -n "$t" ]; then
                wt="W: ${wloc} ${t}°F $desc"
            else
                wt="W: ${wloc}"
            fi
            [ -n "$wloc" ] || wt="W: n/a"
        fi
        bcap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        bst=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        bnow=$(cat /sys/class/power_supply/BAT0/charge_now 2>/dev/null)
        bcur=$(cat /sys/class/power_supply/BAT0/current_now 2>/dev/null)
        case "$bst" in
            Full) s="FULL" ;;
            Charging) s="CHR" ;;
            Discharging) s="BAT" ;;
            *) s="$bst" ;;
        esac
        if [ -n "$bcap" ]; then
            bs="$s $bcap%"
        else
            bs="BAT n/a"
        fi
        if [ -n "$bnow" ] && [ -n "$bcur" ] && [ "$bcur" -gt 0 ] 2>/dev/null; then
            bh=$(( bnow / bcur ))
            bm=$(( (bnow * 60 / bcur) % 60 ))
            bs="$bs ${bh}h${bm}m"
        fi
        if [ -n "$wtz" ]; then
            ct=$(TZ="$wtz" date '+%a %b %d %H:%M:%S' 2>/dev/null)
        else
            ct=$(date '+%a %b %d %H:%M:%S')
        fi
        last="$now"
    fi
    case "$line" in
        '['|'{'|'}'|'')
            echo "$line"
            ;;
        *)
            printf '%s\n' "$line" | sed -e "s|^\(,\?\)\[|\1[{\"name\":\"weather\",\"full_text\":\"$wt\"},{\"name\":\"tailscale\",\"full_text\":\"$ts\"},|" -e 's|\[\(.*\)\]|[\1,{"name":"sound","full_text":"S: '"$vs"'"},{"name":"battery","full_text":"'"$bs"'"},{"name":"clock","full_text":"'"$ct"'"}]|'
            ;;
    esac
done
