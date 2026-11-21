#!/bin/sh
img="$1"
mode="$2"
[ -f "$img" ] || exit 1

# --- ajustes da animacao (awww) ---
TYPE="wipe"
DURATION="1.2"
FPS="60"

mkdir -p "$HOME/.cache"
printf '%s\n' "$img" > "$HOME/.cache/current-wallpaper"

if command -v awww >/dev/null 2>&1; then
  if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    setsid awww-daemon >/dev/null 2>&1 &
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      awww query >/dev/null 2>&1 && break
      sleep 0.2
    done
  fi
  if [ "$mode" = "instant" ]; then
    awww img "$img" --transition-type none
  else
    awww img "$img" --transition-type "$TYPE" --transition-duration "$DURATION" --transition-fps "$FPS"
  fi
  if pgrep -x hyprpaper >/dev/null 2>&1; then
    ( sleep 2; pkill -x hyprpaper ) >/dev/null 2>&1 &
  fi
else
  hyprctl hyprpaper preload "$img" >/dev/null 2>&1
  for mon in $(hyprctl monitors | awk '/^Monitor/{print $2}'); do
    hyprctl hyprpaper wallpaper "$mon,$img" >/dev/null 2>&1
  done
  hyprctl hyprpaper wallpaper ",$img" >/dev/null 2>&1
fi

( "$HOME/.local/bin/wall-accent" "$img" >/dev/null 2>&1 & )

[ "$2" = "instant" ] || notify-send -a Wallpaper -t 4000 -h string:image-path:"$img" "Wallpaper alterado" "$(basename "$img")" >/dev/null 2>&1 &
[ "$2" = "instant" ] || ( sleep 2; quickshell ipc call wallcolors show ) >/dev/null 2>&1 &
