# path: core/lib/module_runner.sh
#--- Core module loader ---#

# Load logging functions
format_module_name() {
  local name="$1"
  name="${name//_/ }"
  printf "%s" "$name"
}

# Validate --only modules
validate_only_modules() {

  local found

  if [[ ${#ONLY_MODULES[@]} -eq 0 ]]; then
    return 0
  fi

  for only in "${ONLY_MODULES[@]}"; do
    found=0

    for module in "${MODULES[@]}"; do
      if [[ "$module" == "$only" ]]; then
        found=1
        break
      fi
    done

    if [[ $found -eq 0 ]]; then
      error "Unknown module in --only: $only"
      exit 1
    fi

  done
}

# Main module runner
run_modules() {

  validate_only_modules

  for module in "${MODULES[@]}"; do

    if [[ -n "$SKIP_ALL" ]]; then
      info "Skipping module due to reset: $module"
      continue
    fi

    if [[ ${#ONLY_MODULES[@]} -gt 0 ]]; then
      local selected=0
      for only in "${ONLY_MODULES[@]}"; do
        if [[ "$module" == "$only" ]]; then
          selected=1
          break
        fi
      done
      if [[ $selected -eq 0 ]]; then
        info "Skipping module (not selected): $module"
        continue
      fi
    fi

    if is_done "$module"; then
      ok "✓ Already done: $(format_module_name "$module")"
      continue
    fi
    info "Working on: $(format_module_name "$module")"
    source "$BASE_DIR/modules/$module.sh"
    ok "✓ Done: $(format_module_name "$module")"
  done

}
