# path: modules/hostname.sh
#--- Hostname Setup ---#

info "Configuring hostname..."

if [[ -z "$HOSTNAME" ]]; then
  info "HOSTNAME is empty. Skipping hostname setup."
  mark_done "hostname"
  return
fi

current_hostname="$(hostname)"
if [[ "$current_hostname" == "$HOSTNAME" ]]; then
  info "Hostname already set to $HOSTNAME. Skipping."
  mark_done "hostname"
  return
fi

hostnamectl set-hostname "$HOSTNAME"
info "Hostname set to $HOSTNAME."

short_hostname="${HOSTNAME%%.*}"
hosts_file="/etc/hosts"

cat > "$hosts_file" <<EOF
127.0.0.1   localhost
127.0.1.1   $HOSTNAME $short_hostname

::1         localhost ip6-localhost ip6-loopback
::1         $HOSTNAME $short_hostname
EOF

mark_done "hostname"
