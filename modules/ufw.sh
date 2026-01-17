# path: modules/ufw.sh
#--- UFW Firewall Setup ---#

info "Configuring UFW firewall..."

# Check if security is enabled
if [[ "$ENABLE_SECURITY" != "yes" ]]; then
  info "Security is disabled. Skipping UFW setup."
  mark_done "ufw"
  return
fi

# Install UFW if not present
if ! command -v ufw >/dev/null 2>&1; then
  info "UFW not found. Installing..."
  apt-get update
  apt-get install -y ufw
fi

# Validate SSH_PORT
ssh_port="${SSH_PORT:-22}"
if [[ ! "$ssh_port" =~ ^[0-9]+$ || "$ssh_port" -lt 1 || "$ssh_port" -gt 65535 ]]; then
  error "Invalid SSH_PORT: $ssh_port"
  exit 1
fi

# Reset rules to ensure only SSH (and optional ports) are open.
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow "$ssh_port"/tcp

# Open additional ports if specified  
if [[ -n "$OPEN_PORTS" ]]; then
  for port in $OPEN_PORTS; do
    ufw allow "$port"
  done
fi

# Enable UFW
ufw --force enable

mark_done "ufw"
