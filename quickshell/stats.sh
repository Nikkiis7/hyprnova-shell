#!/bin/sh
t() { v=$(cat "$1" 2>/dev/null) || return; echo $((v / 1000)); }
for h in /sys/class/hwmon/hwmon*; do
  case "$(cat "$h/name" 2>/dev/null)" in
    k10temp) echo "t_cpu=$(t "$h/temp1_input")" ;;
    nvme)    echo "t_ssd=$(t "$h/temp1_input")" ;;
    amdgpu)  echo "t_gpu=$(t "$h/temp1_input")" ;;
  esac
done
for d in /sys/class/drm/card*/device; do
  if [ -r "$d/gpu_busy_percent" ]; then
    echo "gpu_use=$(cat "$d/gpu_busy_percent")"
    echo "vram=$(( $(cat "$d/mem_info_vram_used") / 1048576 ))/$(( $(cat "$d/mem_info_vram_total") / 1048576 )) MB"
    break
  fi
done
free -m | awk '/^Mem/{printf "ram=%d/%d MB\n", $3, $2}'
awk '{print "load=" $1 " " $2 " " $3}' /proc/loadavg
echo "dnd=$(dunstctl is-paused 2>/dev/null)"
