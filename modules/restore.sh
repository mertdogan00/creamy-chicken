# path: modules/restore.sh
#--- Restore from tar ---#

info "Restoring from tar..."

# Configuration
restore_enabled="${RESTORE_ENABLED:-no}"
restore_tar="${RESTORE_TAR_PATH:-}"
restore_target="${RESTORE_TARGET_DIR:-/opt}"

# Check if restore is enabled
if [[ "$restore_enabled" != "yes" ]]; then
  info "RESTORE_ENABLED is not yes. Skipping restore."
  mark_done "restore"
  return
fi

# Validate restore tar path
if [[ -z "$restore_tar" || ! -f "$restore_tar" ]]; then
  error "Restore tar not found: $restore_tar"
  exit 1
fi

 # Ensure target directory exists
if [[ ! -d "$restore_target" ]]; then
  mkdir -p "$restore_target"
fi

rm -rf "${restore_target:?}/"*

# Extract the tar based on its extension
case "$restore_tar" in
  *.tar.gz|*.tgz)
    tar -xzf "$restore_tar" -C "$restore_target"
    ;;
  *.tar.bz2|*.tbz2)
    tar -xjf "$restore_tar" -C "$restore_target"
    ;;
  *.tar.xz|*.txz)
    tar -xJf "$restore_tar" -C "$restore_target"
    ;;
  *.tar)
    tar -xf "$restore_tar" -C "$restore_target"
    ;;
  *.zip)
    if ! command -v unzip >/dev/null 2>&1; then
      info "unzip not found. Installing..."
      apt-get update
      apt-get install -y unzip
    fi
    unzip -q "$restore_tar" -d "$restore_target"
    ;;
  *)
    error "Unsupported archive type: $restore_tar"
    exit 1
    ;;
esac


info "Restore completed: $restore_target"

mark_done "restore"
