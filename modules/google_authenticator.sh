# path: modules/google_authenticator.sh
#--- Google Authenticator (SSH 2FA) ---#

info "Configuring Google Authenticator (SSH 2FA)..."

if [[ "${ENABLE_2FA:-no}" != "yes" ]]; then
  info "ENABLE_2FA is not yes. Skipping 2FA setup."
  mark_done "google_authenticator"
  return
fi

if [[ -z "$USER_NAME" ]]; then
  error "USER_NAME is empty. Cannot configure 2FA."
  exit 1
fi

if ! id -u "$USER_NAME" >/dev/null 2>&1; then
  error "User not found: $USER_NAME"
  exit 1
fi

if ! command -v google-authenticator >/dev/null 2>&1; then
  info "google-authenticator not found. Installing..."
  apt-get update
  apt-get install -y libpam-google-authenticator
fi

user_home="$(getent passwd "$USER_NAME" | cut -d: -f6)"
ga_file="$user_home/.google_authenticator"

if [[ ! -f "$ga_file" ]]; then
  info "Generating 2FA secret for $USER_NAME..."
  sudo -u "$USER_NAME" google-authenticator -t -d -f -r 3 -R 30 -W -q
fi

pam_file="/etc/pam.d/sshd"
if ! grep -q "pam_google_authenticator.so" "$pam_file"; then
  printf "\nauth required pam_google_authenticator.so\n" >> "$pam_file"
fi

sshd_config="/etc/ssh/sshd_config"
if [[ -f "$sshd_config" ]]; then
  if grep -q "^#\\?ChallengeResponseAuthentication" "$sshd_config"; then
    sed -i "s/^#\\?ChallengeResponseAuthentication.*/ChallengeResponseAuthentication yes/" "$sshd_config"
  else
    printf "\nChallengeResponseAuthentication yes\n" >> "$sshd_config"
  fi
  if grep -q "^#\\?KbdInteractiveAuthentication" "$sshd_config"; then
    sed -i "s/^#\\?KbdInteractiveAuthentication.*/KbdInteractiveAuthentication yes/" "$sshd_config"
  else
    printf "\nKbdInteractiveAuthentication yes\n" >> "$sshd_config"
  fi
else
  error "Missing $sshd_config. Cannot configure SSH 2FA."
  exit 1
fi

systemctl restart sshd
info "SSH 2FA configured."

mark_done "google_authenticator"
