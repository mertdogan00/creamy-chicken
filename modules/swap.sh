# path: modules/swap.sh
# Swap setup: create and enable /swapfile, ensure fstab and swappiness are set.

info "Configuring swap..."

# Load configuration with defaults
swap_enabled="${SWAP_ENABLED:-yes}"
swap_multiplier="${SWAP_MULTIPLIER:-1}"

if [[ ! "$swap_multiplier" =~ ^[0-9]+$ ]]; then
  info "SWAP_MULTIPLIER is not numeric. Defaulting to 1."
  swap_multiplier=1
fi

swap_swappiness="${SWAP_SWAPPINESS:-30}"
swapfile="/swapfile"

# Check if swap is enabled
if [[ "$swap_enabled" != "yes" ]]; then
  info "SWAP_ENABLED is not yes. Skipping swap setup."
  mark_done "swap"
  return
fi

# Determine total memory in KB
mem_kb="$(awk '/MemTotal/ {print $2}' /proc/meminfo)"
if [[ -z "$mem_kb" || !    "$mem_kb" =~ ^[0-9]+$ ]]; then
  error "Unable to determine system memory."
  exit 1
fi

# Calculate swap size in MB
swap_mb="$(( (mem_kb / 1024) * swap_multiplier ))"
if [[ "$swap_mb" -le 0 ]]; then
  error "Invalid swap size calculated: ${swap_mb}MB"
  exit 1
fi

# Check if swap is already active
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

# Ensure swapfile is in /etc/fstab
if ! awk '($1=="/swapfile"){found=1} END{exit !found}' /etc/fstab; then
  printf "%s\n" "/swapfile none swap sw 0 0" >> /etc/fstab
fi

# Set swappiness
if [[ "$swap_swappiness" =~ ^[0-9]+$ ]]; then
  sysctl_file="/etc/sysctl.d/99-swappiness.conf"
  info "Setting vm.swappiness=$swap_swappiness"
  printf "vm.swappiness=%s\n" "$swap_swappiness" > "$sysctl_file"
  sysctl -w vm.swappiness="$swap_swappiness" >/dev/null
fi

info "Swap configured."
mark_done "swap"
