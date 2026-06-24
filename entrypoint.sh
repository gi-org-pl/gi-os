#!/bin/bash
set -e

if [ -z "${NB_SETUP_KEY}" ]; then
  echo "[ERROR] NB_SETUP_KEY is not set. Pass it via -e NB_SETUP_KEY=<your-key>" >&2
  exit 1
fi

# Unlock Alpine's locked-by-default root account so sshd accepts pubkey auth.
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/10806
# https://www.tenable.com/blog/cve-2019-5021-hard-coded-null-root-password-found-in-alpine-linux-docker-images
sed -i 's/^root:!/root:*/' /etc/shadow

if [ -n "${SSH_AUTHORIZED_KEY}" ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  echo "${SSH_AUTHORIZED_KEY}" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "[INFO] SSH authorized key installed for root."
fi

# Fresh Alpine images ship without host keys.
ssh-keygen -A

echo "[INFO] Starting sshd..."
/usr/sbin/sshd

# ── Graceful shutdown ─────────────────────────────────────────────────────────
cleanup() {
  echo "[INFO] Shutting down NetBird peer..."
  netbird down
  echo "[INFO] Stopping NetBird daemon..."
  kill "${DAEMON_PID}" 2>/dev/null || true
  wait "${DAEMON_PID}" 2>/dev/null || true
  exit 0
}
trap cleanup SIGTERM SIGINT

# ── Start NetBird daemon ──────────────────────────────────────────────────────
echo "[INFO] Starting NetBird daemon..."
netbird service run &
DAEMON_PID=$!

# ── Wait for daemon socket ────────────────────────────────────────────────────
SOCKET="/var/run/netbird.sock"
TIMEOUT=30
ELAPSED=0
echo "[INFO] Waiting for NetBird daemon socket..."
until [ -S "${SOCKET}" ]; do
  if [ "${ELAPSED}" -ge "${TIMEOUT}" ]; then
    echo "[ERROR] Timed out waiting for ${SOCKET}" >&2
    exit 1
  fi
  sleep 1
  ELAPSED=$((ELAPSED + 1))
done
echo "[INFO] Daemon is ready."

# ── Disconnect first to ensure flags are applied fresh ───────────────────────
netbird down 2>/dev/null || true

# ── Bring up NetBird peer ─────────────────────────────────────────────────────
ARGS="--setup-key ${NB_SETUP_KEY}"
ARGS="${ARGS} --disable-ssh-auth"
[ -n "${NB_MANAGEMENT_URL}" ] && ARGS="${ARGS} --management-url ${NB_MANAGEMENT_URL}"
[ -n "${NB_HOSTNAME}" ]       && ARGS="${ARGS} --hostname ${NB_HOSTNAME}"
echo "[INFO] Bringing up NetBird peer..."
netbird up ${ARGS}

echo "[INFO] NetBird peer is up. Container will run until stopped."
wait "${DAEMON_PID}"
