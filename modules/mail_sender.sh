# path: modules/mail_sender.sh
#--- Mail Sender (msmtp) Setup ---#

info "Configuring mail sender (msmtp)..."

msmtp_host="${SMTP_HOST:-}"
msmtp_port="${SMTP_PORT:-}"
msmtp_from="${SMTP_FROM:-}"
msmtp_user="${SMTP_USER:-}"
msmtp_password="${SMTP_PASSWORD:-}"
msmtp_logfile="${SMTP_LOGFILE:-/var/log/msmtp.log}"

if [[ -z "$msmtp_host" || -z "$msmtp_port" || -z "$msmtp_from" || -z "$msmtp_user" || -z "$msmtp_password" ]]; then
  info "MSMTP settings missing. Skipping msmtp configuration."
  mark_done "mail_sender"
  return
fi

if ! command -v msmtp >/dev/null 2>&1; then
  info "msmtp not found. Installing..."
  apt-get update
  echo "msmtp-mta msmtp-mta/apparmor boolean false" | debconf-set-selections
  apt-get install -y msmtp msmtp-mta ca-certificates

fi

cat > /etc/msmtprc <<EOF
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt

account default
host $msmtp_host
port $msmtp_port
from $msmtp_from
user $msmtp_user
password $msmtp_password
logfile $msmtp_logfile
EOF

chmod 0600 /etc/msmtprc
msmtp_logdir="$(dirname "$msmtp_logfile")"
mkdir -p "$msmtp_logdir"
touch "$msmtp_logfile"
chmod 0600 "$msmtp_logfile"

cat > /etc/logrotate.d/msmtp <<EOF
$msmtp_logfile {
  daily
  rotate 14
  compress
  delaycompress
  missingok
  notifempty
  create 0600 root root
}
EOF

info "msmtp configured."
mark_done "mail_sender"
