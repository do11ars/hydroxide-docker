#!/usr/bin/env bash
set -e

/hydroxide/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &
TAILSCALED_PID=$!

until /hydroxide/tailscale up --authkey="${TAILSCALE_AUTHKEY}" --hostname="${RENDER_SERVICE_NAME}"; do
  sleep 0.5
done
echo "Tailscale is up."

wait -n ${TAILSCALED_PID}
