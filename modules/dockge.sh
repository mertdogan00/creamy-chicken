# path: modules/dockge.sh
#--- Dockge Setup ---#

info "Configuring Dockge..."

# Check if Dockge installation is requested
if [[ "$INSTALL_DOCKER" != "yes" ]]; then
  info "INSTALL_DOCKER is not yes. Skipping Dockge setup."
  mark_done "dockge"
  return
fi

# Ensure Docker is installed
if ! command -v docker >/dev/null 2>&1; then
  info "Docker not found. Skipping Dockge setup."
  mark_done "dockge"
  return
fi

dockge_port="${DOCKGE_PORT:-5001}"

dockge_stacks_dir="${DOCKGE_STACKS_DIR:-/opt/stacks}"
dockge_data_dir="${DOCKGE_DATA_DIR:-/opt/dockge}"
dockge_volumes_dir="${DOCKGE_VOLUMES_DIR:-/opt/volumes}"

mkdir -p "$dockge_stacks_dir" "$dockge_data_dir" "$dockge_volumes_dir"

cat > "$dockge_data_dir/docker-compose.yml" <<EOF
services:
  dockge:
    image: louislam/dockge:latest
    container_name: dockge
    restart: unless-stopped
    ports:
      - "${dockge_port}:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${dockge_data_dir}:/app/data
      - ${dockge_stacks_dir}:${dockge_stacks_dir}
    environment:
      - DOCKGE_STACKS_DIR=${dockge_stacks_dir}
EOF

info "Starting Dockge..."
docker compose -f "$dockge_data_dir/docker-compose.yml" up -d

mark_done "dockge"
