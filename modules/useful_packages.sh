# path: modules/useful_packages.sh
# --- Useful Packages (Minimal & Docker-friendly) --- #

info "Installing useful packages..."

# -------------------------------
# Package groups (CLI tools only)
# -------------------------------

packages=(
  # --- Network & Data Fetching ---
  curl        # Download files, call APIs, fetch remote scripts (e.g. Docker install)

  # --- Terminal Productivity & Navigation ---
  tree        # Display directory structure in a tree format
  ranger      # Terminal-based file manager for fast navigation over SSH
  tmux        # Persistent terminal sessions and multiple panes/windows
  fzf         # Fuzzy finder for fast searching (files, history, commands)
  bat         # Modern replacement for cat with syntax highlighting
  ripgrep     # Fast text search tool (modern grep)
  ncdu        # Interactive disk usage analyzer (find what eats disk space)

  # --- System Monitoring ---
  btop        # Modern system monitor (CPU, memory, disk, network)

  # --- Host Logging & Diagnostics ---
  rsyslog     # Write system logs to files under /var/log
  logrotate   # Rotate and manage log files to prevent disk overflow
  lsof        # Show which process is using a file or network port
)


# -------------------------------
# Detect missing packages
# -------------------------------

missing=()

for pkg in "${packages[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

# -------------------------------
# Install missing packages
# -------------------------------

if [[ ${#missing[@]} -gt 0 ]]; then
  info "Installing missing packages: ${missing[*]}"
  apt-get update
  apt-get install -y "${missing[@]}"
else
  info "All useful packages are already installed."
fi

# -------------------------------
# Enable ONLY real services
# -------------------------------

services=(
  rsyslog
)

for svc in "${services[@]}"; do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    systemctl enable --now "$svc" >/dev/null 2>&1 || true
    info "Service enabled: $svc"
  fi
done

mark_done "useful_packages"
