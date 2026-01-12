# path: core/lib/state_store.sh
#--- Core state management ---#

STATE_DIR="$BASE_DIR/.state"

# State dizini yoksa oluştur
mkdir -p "$STATE_DIR"

is_done() {
  local name="$1"
  [[ -f "$STATE_DIR/$name.done" ]]
}

mark_done() {
  local name="$1"
  touch "$STATE_DIR/$name.done"
}

reset_all_state() {
  rm -f "$STATE_DIR"/*.done
}

reset_module_state() {
  local name="$1"
  rm -f "$STATE_DIR/$name.done"
}
