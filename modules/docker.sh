# path: modules/docker.sh
#--- Docker Setup ---#

info "Configuring Docker..."

if [[ "$INSTALL_DOCKER" != "yes" ]]; then
  info "INSTALL_DOCKER is not yes. Skipping Docker setup."
  mark_done "docker"
  return
fi

if ! command -v curl >/dev/null 2>&1; then
  info "curl not found. Installing..."
  apt-get update
  apt-get install -y curl
fi

if command -v docker >/dev/null 2>&1; then
  info "Docker already installed."
else
  info "Running official Docker install script..."
  curl -fsSL https://get.docker.com | sh
fi

info "Configuring Docker logging limits..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  }
}
EOF

systemctl enable --now docker
systemctl restart docker
info "Docker installed and enabled."

mark_done "docker"
