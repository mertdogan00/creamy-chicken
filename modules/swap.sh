# path: modules/swap.sh
#--- Swap Setup ---#

info "Configuring swap..."

swap_enabled="${SWAP_ENABLED:-yes}"
swap_multiplier="${SWAP_MULTIPLIER:-1}"
swap_swappiness="${SWAP_SWAPPINESS:-10}"
swapfile="/swapfile"

if [[ "$swap_enabled" != "yes" ]]; then
  info "SWAP_ENABLED is not yes. Skipping swap setup."
  mark_done "swap"
  return
fi

mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
if [[ -z "$mem_kb" || ! "$mem_kb" =~ ^[0-9]+$ ]]; then
  error "Unable to determine system memory."
  exit 1
fi

swap_mb="$(( (mem_kb / 1024) * swap_multiplier ))"
if [[ "$swap_mb" -le 0 ]]; then
  error "Invalid swap size calculated: ${swap_mb}MB"
  exit 1
fi

if swapon --show=NAME | grep -qx "$swapfile"; then
  info "Swap already active: $swapfile"
else
  if [[ ! -f "$swapfile" ]]; then
    info "Creating swapfile (${swap_mb}MB)..."
    dd if=/dev/zero of="$swapfile" bs=1M count="$swap_mb" status=progress
    chmod 600 "$swapfile"
    mkswap "$swapfile"
  fi
  swapon "$swapfile"
fi

if ! awk '($1=="/swapfile"){found=1} END{exit !found}' /etc/fstab; then
  printf "%s\n" "/swapfile none swap sw 0 0" >> /etc/fstab
fi

if [[ "$swap_swappiness" =~ ^[0-9]+$ ]]; then
  if grep -q "^vm.swappiness=" /etc/sysctl.conf; then
    sed -i "s/^vm\\.swappiness=.*/vm.swappiness=$swap_swappiness/" /etc/sysctl.conf
  else
    printf "%s\n" "vm.swappiness=$swap_swappiness" >> /etc/sysctl.conf
  fi
  sysctl -p >/dev/null 2>&1
fi

info "Swap configured."
mark_done "swap"
