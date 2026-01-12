# path: cli/lib/args.sh
#--- Parse command-line arguments ---#

# Global variables to hold parsed arguments
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        print_help
        exit 0
        ;;
      -v|--version)
        print_version
        exit 0
        ;;
      -p|--profile)
        PROFILE="$2"
        shift 2
        ;;
      --only)
        if [[ -n "$2" && "$2" != --* ]]; then
          shift
          while [[ -n "$1" && "$1" != --* ]]; do
            ONLY_MODULES+=("$1")
            shift
          done
        else
          echo "Missing module name for --only"
          exit 1
        fi
        ;;
      --reset)
        if [[ -n "$2" && "$2" != --* ]]; then
          shift
          while [[ -n "$1" && "$1" != --* ]]; do
            RESET_MODULES+=("$1")
            shift
          done
        else
          RESET_ALL=1
          shift
        fi
        ;;
      --force)
        if [[ -n "$2" && "$2" != --* ]]; then
          shift
          while [[ -n "$1" && "$1" != --* ]]; do
            FORCE_MODULES+=("$1")
            shift
          done
        else
          FORCE_ALL=1
          shift
        fi
        ;;
      *)
        echo "Unknown option: $1"
        echo "Run './run.sh --help' for usage."
        exit 1
        ;;
    esac
  done
}
