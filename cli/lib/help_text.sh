# path: cli/lib/help_text.sh
#--- Print help message for the CLI tool ---#

list_profiles() {
  local file name desc
  for file in "$BASE_DIR/profiles/"*.conf; do
    [[ -f "$file" ]] || continue
    name="${file##*/}"
    name="${name%.conf}"
    desc="$(sed -n 's/^#--- \(.*\) ---#/\1/p' "$file" | head -n 1)"
    [[ -z "$desc" ]] && desc="-"
    printf "  %-20s %s\n" "$name" "$desc"
  done
}

list_modules() {
  local file name desc
  for file in "$BASE_DIR/modules/"*.sh; do
    [[ -f "$file" ]] || continue
    name="${file##*/}"
    name="${name%.sh}"
    desc="$(sed -n 's/^#--- \(.*\) ---#/\1/p' "$file" | head -n 1)"
    [[ -z "$desc" ]] && desc="-"
    printf "  %-20s %s\n" "$name" "$desc"
  done
}

print_help() {
  cat <<EOF
Usage:
  ./run.sh [options]

Default behavior:
  - Resume from last successful step

Options:
  -h, --help            Show this help and exit
  -v, --version         Show version and exit
  -p, --profile <name>  Select profile (default: setup)
  --only <module>       Run only the selected module(s) from the profile
  --reset               Reset all state (does not run modules)
  --reset <module>      Reset selected modules (does not run modules)
  --force               Reset all state and run all profile modules
  --force <module>      Reset selected modules and run all profile modules

Profiles:
$(list_profiles)

Modules:
$(list_modules)
EOF
}
