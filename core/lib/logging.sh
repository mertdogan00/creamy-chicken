# path: core/lib/logging.sh
#--- Core logging functions ---#

BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

LOG_DIR="$BASE_DIR/logs"
LOG_FILE="$LOG_DIR/run.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

timestamp() {
 date -u "+%Y-%m-%dT%H:%M:%SZ"
}

log_to_file() {
  echo "$(timestamp) [$1] $2" >> "$LOG_FILE"
}

info() {
  printf "%b[INFO] %s%b\n" "$BLUE" "$1" "$RESET"
  log_to_file "INFO" "$1"
}

ok() {
  printf "%b[OK] %s%b\n" "$GREEN" "$1" "$RESET"
  log_to_file "OK" "$1"
}

error() {
  printf "%b[ERROR] %s%b\n" "$RED" "$1" "$RESET"
  log_to_file "ERROR" "$1"
}
