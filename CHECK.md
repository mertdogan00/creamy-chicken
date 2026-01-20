# Module Check Guide (Backup + Restore)

This guide focuses only on backup and restore verification. Run as root (or
with sudo). Commands are safe unless noted.

## 1. Backup
Why this matters: Ensures the repo is reachable, scheduling runs, and logs are
kept for audits. Missing any of these means backups may silently fail.

Check configuration and env file:
```bash
test -f /etc/creamy-chicken/backup.env
sed -n '1,120p' /etc/creamy-chicken/backup.env
```
Expected: file exists; values match `BACKUP_*` in config.

Check repo reachability (restic):
```bash
restic -r "$BACKUP_REPO" snapshots
```
Expected: snapshot list prints; empty list is ok for a new repo.

Check backup runner works (manual run):
```bash
/usr/local/bin/creamy-chicken-backup
```
Expected: completes without error; a new snapshot appears afterward.

Check scheduler and last run status:
```bash
systemctl status creamy-chicken-backup.timer
systemctl status creamy-chicken-backup.service
systemctl list-timers | rg creamy-chicken-backup
```
Expected: timer is `active (waiting)`; service shows the last run status.

Check log file and rotation:
```bash
tail -n 50 /var/log/creamy-chicken/backup.log
cat /etc/logrotate.d/creamy-chicken-backup
```
Expected: recent run output in log; logrotate rules present.

If using rclone for offsite sync:
```bash
test -f "$RCLONE_CONFIG_PATH"
rclone lsd "${BACKUP_RCLONE_REMOTE}:"
```
Expected: rclone config exists; remote listing succeeds.

## 2. Restore
Why this matters: Verifies you can actually recover data, not just create
backups. A passing restore check is the real proof of backup health.

Check restore config:
```bash
echo "$RESTORE_REPO"
echo "$RESTORE_SNAPSHOT"
echo "$RESTORE_TARGET_DIR"
```
Expected: values are set and sane (target is not `/`).

List available snapshots:
```bash
restic -r "$RESTORE_REPO" snapshots
```
Expected: snapshot list prints; choose one to restore.

Restore to a temp directory (recommended):
```bash
tmp_restore="/tmp/restore-check"
rm -rf "$tmp_restore"
mkdir -p "$tmp_restore"
restic -r "$RESTORE_REPO" restore "$RESTORE_SNAPSHOT" --target "$tmp_restore"
ls -la "$tmp_restore"
```
Expected: files appear under the temp directory.

Optional: verify a specific file hash after restore:
```bash
sha256sum "$tmp_restore/path/to/file"
```
Expected: hash matches the source (if you still have it).

