# path: cli/lib/cli_actions.sh
#--- CLI actions ---#

handle_cli_actions() {
  
  # Handle reset and force actions
  if [[ -n "$RESET_ALL" ]]; then
    info "Resetting all state"
    reset_all_state
    SKIP_ALL=1

  elif [[ ${#RESET_MODULES[@]} -gt 0 ]]; then
    for module in "${RESET_MODULES[@]}"; do
      info "Resetting state for module: $module"
      reset_module_state "$module"
    done
    SKIP_ALL=1
  fi
 
  # Handle force actions
  if [[ -n "$FORCE_ALL" ]]; then
    info "Forcing all modules"
    reset_all_state

  elif [[ ${#FORCE_MODULES[@]} -gt 0 ]]; then
    for module in "${FORCE_MODULES[@]}"; do
      info "Forcing module rerun: $module"
      reset_module_state "$module"
    done
  fi
}
