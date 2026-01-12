# path: modules/user.sh
#--- User Setup ---#

info "Configuring user..."

if [[ -z "$USER_NAME" ]]; then
  info "USER_NAME is empty. Skipping user setup."
  mark_done "user"
  return
fi

if id -u "$USER_NAME" >/dev/null 2>&1; then
  info "User $USER_NAME already exists."
else
  useradd -m -s /bin/bash "$USER_NAME"
  info "User $USER_NAME created."
fi

if ! command -v sudo >/dev/null 2>&1; then
  info "sudo not found. Installing..."
  apt-get update
  apt-get install -y sudo
fi

if ! getent group sudo >/dev/null 2>&1; then
  info "sudo group not found. Creating..."
  groupadd sudo
fi

usermod -aG sudo "$USER_NAME"
info "User $USER_NAME added to sudo group."

if [[ -n "$USER_PASSWORD" ]]; then
  echo "$USER_NAME:$USER_PASSWORD" | chpasswd
  info "Password set for $USER_NAME."
else
  info "USER_PASSWORD is empty. Skipping password setup."
fi

mark_done "user"
