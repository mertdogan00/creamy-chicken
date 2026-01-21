# path: modules/dockge.sh
#--------------------------------------
# Dockge Setup
#--------------------------------------

info "Configuring Dockge..."

# -------------------------------------
# Preconditions
# -------------------------------------
if [[ "${INSTALL_DOCKER:-no}" != "yes" ]]; then
  info "INSTALL_DOCKER is not enabled. Skipping Dockge."
  mark_done dockge
  return
fi

if ! command -v docker >/dev/null 2>&1; then
  info "Docker not found. Skipping Dockge."
  mark_done dockge
  return
fi

# -------------------------------------
# Configuration
# -------------------------------------
DOCKGE_PORT="${DOCKGE_PORT:-5001}"

DOCKGE_STACKS_DIR="${DOCKGE_STACKS_DIR:-/opt/stacks}"
DOCKGE_DATA_DIR="${DOCKGE_DATA_DIR:-/opt/dockge}"
DOCKGE_VOLUMES_DIR="${DOCKGE_VOLUMES_DIR:-/opt/volumes}"

DOCKGE_ENABLE_CONSOLE="${DOCKGE_ENABLE_CONSOLE:-}"

COMPOSE_FILE="${DOCKGE_DATA_DIR}/docker-compose.yml"

# -------------------------------------
# Prepare directories
# -------------------------------------
mkdir -p \
  "$DOCKGE_STACKS_DIR" \
  "$DOCKGE_DATA_DIR" \
  "$DOCKGE_VOLUMES_DIR"

# -------------------------------------
# Generate docker-compose.yml
# -------------------------------------
cat > "$COMPOSE_FILE" <<EOF
services:
  dockge:
    image: louislam/dockge:latest
    container_name: dockge
    restart: unless-stopped
    ports:
      - "${DOCKGE_PORT}:5001"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${DOCKGE_DATA_DIR}:/app/data
      - ${DOCKGE_STACKS_DIR}:${DOCKGE_STACKS_DIR}
    environment:
      - DOCKGE_STACKS_DIR=${DOCKGE_STACKS_DIR}
EOF

if [[ -n "$DOCKGE_ENABLE_CONSOLE" ]]; then
  cat >> "$COMPOSE_FILE" <<EOF
      - DOCKGE_ENABLE_CONSOLE=${DOCKGE_ENABLE_CONSOLE}
EOF
fi

# -------------------------------------
# Start Dockge
# -------------------------------------
info "Starting Dockge..."
docker compose -f "$COMPOSE_FILE" up -d

mark_done dockge
