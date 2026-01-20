# path: modules/restore.sh
#--- Restore from restic (optionally via rclone backend) ---#

set -euo pipefail

info "Running restore setup..."

# --------------------
# Helpers
# --------------------
die() { error "$1"; exit 1; }

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
[[ "$restore_enabled" == "yes" ]] || {
  info "Restore disabled. Skipping."
  mark_done restore
  return
}

# =========================================================
# Validation
# =========================================================
[[ -n "$restore_target" ]]   || die "RESTORE_TARGET_DIR missing"
[[ -n "$restore_repo" ]]     || die "RESTORE_REPO missing"
[[ -n "$restore_password" ]] || die "RESTORE_PASSWORD missing"

# rclone config only required for remote repos
if [[ "$restore_repo" =~ $remote_repo_re ]]; then
  [[ -n "$rclone_config_path" ]] \
    || die "RESTORE_RCLONE_CONFIG_PATH must be set for remote repo"

  [[ -f "$rclone_config_path" ]] \
    || die "RESTORE_RCLONE_CONFIG_PATH not found: $rclone_config_path"

  chmod 600 "$rclone_config_path"
fi

# =========================================================
# Dependencies
# =========================================================
apt-get update -qq
command -v restic >/dev/null || apt-get install -y restic

if [[ "$restore_repo" =~ $remote_repo_re ]]; then
  command -v rclone >/dev/null || apt-get install -y rclone
fi

# =========================================================
# Prepare environment
# =========================================================
export RESTIC_PASSWORD="$restore_password"

if [[ "$restore_repo" =~ $remote_repo_re ]]; then
  export RCLONE_CONFIG="$rclone_config_path"
fi

# =========================================================
# Prepare target directory
# =========================================================
mkdir -p "$restore_target"

# DANGEROUS but intentional: clean target directory
info "Cleaning restore target: $restore_target"
restore_target_clean="${restore_target%/}"
[[ -n "$restore_target_clean" && "$restore_target_clean" != "/" ]] || \
  die "Refusing to wipe root directory: RESTORE_TARGET_DIR=$restore_target"
rm -rf "${restore_target:?}/"*

# =========================================================
# Restore
# =========================================================
info "Restoring snapshot '$restore_snapshot'"
info "Repo: $restore_repo"
info "Target: $restore_target"

restic -r "$restore_repo" restore "$restore_snapshot" \
  --target "$restore_target"

# ---------------------------------------------------------
# Flatten nested restore (avoid opt/opt, var/var, etc.)
# ---------------------------------------------------------
nested_dir="${restore_target%/}/${restore_target_clean#/}"

if [[ -d "$nested_dir" ]]; then
  info "Nested directory detected: $nested_dir"
  info "Flattening restore structure..."

  shopt -s dotglob nullglob
  mv "$nested_dir"/* "$restore_target"/
  shopt -u dotglob nullglob
  rm -rf "$nested_dir"
fi

info "Restore completed successfully: $restore_target"

mark_done restore
