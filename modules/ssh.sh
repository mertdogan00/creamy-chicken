# path: modules/ssh.sh
#--- SSH Configuration ---#

info "Configuring SSH..."

# Check if SSH_PORT is set
if [[ -z "$SSH_PORT" ]]; then
  info "SSH_PORT is empty. Skipping SSH configuration."
  mark_done "ssh"
  return
fi

# Validate SSH_PORT
if [[ ! "$SSH_PORT" =~ ^[0-9]+$ || "$SSH_PORT" -lt 1 || "$SSH_PORT" -gt 65535 ]]; then
  error "Invalid SSH_PORT: $SSH_PORT"
  exit 1
fi

# Configure SSHD
sshd_config="/etc/ssh/sshd_config"
if [[ ! -f "$sshd_config" ]]; then
  error "Missing $sshd_config. Cannot configure SSH."
  exit 1
fi

# Set SSH port
if grep -qE '^#?Port[[:space:]]+' "$sshd_config"; then
 sed -Ei "s/^#?Port[[:space:]]+.*/Port $SSH_PORT/" "$sshd_config"
else
  printf "\nPort %s\n" "$SSH_PORT" >> "$sshd_config"
fi

# Disable root login if specified
if [[ "$DISABLE_ROOT_SSH" == "yes" ]]; then
  if grep -qE '^#?PermitRootLogin[[:space:]]+' "$sshd_config"; then
    sed -Ei "s/^#?PermitRootLogin[[:space:]]+.*/PermitRootLogin no/" "$sshd_config"
  else
    printf "\nPermitRootLogin no\n" >> "$sshd_config"
  fi
fi

# Restart SSH service to apply changes
systemctl restart ssh
info "SSH port set to $SSH_PORT."
mark_done "ssh"
