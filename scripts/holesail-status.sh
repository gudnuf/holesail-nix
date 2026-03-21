#!/usr/bin/env bash
set -euo pipefail

# holesail-status: show running holesail tunnels

get_role() {
  local execstart="$1"
  if [[ "$execstart" == *"--filemanager"* ]]; then
    echo "filemanager"
  elif [[ "$execstart" == *"--connect"* ]]; then
    echo "client"
  elif [[ "$execstart" == *"--live"* ]]; then
    echo "server"
  else
    echo "unknown"
  fi
}

get_port() {
  local execstart="$1" role="$2"
  local flag
  if [[ "$role" == "server" ]]; then
    flag="--live"
  else
    flag="--port"
  fi
  echo "$execstart" | sed -n "s/.*${flag} \([0-9]*\).*/\1/p" | head -1 || echo "—"
}

get_key() {
  local unit="$1" role="$2"
  if [[ "$role" == "client" ]]; then
    echo "—"
    return
  fi
  # try journal first
  local key
  key=$(journalctl -u "$unit" --no-pager -o cat 2>/dev/null \
    | grep -oE 'hs://[a-zA-Z0-9]+' | tail -1) || true
  if [[ -n "$key" ]]; then
    # truncate for table view
    if [[ ${#key} -gt 30 ]]; then
      echo "${key:0:27}..."
    else
      echo "$key"
    fi
  else
    echo "(check journal)"
  fi
}

detail_view() {
  local name="$1"
  local unit="holesail-${name}.service"

  if ! systemctl cat "$unit" &>/dev/null; then
    echo "Error: no tunnel named '$name' found"
    exit 1
  fi

  local status
  status=$(systemctl is-active "$unit" 2>/dev/null || echo "inactive")
  local execstart
  execstart=$(systemctl show "$unit" -p ExecStart --value 2>/dev/null || echo "")
  local role
  role=$(get_role "$execstart")
  local port
  port=$(get_port "$execstart" "$role")

  local since=""
  if [[ "$status" == "active" ]]; then
    since=" since $(systemctl show "$unit" -p ActiveEnterTimestamp --value 2>/dev/null)"
  fi

  echo " Tunnel: $name"
  echo " Role:   $role"
  echo " Status: $status$since"
  echo " Port:   $port"

  local host
  host=$(echo "$execstart" | sed -n 's/.*--host \([^ ]*\).*/\1/p' | head -1)
  host="${host:-127.0.0.1}"
  echo " Host:   $host"

  if [[ "$role" != "client" ]]; then
    local key
    key=$(journalctl -u "$unit" --no-pager -o cat 2>/dev/null \
      | grep -oE 'hs://[a-zA-Z0-9]+' | tail -1) || true
    if [[ -n "$key" ]]; then
      echo " Key:    $key"
    fi
    local keyfile="/var/lib/holesail-${name}/key"
    if [[ -f "$keyfile" ]]; then
      echo ""
      echo " Raw key file: $keyfile"
    fi
  fi

  echo ""
  echo " Journal: journalctl -u holesail-${name} -f"
}

table_view() {
  local units
  units=$(systemctl list-units 'holesail-*.service' --no-legend --no-pager 2>/dev/null || true)

  if [[ -z "$units" ]]; then
    echo "No holesail tunnels found."
    exit 0
  fi

  printf "\n %-16s %-14s %-10s %-7s %s\n" "Tunnel" "Role" "Status" "Port" "Key"
  printf " %s\n" "──────────────────────────────────────────────────────────────"

  while IFS= read -r line; do
    local unit
    unit=$(echo "$line" | awk '{print $1}')
    # strip holesail- prefix and .service suffix
    local name="${unit#holesail-}"
    name="${name%.service}"

    local status
    status=$(systemctl is-active "$unit" 2>/dev/null || echo "inactive")
    local execstart
    execstart=$(systemctl show "$unit" -p ExecStart --value 2>/dev/null || echo "")
    local role
    role=$(get_role "$execstart")
    local port
    port=$(get_port "$execstart" "$role")
    local key
    key=$(get_key "$unit" "$role")

    printf " %-16s %-14s %-10s %-7s %s\n" "$name" "$role" "$status" "$port" "$key"
  done <<< "$units"

  echo ""
}

if [[ $# -ge 1 ]]; then
  detail_view "$1"
else
  table_view
fi
