# path: modules/dockge.sh
#--- Dockge Setup ---#

info "Configuring Dockge..."

if [[ "$INSTALL_DOCKER" != "yes" ]]; then
  info "INSTALL_DOCKER is not yes. Skipping Dockge setup."
  mark_done "dockge"
  return
fi

if ! command -v docker >/dev/null 2>&1; then
  info "Docker not found. Skipping Dockge setup."
  mark_done "dockge"
  return
fi

dockge_port="${DOCKGE_PORT:-5001}"
dockge_stacks_dir="${DOCKGE_STACKS_DIR:-/opt/stacks}"
dockge_data_dir="${DOCKGE_DATA_DIR:-/opt/dockge}"

mkdir -p "$dockge_stacks_dir" "$dockge_data_dir"

cat > "$dockge_data_dir/docker-compose.yml" <<EOF
version: "3.8"
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
