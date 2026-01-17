# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

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
