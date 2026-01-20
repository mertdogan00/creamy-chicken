# path: modules/backup.sh
#--- Backup Setup ---#

set -euo pipefail

info "Running backup setup..."

# --------------------
# Helpers
# --------------------
die() { error "$1"; exit 1; }

# --------------------
# Load configuration
# --------------------
backup_enabled="${BACKUP_ENABLED:-no}"
backup_source="${BACKUP_SOURCE_DIR:-}"
backup_repo="${BACKUP_REPO:-}"
backup_password="${BACKUP_PASSWORD:-}"

backup_keep_daily="${BACKUP_KEEP_DAILY:-7}"
backup_keep_weekly="${BACKUP_KEEP_WEEKLY:-4}"
backup_keep_monthly="${BACKUP_KEEP_MONTHLY:-6}"
backup_keep_yearly="${BACKUP_KEEP_YEARLY:-1}"

backup_rclone_remote="${BACKUP_RCLONE_REMOTE:-}"
backup_rclone_path="${BACKUP_RCLONE_PATH:-}"
rclone_config_path="${RCLONE_CONFIG_PATH:-}"

backup_schedule="${BACKUP_SCHEDULE:-}"

remote_repo_re='^(rclone|s3|sftp|b2|azure|gs|swift|rest):'

# --------------------
# Enable check
# --------------------
[[ "$backup_enabled" == "yes" ]] || {
  info "Backup disabled. Skipping."
  mark_done backup
  return
}

# --------------------
# Validation
# --------------------
[[ -d "$backup_source" ]] || die "BACKUP_SOURCE_DIR missing or not a directory"
[[ -n "$backup_repo" ]]   || die "BACKUP_REPO missing"
[[ -n "$backup_password" ]] || die "BACKUP_PASSWORD missing"

# create local repo directory if needed
if [[ ! "$backup_repo" =~ $remote_repo_re ]]; then
  mkdir -p "$backup_repo"
fi

# schedule format HH:MM
if [[ -n "$backup_schedule" ]] &&
   [[ ! "$backup_schedule" =~ ^([01]?[0-9]|2[0-3]):[0-5][0-9]$ ]]; then
  die "Invalid BACKUP_SCHEDULE: $backup_schedule (use HH:MM)"
fi

# retention must be numeric
for v in backup_keep_daily backup_keep_weekly backup_keep_monthly backup_keep_yearly; do
  [[ "${!v}" =~ ^[0-9]+$ ]] || die "$v must be a number"
done

# rclone options must be paired
if [[ -n "$backup_rclone_remote" || -n "$backup_rclone_path" ]]; then
  [[ -n "$backup_rclone_remote" && -n "$backup_rclone_path" ]] \
    || die "BACKUP_RCLONE_REMOTE and BACKUP_RCLONE_PATH must be set together"
fi

# rclone config validation (NO DEFAULTS)
if [[ -n "$backup_rclone_remote" ]]; then
  [[ -n "$rclone_config_path" ]] \
    || die "RCLONE_CONFIG_PATH must be set when using rclone"

  [[ -f "$rclone_config_path" ]] \
    || die "RCLONE_CONFIG_PATH not found: $rclone_config_path"

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

BACKUP_KEEP_DAILY="$backup_keep_daily"
BACKUP_KEEP_WEEKLY="$backup_keep_weekly"
BACKUP_KEEP_MONTHLY="$backup_keep_monthly"
BACKUP_KEEP_YEARLY="$backup_keep_yearly"

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
[[ -f "$ENV" ]] || { echo "Backup env missing"; exit 1; }

set -a
source "$ENV"
set +a

export RESTIC_PASSWORD="$BACKUP_PASSWORD"

# rclone config required only if used
if [[ -n "$BACKUP_RCLONE_REMOTE" ]]; then
  [[ -n "$RCLONE_CONFIG_PATH" ]] || {
    echo "RCLONE_CONFIG_PATH missing"
    exit 1
  }
  export RCLONE_CONFIG="$RCLONE_CONFIG_PATH"
fi

remote_repo_re='^(rclone|s3|sftp|b2|azure|gs|swift|rest):'

# init repo if needed
restic -r "$BACKUP_REPO" snapshots >/dev/null 2>&1 || \
  restic -r "$BACKUP_REPO" init

# backup
restic -r "$BACKUP_REPO" backup "$BACKUP_SOURCE_DIR"

# retention
restic -r "$BACKUP_REPO" forget \
  --keep-daily "$BACKUP_KEEP_DAILY" \
  --keep-weekly "$BACKUP_KEEP_WEEKLY" \
  --keep-monthly "$BACKUP_KEEP_MONTHLY" \
  --keep-yearly "$BACKUP_KEEP_YEARLY" \
  --prune

# optional rclone sync
if [[ -n "$BACKUP_RCLONE_REMOTE" && ! "$BACKUP_REPO" =~ $remote_repo_re ]]; then
  rclone sync "$BACKUP_REPO" \
    "${BACKUP_RCLONE_REMOTE}:${BACKUP_RCLONE_PATH}"
fi
EOF

chmod 700 /usr/local/bin/creamy-chicken-backup

# --------------------
# Logs (file + logrotate)
# --------------------
install -d -m 750 /var/log/creamy-chicken
touch /var/log/creamy-chicken/backup.log
chmod 640 /var/log/creamy-chicken/backup.log

cat > /etc/logrotate.d/creamy-chicken-backup <<'EOF'
/var/log/creamy-chicken/backup.log {
  daily
  rotate 14
  missingok
  notifempty
  compress
  delaycompress
  create 0640 root root
  copytruncate
}
EOF

# --------------------
# Systemd timer
# --------------------
if [[ -n "$backup_schedule" ]]; then
  cat > /etc/systemd/system/creamy-chicken-backup.service <<EOF
[Service]
Type=oneshot
ExecStart=/usr/local/bin/creamy-chicken-backup
StandardOutput=append:/var/log/creamy-chicken/backup.log
StandardError=append:/var/log/creamy-chicken/backup.log
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
