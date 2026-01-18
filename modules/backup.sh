# path: modules/backup.sh
#--- Backup Setup ---#

info "Running backup setup..."

# --------------------
# Load configuration
# --------------------
backup_enabled="${BACKUP_ENABLED:-no}"
backup_source="${BACKUP_SOURCE_DIR:-}"
backup_repo="${BACKUP_REPO:-}"
backup_password="${BACKUP_PASSWORD:-}"
backup_keep="${BACKUP_KEEP:-7}"
backup_rclone_remote="${BACKUP_RCLONE_REMOTE:-}"
backup_rclone_path="${BACKUP_RCLONE_PATH:-}"
rclone_config_path="${RCLONE_CONFIG_PATH:-}"
backup_schedule="${BACKUP_SCHEDULE:-}"
remote_repo_re='^(rclone|s3|sftp|b2|azure|gs|swift|rest):'

# --------------------
# Enable check
# --------------------
if [[ "$backup_enabled" != "yes" ]]; then
  info "Backup disabled. Skipping."
  mark_done backup
  return
fi

# --------------------
# Validation
# --------------------
[[ -n "$backup_source" && -d "$backup_source" ]] || {
  error "BACKUP_SOURCE_DIR missing or not a directory."
  exit 1
}

[[ -n "$backup_repo" && -n "$backup_password" ]] || {
  error "BACKUP_REPO or BACKUP_PASSWORD missing."
  exit 1
}

if [[ -n "$backup_schedule" ]] && \
   [[ ! "$backup_schedule" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
  error "Invalid BACKUP_SCHEDULE: $backup_schedule (use HH:MM)"
  exit 1
fi

if [[ -n "$backup_rclone_remote" || -n "$backup_rclone_path" ]]; then
  [[ -n "$backup_rclone_remote" && -n "$backup_rclone_path" ]] || {
    error "Both BACKUP_RCLONE_REMOTE and BACKUP_RCLONE_PATH must be set together."
    exit 1
  }
fi
if [[ -n "$backup_rclone_remote" ]]; then
  [[ -n "$rclone_config_path" && -f "$rclone_config_path" ]] || {
    error "RCLONE_CONFIG_PATH missing or file not found."
    exit 1
  }
  chmod 600 "$rclone_config_path"
fi

# --------------------
# Dependencies
# --------------------
apt-get update -qq
command -v restic >/dev/null || apt-get install -y restic

if [[ -n "$backup_rclone_remote" ]]; then
  command -v rclone >/dev/null || apt-get install -y rclone
fi

# --------------------
# Write env for runner
# --------------------
install -d -m 700 /etc/creamy-chicken
cat > /etc/creamy-chicken/backup.env <<EOF
BACKUP_SOURCE_DIR="$backup_source"
BACKUP_REPO="$backup_repo"
BACKUP_PASSWORD="$backup_password"
BACKUP_KEEP="$backup_keep"
BACKUP_RCLONE_REMOTE="$backup_rclone_remote"
BACKUP_RCLONE_PATH="$backup_rclone_path"
RCLONE_CONFIG_PATH="$rclone_config_path"
EOF
chmod 600 /etc/creamy-chicken/backup.env

# --------------------
# Runner script
# --------------------
cat > /usr/local/bin/creamy-chicken-backup <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

ENV=/etc/creamy-chicken/backup.env
[[ -f $ENV ]] || { echo "Backup env missing"; exit 1; }
remote_repo_re='^(rclone|s3|sftp|b2|azure|gs|swift|rest):'

set -a
. "$ENV"
set +a

export RESTIC_PASSWORD="$BACKUP_PASSWORD"
if [[ -n "$RCLONE_CONFIG_PATH" ]]; then
  export RCLONE_CONFIG="$RCLONE_CONFIG_PATH"
fi

restic -r "$BACKUP_REPO" snapshots >/dev/null 2>&1 || \
  restic -r "$BACKUP_REPO" init

restic -r "$BACKUP_REPO" backup "$BACKUP_SOURCE_DIR"

[[ "$BACKUP_KEEP" =~ ^[0-9]+$ ]] && \
  restic -r "$BACKUP_REPO" forget --keep-last "$BACKUP_KEEP" --prune

if [[ -n "$BACKUP_RCLONE_REMOTE" && ! "$BACKUP_REPO" =~ $remote_repo_re ]]; then
  [[ -n "$RCLONE_CONFIG_PATH" && -f "$RCLONE_CONFIG_PATH" ]] || {
    echo "RCLONE_CONFIG_PATH missing or file not found." >&2
    exit 1
  }
  rclone sync "$BACKUP_REPO" \
    "${BACKUP_RCLONE_REMOTE}:${BACKUP_RCLONE_PATH}"
fi
EOF
chmod 700 /usr/local/bin/creamy-chicken-backup

# --------------------
# Systemd timer
# --------------------
if [[ -n "$backup_schedule" ]]; then
  cat > /etc/systemd/system/creamy-chicken-backup.service <<EOF
[Service]
Type=oneshot
ExecStart=/usr/local/bin/creamy-chicken-backup
EOF

  cat > /etc/systemd/system/creamy-chicken-backup.timer <<EOF
[Timer]
OnCalendar=*-*-* ${backup_schedule}:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  systemctl enable --now creamy-chicken-backup.timer
  systemctl start creamy-chicken-backup.service
  info "Backup scheduled daily at $backup_schedule."
else
  info "No schedule set. Run backup manually:"
  info "  /usr/local/bin/creamy-chicken-backup"
fi

mark_done backup
