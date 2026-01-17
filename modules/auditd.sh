# path: modules/auditd.sh
#--- Auditd Setup (Modern Baseline) ---#

info "Configuring auditd..."

# --- Security toggle ---
if [[ "$ENABLE_SECURITY" != "yes" ]]; then
  info "Security is disabled. Skipping auditd setup."
  mark_done "auditd"
  return
fi

# --- Install auditd if missing ---
if ! command -v auditctl >/dev/null 2>&1; then
  info "auditd not found. Installing..."
  apt-get update
  apt-get install -y auditd
fi

# --- Ensure rules directory ---
mkdir -p /etc/audit/rules.d

# --- Baseline audit rules ---
cat > /etc/audit/rules.d/10-baseline.rules <<'EOF'
############################
# Auditd Baseline Ruleset #
############################

# --- Identity files ---
-w /etc/passwd   -p wa -k identity
-w /etc/group    -p wa -k identity
-w /etc/shadow   -p wa -k identity
-w /etc/gshadow  -p wa -k identity

# --- Privilege escalation ---
-w /etc/sudoers     -p wa -k scope
-w /etc/sudoers.d/  -p wa -k scope

# --- SSH configuration ---
-w /etc/ssh/sshd_config -p wa -k sshd

# --- Network configuration ---
-w /etc/hosts       -p wa -k network
-w /etc/hostname    -p wa -k network
-w /etc/resolv.conf -p wa -k network

# --- Time changes (b64 + b32) ---
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time-change

# --- Hostname / domain changes ---
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale

# --- Kernel module loading/unloading ---
-a always,exit -F arch=b64 -S init_module -S delete_module -k kernel-modules
-a always,exit -F arch=b32 -S init_module -S delete_module -k kernel-modules

# --- Service control via systemctl ---
-a always,exit -F arch=b64 -S execve -F exe=/usr/bin/systemctl -k service-control
-a always,exit -F arch=b32 -S execve -F exe=/usr/bin/systemctl -k service-control

# --- Reboot / shutdown ---
-a always,exit -F arch=b64 -S reboot -S shutdown -k system-power
-a always,exit -F arch=b32 -S reboot -S shutdown -k system-power
EOF

# --- Logrotate for audit logs ---
cat > /etc/logrotate.d/auditd <<'EOF'
/var/log/audit/audit.log {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  create 0600 root root
  sharedscripts
  postrotate
    /bin/systemctl kill -s SIGUSR1 auditd >/dev/null 2>&1 || true
  endscript
}
EOF

# --- Enable auditd (do NOT hard restart blindly) ---
systemctl enable auditd

# --- Load rules safely ---
if command -v augenrules >/dev/null 2>&1; then
  augenrules --load
else
  auditctl -R /etc/audit/rules.d/10-baseline.rules
fi

# --- Ensure auditd is running ---
systemctl restart auditd

info "auditd configured successfully (modern baseline)."
mark_done "auditd"
