# path: modules/tmp_lockdown.sh
#--- /tmp Execution Lockdown ---#

info "Configuring /tmp mount options..."

if [[ "$ENABLE_SECURITY" != "yes" ]]; then
  info "Security is disabled. Skipping /tmp lockdown."
  mark_done "tmp_lockdown"
  return
fi

fstab="/etc/fstab"
desired_opts="defaults,noexec,nosuid,nodev"

if ! awk -v mnt="/tmp" '($2==mnt){found=1} END{exit !found}' "$fstab"; then
  printf "%s\n" "tmpfs /tmp tmpfs $desired_opts 0 0" >> "$fstab"
fi

if mountpoint -q /tmp; then
  mount -o remount,nodev,nosuid,noexec /tmp
else
  mount /tmp
  mount -o remount,nodev,nosuid,noexec /tmp
fi
info "/tmp remounted with nodev,nosuid,noexec."

mark_done "tmp_lockdown"
