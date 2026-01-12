# path: modules/useful_packages.sh
#--- Useful Packages ---#

info "Installing useful packages..."

# List of useful packages to install
packages=(
  curl
  logrotate
  perl
  rsyslog
)

# Array to hold missing packages
missing=()

# Check for already installed packages
for pkg in "${packages[@]}"; do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing+=("$pkg")
  fi
done

# Install missing packages
if [[ ${#missing[@]} -gt 0 ]]; then
  info "Installing: ${missing[*]}"
  apt-get update
  apt-get install -y "${missing[@]}"
else
  info "All useful packages already installed."
fi

# Enable and start services if systemctl is available
  for pkg in "${packages[@]}"; do
    systemctl enable --now "$pkg" >/dev/null 2>&1 || systemctl enable --now "$pkg.service" >/dev/null 2>&1 || true
  done
fi

mark_done "useful_packages"
