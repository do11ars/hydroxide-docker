#!/usr/bin/env bash
set -e

/hydroxide/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
TAILSCALED_PID=$!

until /hydroxide/tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname="${RENDER_SERVICE_NAME}"; do
  sleep 0.5
done
echo "Tailscale is up."

/usr/bin/hydroxide -smtp-host 0.0.0.0 -imap-host 0.0.0.0 -disable-carddav serve &
HYDROXIDE_PID=$!

socat TCP4-LISTEN:80,fork,reuseaddr SOCKS5:127.0.0.1:1055:100.75.146.49:80 &
SOCAT_PID=$!

wait -n ${TAILSCALED_PID} ${HYDROXIDE_PID} ${SOCAT_PID}
