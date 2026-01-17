# Module Check Guide

This file explains how to verify each module from the terminal. Copy/paste the
commands and compare the output with the expected results. Short explanations
are included so people who are not familiar with the commands can still follow.

Notes:
- Run as root (or with sudo).
- Some modules may be skipped by configuration. In that case, missing output is
  normal.

## 1. system_update
Why: Shows whether a recent dist-upgrade actually ran.
```bash
grep -n "dist-upgrade" /var/log/apt/history.log | tail -n 1
```
Expected: if `AUTO_UPDATE=yes`, a recent line appears.

## 2. useful_packages
Why: Confirms packages were installed and rsyslog service is running.
```bash
for pkg in curl tree ranger tmux fzf bat ripgrep ncdu btop rsyslog logrotate lsof; do
  dpkg -s "$pkg" | grep -m1 '^Status:'
done
systemctl is-active rsyslog
```
Expected: each shows `install ok installed`, rsyslog is `active`.

## 3. user
Why: Checks the user exists and has sudo access.
```bash
id "$USER_NAME"
groups "$USER_NAME" | tr ' ' '\n' | grep -x sudo
```
Expected: user exists and is in `sudo` group.

## 4. hostname
Why: Confirms hostname and /etc/hosts entries were updated.
```bash
hostname
sed -n '1,5p' /etc/hosts
```
Expected: hostname matches config; `/etc/hosts` includes `127.0.1.1 $HOSTNAME`.

## 5. ssh
Why: Confirms SSH port and root login policy are applied.
```bash
sshd -T | grep -E '^port '
grep -E '^Port ' /etc/ssh/sshd_config
grep -E '^PermitRootLogin ' /etc/ssh/sshd_config
systemctl is-active ssh
```
Expected: port matches `$SSH_PORT`; if `DISABLE_ROOT_SSH=yes` then `PermitRootLogin no`;
service is `active`.

## 6. google_authenticator (SSH 2FA)
Why: Checks package, user secret file, and SSH/PAM config.
```bash
dpkg -s libpam-google-authenticator | grep -m1 '^Status:'
user_home="$(getent passwd "$USER_NAME" | cut -d: -f6)"
test -f "$user_home/.google_authenticator"
grep -n 'pam_google_authenticator.so' /etc/pam.d/sshd
grep -E '^ChallengeResponseAuthentication|^KbdInteractiveAuthentication' /etc/ssh/sshd_config
```
Expected: package installed, user secret file exists, PAM and sshd_config entries present.

## 7. ufw
Why: Ensures firewall rules are active and ports are open as configured.
```bash
ufw status verbose
```
Expected: `Status: active`, SSH port allowed, plus `OPEN_PORTS`.

## 8. fail2ban
Why: Verifies Fail2Ban service and sshd jail are running.
```bash
systemctl is-active fail2ban
fail2ban-client status
fail2ban-client status sshd
cat /etc/fail2ban/jail.d/sshd.local
```
Expected: service `active`, `sshd` jail present, and port settings match.

## 9. auditd
Why: Checks auditd is active and baseline rules are loaded.
```bash
systemctl is-active auditd
auditctl -l | grep -E 'identity|sshd|network|time-change|kernel-modules' | head -n 5
```
Expected: service `active`, rules visible.

## 10. tmp_lockdown
Why: Confirms /tmp is mounted with safe options.
```bash
findmnt /tmp -o TARGET,OPTIONS
grep -E '^[^#].* /tmp ' /etc/fstab
```
Expected: `/tmp` options include `nodev,nosuid,noexec`.

## 11. swap
Why: Ensures swapfile exists, is active, and swappiness is set.
```bash
swapon --show
grep -E '^/swapfile ' /etc/fstab
sysctl vm.swappiness
```
Expected: `/swapfile` listed, fstab entry present, swappiness matches config.

## 12. mail_sender (msmtp)
Why: Confirms msmtp config and log rotation exist.
```bash
test -f /etc/msmtprc && sed -n '1,20p' /etc/msmtprc
test -f /etc/logrotate.d/msmtp
```
Expected: msmtp config present with SMTP values; logrotate file exists.

Mail test (optional):
Why: Sends a real email to verify SMTP works end-to-end.
```bash
to_addr="you@example.com"
printf "To: %s\nSubject: msmtp test\n\nThis is a test email.\n" "$to_addr" | msmtp -a default "$to_addr"
tail -n 5 /var/log/msmtp.log
```
Expected: No error from msmtp; log shows a successful send. Replace `to_addr`.

## 13. docker
Why: Confirms Docker is installed, running, and logging is configured.
```bash
docker --version
systemctl is-active docker
cat /etc/docker/daemon.json
```
Expected: version prints, service `active`, log limits set in daemon.json.

## 14. dockge
Why: Confirms Dockge container is running and directories exist.
```bash
test -d "$DOCKGE_VOLUMES_DIR"
docker compose -f /opt/dockge/docker-compose.yml ps
docker ps --format '{{.Names}}' | grep -x dockge
```
Expected: volumes dir exists, compose shows `dockge` running, container listed.

## 15. backup
Why: Verifies restic can access the repository.
```bash
restic -r "$BACKUP_REPO" snapshots
```
Expected: snapshot list appears if `BACKUP_ENABLED=yes`.

## 16. restore
Why: Confirms restore target directory has files.
```bash
ls -la "$RESTORE_TARGET_DIR"
```
Expected: target directory populated if `RESTORE_ENABLED=yes`.
