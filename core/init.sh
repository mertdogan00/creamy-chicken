# path: core/init.sh
#--- Core initialization ---#

source "$BASE_DIR/core/lib/logging.sh"
source "$BASE_DIR/core/lib/privileges.sh"
source "$BASE_DIR/core/lib/state_store.sh"
source "$BASE_DIR/core/lib/module_runner.sh"

if [[ "${DEBIAN_NONINTERACTIVE:-yes}" == "yes" ]]; then
  export DEBIAN_FRONTEND=noninteractive
fi

require_root
