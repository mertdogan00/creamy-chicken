# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [2.1.0] - 2026-01-19

### Added

- Backup log file output with logrotate rotation
- Backup retention knobs (`BACKUP_KEEP_DAILY`, `BACKUP_KEEP_WEEKLY`, `BACKUP_KEEP_MONTHLY`)
- Backup schedule defaults in global configs (`BACKUP_SCHEDULE`)
- Focused backup/restore verification guide in `CHECK.md`

### Changed

- Backup setup now creates local repo directories when needed
- Restore cleanup guard refuses to wipe `/`
- Default backup repo path in global configs is `/backups/restic`

### Removed

- `BACKUP_KEEP` legacy retention setting from configs

## [2.0.0] - 2026-01-18

### Added

- Systemd-backed daily backup scheduling with a dedicated runner script
- Backup schedule configuration (`BACKUP_SCHEDULE`)
- Restore snapshot selection (`RESTORE_SNAPSHOT`)
- Restore repo/password config (`RESTORE_REPO`, `RESTORE_PASSWORD`)
- rclone config path support for backup and restore (`RCLONE_CONFIG_PATH`, `RESTORE_RCLONE_CONFIG_PATH`)

### Changed

- Backup flow now writes a shared env file and validates config more strictly
- Restore flow uses restic directly against the configured repo
- Restore settings are now independent from backup settings
- Clarified backup/restore configuration notes in global config

### Removed

- `RESTORE_TAR_PATH` legacy restore option

## [1.1.2] - 2026-01-17

### Added

- Export noninteractive debconf setting globally during core init
- Add `DEBIAN_NONINTERACTIVE` to global configs for noninteractive installs
- Preseed msmtp AppArmor prompt to default to "No"

### Changed

- Ensure msmtp log directory exists before touching log file
- Install ca-certificates alongside msmtp
- Organize global config files by module with a global defaults section
- Split firewall, Fail2Ban, and 2FA config blocks into separate sections
- Remove rclone check and renumber modules in `CHECK.md`

## [1.1.1] - 2026-01-17

### Added

- Add DOCKGE_VOLUMES_DIR config and create the directory during Dockge setup
- Add `CHECK.md` with per-module verification commands and expected results

## [1.1.0] - 2026-01-15

### Changed

- Simplified system update to use dist-upgrade with cleanup steps
- Set Docker log limits (max-size 50m, max-file 3) via daemon.json
- Refined useful packages list and service enablement
- Install auditd without audispd-plugins

## [1.0.0] - 2026-01-12

### Added

- Added CHANGELOG file

### Changed

- Updated README with license information
