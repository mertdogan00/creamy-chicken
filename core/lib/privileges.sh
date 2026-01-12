# path: core/lib/privileges.sh
#--- Privilege checks ---#

# Ensure the script is run as root
require_root() {
  local uid="${EUID:-$(id -u)}"
  if [[ "$uid" -ne 0 ]]; then
    error "This script must be run as root. Use sudo."
    exit 1
  fi
}
