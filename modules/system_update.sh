# path: modules/system_update.sh
#--- System Update Module ---#

info "Starting system update..."

if is_done "system_update"; then
  info "System update already completed. Skipping."
  return
fi

if [[ "$AUTO_UPDATE" == "yes" ]]; then
  apt-get update \
    && apt-get -y upgrade \
    && apt-get -y dist-upgrade \
    && apt-get -y autoremove \
    && apt-get -y autoclean
  info "System update completed automatically."
else
  info "Auto update is disabled. Skipping system update."
fi

mark_done "system_update"
