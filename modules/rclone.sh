# path: modules/rclone.sh
#--- Rclone Setup ---#

info "Configuring rclone..."

if ! command -v rclone >/dev/null 2>&1; then
  info "rclone not found. Installing..."
  apt-get update
  apt-get install -y rclone
fi

if [[ ! -f /root/.config/rclone/rclone.conf ]]; then
  info "rclone config not found. Run: rclone config"
fi

mark_done "rclone"
