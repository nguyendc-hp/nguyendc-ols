#!/usr/bin/env bash

# ======================================
# Plugin: Health Check
# Project: nguyendc-ols
# ID: healthcheck
# Category: OPS
# ======================================

HEALTH_CPU_THRESHOLD_KEY="HEALTH_CPU_THRESHOLD"      # %
HEALTH_RAM_THRESHOLD_KEY="HEALTH_RAM_THRESHOLD"      # %
HEALTH_LOAD_THRESHOLD_KEY="HEALTH_LOAD_THRESHOLD"    # 1-minute load
HEALTH_DISK_THRESHOLD_KEY="HEALTH_DISK_THRESHOLD"    # % / partition

health_default_thresholds() {
  # Giá trị mặc định nếu chưa set
  local cpu ram load disk
  cpu="$(state_get "$HEALTH_CPU_THRESHOLD_KEY" || echo "")"
  ram="$(state_get "$HEALTH_RAM_THRESHOLD_KEY" || echo "")"
  load="$(state_get "$HEALTH_LOAD_THRESHOLD_KEY" || echo "")"
  disk="$(state_get "$HEALTH_DISK_THRESHOLD_KEY" || echo "")"

  [[ -z "$cpu" ]]  && state_set "$HEALTH_CPU_THRESHOLD_KEY" "85"
  [[ -z "$ram" ]]  && state_set "$HEALTH_RAM_THRESHOLD_KEY" "85"
  [[ -z "$load" ]] && state_set "$HEALTH_LOAD_THRESHOLD_KEY" "4.0"
  [[ -z "$disk" ]] && state_set "$HEALTH_DISK_THRESHOLD_KEY" "90"
}

health_get_thresholds() {
  health_default_thresholds
  CPU_THR="$(state_get "$HEALTH_CPU_THRESHOLD_KEY")"
  RAM_THR="$(state_get "$HEALTH_RAM_THRESHOLD_KEY")"
  LOAD_THR="$(state_get "$HEALTH_LOAD_THRESHOLD_KEY")"
  DISK_THR="$(state_get "$HEALTH_DISK_THRESHOLD_KEY")"
}

health_calc_cpu_usage() {
  # đo nhanh bằng top -bn1
  local usage
  # Lấy cột %Cpu(s): us,sy,id,wa,... -> lấy "id" rồi 100-id
  usage=$(top -bn1 | awk '/Cpu\(s\)/ {print 100 - $8}')
  printf "%.0f\n" "$usage" 2>/dev/null
}

health_calc_ram_usage() {
  local usage
  usage=$(free | awk '/Mem:/ {print $3*100/$2}')
  printf "%.0f\n" "$usage" 2>/dev/null
}

health_get_load1() {
  awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"
}

health_get_root_disk_usage() {
  df -P / | awk 'NR==2 {gsub("%","",$5); print $5}'
}

health_format_summary() {
  local cpu="$1"
  local ram="$2"
  local load="$3"
  local disk="$4"

  echo "Server health summary:
- CPU usage : ${cpu}%
- RAM usage : ${ram}%
- Loadavg 1m: ${load}
- Disk /    : ${disk}%"
}

healthcheck_run_once() {
  health_get_thresholds

  local cpu ram load disk
  cpu="$(health_calc_cpu_usage)"
  ram="$(health_calc_ram_usage)"
  load="$(health_get_load1)"
  disk="$(health_get_root_disk_usage)"

  local summary
  summary="$(health_format_summary "$cpu" "$ram" "$load" "$disk")"

  echo "$summary"
  echo
  echo "Thresholds:"
  echo " - CPU  > ${CPU_THR}%"
  echo " - RAM  > ${RAM_THR}%"
  echo " - LOAD > ${LOAD_THR}"
  echo " - DISK > ${DISK_THR}% (/ partition)"
  echo

  local alert=0
  local alert_msg="⚠️ *Healthcheck Alert*:

${summary}

Ngưỡng:
CPU>${CPU_THR}%, RAM>${RAM_THR}%, LOAD>${LOAD_THR}, DISK>${DISK_THR}%
"

  (( cpu > CPU_THR )) && alert=1
  (( ram > RAM_THR )) && alert=1

  # So sánh load float
  awk -v l="$load" -v t="$LOAD_THR" 'BEGIN {exit !(l>t)}'
  [[ $? -eq 0 ]] && alert=1

  (( disk > DISK_THR )) && alert=1

  if [[ "$alert" -eq 1 ]]; then
    echo ">>> Phát hiện vượt ngưỡng, nên gửi cảnh báo Telegram (nếu đã cấu hình)."
    # nếu có hàm telegram_send_message thì gọi
    if [[ "$(type -t telegram_send_message)" == "function" ]]; then
      telegram_send_message "$alert_msg" || true
    else
      echo "(Chưa có plugin Telegram hoặc chưa load hàm telegram_send_message)"
    fi
  else
    echo "Mọi thông số đang trong ngưỡng an toàn."
  fi
}

healthcheck_config_thresholds() {
  health_get_thresholds
  echo "Ngưỡng hiện tại:"
  echo " - CPU  : ${CPU_THR}%"
  echo " - RAM  : ${RAM_THR}%"
  echo " - LOAD : ${LOAD_THR}"
  echo " - DISK : ${DISK_THR}% (/ partition)"
  echo

  read -r -p "CPU threshold % (Enter để giữ ${CPU_THR}): " cpu
  read -r -p "RAM threshold % (Enter để giữ ${RAM_THR}): " ram
  read -r -p "LOAD threshold   (Enter để giữ ${LOAD_THR}): " load
  read -r -p "DISK threshold % (Enter để giữ ${DISK_THR}): " disk

  [[ -n "$cpu" ]]  && state_set "$HEALTH_CPU_THRESHOLD_KEY" "$cpu"
  [[ -n "$ram" ]]  && state_set "$HEALTH_RAM_THRESHOLD_KEY" "$ram"
  [[ -n "$load" ]] && state_set "$HEALTH_LOAD_THRESHOLD_KEY" "$load"
  [[ -n "$disk" ]] && state_set "$HEALTH_DISK_THRESHOLD_KEY" "$disk"

  log_info "Đã cập nhật ngưỡng healthcheck."
}

healthcheck_show_status_line() {
  health_get_thresholds
  echo "CPU>${CPU_THR}%, RAM>${RAM_THR}%, LOAD>${LOAD_THR}, DISK>${DISK_THR}% (/)"
}

healthcheck_menu() {
  while true; do
    clear
    echo "══════════════════════════════════════════════"
    echo "            Health Check (Plugin)"
    echo "                nguyendc-ols"
    echo "══════════════════════════════════════════════"
    echo -n "Ngưỡng: "
    healthcheck_show_status_line
    echo
    echo "1) Chạy healthcheck ngay"
    echo "2) Cấu hình ngưỡng cảnh báo"
    echo "0) Quay lại menu trước"
    echo
    read -rp "Chọn một tuỳ chọn: " choice
    case "$choice" in
      1) healthcheck_run_once;        read -rp "Nhấn Enter để tiếp tục..." ;;
      2) healthcheck_config_thresholds; read -rp "Nhấn Enter để tiếp tục..." ;;
      0) break ;;
      *) echo "Lựa chọn không hợp lệ."; sleep 1 ;;
    esac
  done
}

# CLI: ./nguyendc-ols.sh healthcheck run
healthcheck_cli() {
  local subcmd="$1"
  case "$subcmd" in
    run|"")
      healthcheck_run_once
      ;;
    *)
      echo "Healthcheck CLI:"
      echo "  healthcheck run   - chạy healthcheck một lần"
      return 1
      ;;
  esac
}

ndc_register_plugin \
  "healthcheck" \
  "Health Check" \
  "OPS" \
  "Kiểm tra CPU/RAM/load/disk và gửi cảnh báo Telegram nếu quá tải" \
  "healthcheck_menu"
