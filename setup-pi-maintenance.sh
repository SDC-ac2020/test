#!/bin/bash

set -e

echo "Updating package lists..."
apt update

echo "Installing required packages..."
apt install -y \
    unattended-upgrades \
    apt-listchanges \
    clamav \
    clamav-daemon \
    clamav-freshclam

echo "Enabling unattended-upgrades..."
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "Configuring automatic upgrades..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo "Configuring Tuesday 9 PM upgrade schedule..."
mkdir -p /etc/systemd/system/apt-daily-upgrade.timer.d

cat > /etc/systemd/system/apt-daily-upgrade.timer.d/override.conf <<EOF
[Timer]
OnCalendar=
OnCalendar=Tue *-*-* 21:00:00
Persistent=true
EOF

systemctl daemon-reload
systemctl restart apt-daily-upgrade.timer

echo "Updating ClamAV signatures..."
systemctl stop clamav-freshclam || true
freshclam
systemctl start clamav-freshclam || true

echo "Ensuring clamd is running..."
systemctl enable clamav-daemon
systemctl restart clamav-daemon

echo "Creating virus scan script..."

cat > /root/scanvirus.sh <<'EOF'
#!/bin/bash

LOGFILE="/var/log/clamav-scan.log"

echo "===================================" >> "$LOGFILE"
echo "Scan started: $(date)" >> "$LOGFILE"
echo "===================================" >> "$LOGFILE"

clamdscan \
    --fdpass \
    --multiscan \
    --infected \
    --log="$LOGFILE" \
    --exclude-dir="^/proc" \
    --exclude-dir="^/sys" \
    --exclude-dir="^/dev" \
    --exclude-dir="^/run" \
    --exclude-dir="^/tmp" \
    --exclude-dir="^/var/tmp" \
    --exclude-dir="^/mnt" \
    --exclude-dir="^/media" \
    /

echo "" >> "$LOGFILE"
EOF

chmod +x /root/scanvirus.sh

echo "Creating maintenance cron jobs..."

cat > /etc/cron.d/pi-maintenance <<EOF
# Virus scan daily at 9 PM
0 21 * * * root /root/scanvirus.sh

# Reboot every day at 7 AM
0 7 * * * root /sbin/shutdown -r now
EOF

chmod 644 /etc/cron.d/pi-maintenance

echo "Verifying configuration..."

systemctl enable apt-daily-upgrade.timer

echo ""
echo "Setup complete."
echo ""
echo "Useful checks:"
echo "  systemctl list-timers apt-daily-upgrade.timer"
echo "  systemctl status clamav-daemon"
echo "  freshclam --version"
echo "  sudo /root/scanvirus.sh"
echo "  tail -f /var/log/clamav-scan.log"

