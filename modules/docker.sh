# path: modules/docker.sh
#--- Docker Setup ---#

info "Configuring Docker..."

if [[ "$INSTALL_DOCKER" != "yes" ]]; then
  info "INSTALL_DOCKER is not yes. Skipping Docker setup."
  mark_done "docker"
  return
fi

if command -v docker >/dev/null 2>&1; then
  info "Docker already installed."
  mark_done "docker"
  return
fi

if ! command -v curl >/dev/null 2>&1; then
  info "curl not found. Installing..."
  apt-get update
  apt-get install -y curl
fi

info "Running official Docker install script..."
curl -fsSL https://get.docker.com | sh

systemctl enable --now docker
info "Docker installed and enabled."

mark_done "docker"
