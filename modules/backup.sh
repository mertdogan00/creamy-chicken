# path: modules/backup.sh
#--- Backup Setup ---#

info "Running backup..."

backup_enabled="${BACKUP_ENABLED:-no}"
backup_source="${BACKUP_SOURCE_DIR:-/opt}"
backup_repo="${BACKUP_REPO:-}"
backup_password="${BACKUP_PASSWORD:-}"
backup_keep="${BACKUP_KEEP:-7}"
backup_rclone_remote="${BACKUP_RCLONE_REMOTE:-}"
backup_rclone_path="${BACKUP_RCLONE_PATH:-}"

# Check if backup is enabled
if [[ "$backup_enabled" != "yes" ]]; then
  info "BACKUP_ENABLED is not yes. Skipping backup."
  mark_done "backup"
  return
fi

# Validate backup configuration
if [[ -z "$backup_repo" || -z "$backup_password" ]]; then
  error "BACKUP_REPO or BACKUP_PASSWORD missing."
  exit 1
fi

# Check if backup source directory exists
if [[ ! -d "$backup_source" ]]; then
  error "Backup source not found: $backup_source"
  exit 1
fi

# Install restic 
if ! command -v restic >/dev/null 2>&1; then
  info "restic not found. Installing..."
  apt-get update
  apt-get install -y restic
fi

# Install rclone if Google Drive upload is configured
if ! command -v rclone >/dev/null 2>&1; then
  info "rclone not found. Installing..."
  apt-get update
  apt-get install -y rclone
fi

# Perform backup
export RESTIC_PASSWORD="$backup_password"

# Initialize restic repository if it doesn't exist
if ! restic -r "$backup_repo" snapshots >/dev/null 2>&1; then
  info "Initializing restic repository..."
  restic -r "$backup_repo" init
fi

# Create backup
restic -r "$backup_repo" backup "$backup_source"

# Prune old backups
if [[ "$backup_keep" =~ ^[0-9]+$ && "$backup_keep" -gt 0 ]]; then
  restic -r "$backup_repo" forget --keep-last "$backup_keep" --prune
fi

# Push to Google Drive if configured
if [[ -n "$backup_rclone_remote" ]]; then
  if [[ "$backup_repo" == *:* ]]; then
    info "BACKUP_REPO is remote. Skipping rclone push."
  else
    info "Pushing backup repo to Google Drive..."
    rclone sync "$backup_repo" "${backup_rclone_remote}:${backup_rclone_path}"
  fi
fi

info "Backup completed."
mark_done "backup"
