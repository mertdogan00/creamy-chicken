# path: modules/fail2ban.sh
#--- Fail2Ban Setup ---#

info "Configuring Fail2Ban..."

# Check if security is enabled
if [[ "$ENABLE_SECURITY" != "yes" ]]; then
  info "Security is disabled. Skipping Fail2Ban setup."
  mark_done "fail2ban"
  return
fi

# Install Fail2Ban if not present
if ! command -v fail2ban-client >/dev/null 2>&1; then
  info "Fail2Ban not found. Installing..."
  apt-get update
  apt-get install -y fail2ban
fi

# Configure Fail2Ban
destemail="${FAIL2BAN_DESTEMAIL:-}"
sender="${FAIL2BAN_SENDER:-}"
mta="${FAIL2BAN_MTA:-sendmail}"
action="${FAIL2BAN_ACTION:-%(action_mwl)s}"

if [[ -n "$destemail" && -n "$sender" ]]; then
  cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
EOF
  if [[ -n "$destemail" ]]; then
    printf "destemail = %s\n" "$destemail" >> /etc/fail2ban/jail.local
  fi
  if [[ -n "$sender" ]]; then
    printf "sender = %s\n" "$sender" >> /etc/fail2ban/jail.local
  fi
  if [[ -n "$mta" ]]; then
    printf "mta = %s\n" "$mta" >> /etc/fail2ban/jail.local
  fi
  if [[ -n "$action" ]]; then
    printf "action = %s\n" "$action" >> /etc/fail2ban/jail.local
  fi
fi

# Configure SSH jail
ssh_port="${SSH_PORT:-22}"
if [[ ! "$ssh_port" =~ ^[0-9]+$ || "$ssh_port" -lt 1 || "$ssh_port" -gt 65535 ]]; then
  error "Invalid SSH_PORT: $ssh_port"
  exit 1
fi

# Enable SSH jail
mkdir -p /etc/fail2ban/jail.d
cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
port = $ssh_port
maxretry = 5
findtime = 10m
bantime = 15m
EOF

# Restart and enable Fail2Ban service so settings take effect
systemctl enable --now fail2ban
systemctl restart fail2ban
info "Fail2Ban enabled."
mark_done "fail2ban"
