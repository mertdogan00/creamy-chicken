# path: modules/ssh.sh
#--- SSH Configuration ---#

info "Configuring SSH..."

if [[ -z "$SSH_PORT" ]]; then
  info "SSH_PORT is empty. Skipping SSH configuration."
  mark_done "ssh"
  return
fi

if [[ ! "$SSH_PORT" =~ ^[0-9]+$ || "$SSH_PORT" -lt 1 || "$SSH_PORT" -gt 65535 ]]; then
  error "Invalid SSH_PORT: $SSH_PORT"
  exit 1
fi

sshd_config="/etc/ssh/sshd_config"
if [[ ! -f "$sshd_config" ]]; then
  error "Missing $sshd_config. Cannot configure SSH."
  exit 1
fi

if grep -qE '^#?Port\s+' "$sshd_config"; then
  sed -i "s/^#\\?Port\\s\\+.*/Port $SSH_PORT/" "$sshd_config"
else
  printf "\nPort %s\n" "$SSH_PORT" >> "$sshd_config"
fi

if [[ "$DISABLE_ROOT_SSH" == "yes" ]]; then
  if grep -qE '^#?PermitRootLogin\s+' "$sshd_config"; then
    sed -i "s/^#\\?PermitRootLogin\\s\\+.*/PermitRootLogin no/" "$sshd_config"
  else
    printf "\nPermitRootLogin no\n" >> "$sshd_config"
  fi
fi

systemctl restart ssh
info "SSH port set to $SSH_PORT."
mark_done "ssh"
