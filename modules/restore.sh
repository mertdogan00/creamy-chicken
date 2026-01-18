# path: modules/restore.sh
#--- Restore from restic (optionally via rclone backend) ---#

set -euo pipefail

info "Running restore setup..."

# =========================================================
# Load configuration
# =========================================================
restore_enabled="${RESTORE_ENABLED:-no}"
restore_target="${RESTORE_TARGET_DIR:-}"
restore_snapshot="${RESTORE_SNAPSHOT:-latest}"
restore_repo="${RESTORE_REPO:-}"
restore_password="${RESTORE_PASSWORD:-}"
rclone_config_path="${RESTORE_RCLONE_CONFIG_PATH:-}"
remote_repo_re='^(rclone|s3|sftp|b2|azure|gs|swift|rest):'

# =========================================================
# Enable check
# =========================================================
if [[ "$restore_enabled" != "yes" ]]; then
  info "Restore disabled. Skipping."
  mark_done restore
  return
fi

# =========================================================
# Validation
# =========================================================
[[ -n "$restore_target" ]] || {
  error "RESTORE_TARGET_DIR missing."
  exit 1
}
[[ -n "$restore_repo" ]] || {
  error "RESTORE_REPO missing (required for restore). Use rclone:REMOTE:PATH for Drive."
  exit 1
}
[[ -n "$restore_password" ]] || {
  error "RESTORE_PASSWORD missing (required for restore)."
  exit 1
}
if [[ "$restore_repo" =~ $remote_repo_re ]]; then
  [[ -n "$rclone_config_path" && -f "$rclone_config_path" ]] || {
    error "RESTORE_RCLONE_CONFIG_PATH missing or file not found."
    exit 1
  }
  chmod 600 "$rclone_config_path"
fi

# =========================================================
# Dependencies
# =========================================================
apt-get update -qq
command -v restic >/dev/null || apt-get install -y restic

# rclone is only needed for remote repos
if [[ "$restore_repo" =~ $remote_repo_re ]]; then
  command -v rclone >/dev/null || apt-get install -y rclone
fi

# =========================================================
# Prepare environment
# =========================================================
export RESTIC_PASSWORD="$restore_password"
if [[ -n "$rclone_config_path" ]]; then
  export RCLONE_CONFIG="$rclone_config_path"
fi

# =========================================================
# Ensure target directory
# =========================================================
mkdir -p "$restore_target"

# DANGEROUS but intentional: clean the target directory
info "Cleaning restore target: $restore_target"
rm -rf "${restore_target:?}/"*

# =========================================================
# Restore
# =========================================================
info "Restoring from repo: $restore_repo (use rclone:REMOTE:PATH for Drive)"
info "Restoring snapshot '$restore_snapshot' to $restore_target"

restic -r "$restore_repo" restore "$restore_snapshot" \
  --target "$restore_target"

info "Restore completed successfully: $restore_target"

mark_done restore
