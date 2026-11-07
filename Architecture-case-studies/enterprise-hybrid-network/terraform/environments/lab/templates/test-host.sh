#!/bin/bash
set -euo pipefail
# Ubuntu's AWS image includes Python 3 and the SSM agent snap; no apt egress needed.
mkdir -p /opt/network-test
printf 'network lab listener ready\n' >/opt/network-test/index.html
cat >/etc/systemd/system/network-test.service <<'UNIT'
[Unit]
Description=Network lab TCP listener
After=network.target
[Service]
User=nobody
WorkingDirectory=/opt/network-test
ExecStart=/usr/bin/python3 -m http.server 8080 --bind 0.0.0.0
Restart=always
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now network-test.service
systemctl restart snap.amazon-ssm-agent.amazon-ssm-agent.service
