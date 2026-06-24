#!/bin/bash
set -e

if [ -z "${NB_SETUP_KEY}" ]; then
  echo "[ERROR] NB_SETUP_KEY is not set. Pass it via -e NB_SETUP_KEY=<your-key>" >&2
  exit 1
fi

# ── SSH authorized key setup ──────────────────────────────────────────────────
if [ -n "${SSH_AUTHORIZED_KEY}" ]; then
  mkdir -p /root/.ssh
  chmod 700 /root/.ssh
  echo "${SSH_AUTHORIZED_KEY}" >> /root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
  echo "[INFO] SSH authorized key installed for root."
fi

# ── Harden sshd config at runtime ────────────────────────────────────────────
rm -f /etc/ssh/sshd_config.d/50-cloud-init.conf
cat > /etc/ssh/sshd_config.d/00-hardened.conf << 'SSHEOF'
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
AuthorizedKeysFile .ssh/authorized_keys
SSHEOF
echo "[INFO] sshd hardened config applied."

# ── Start sshd ────────────────────────────────────────────────────────────────
echo "[INFO] Starting sshd..."
/usr/sbin/sshd

# ── Wipe any stale NetBird state baked into the image ────────────────────────
# Ensures each container start generates a fresh peer identity.
echo "[INFO] Clearing stale NetBird state..."
rm -f /var/lib/netbird/default.json
rm -f /var/lib/netbird/state.json
rm -f /var/lib/netbird/resolv.conf

# ── Graceful shutdown ─────────────────────────────────────────────────────────
cleanup() {
  echo "[INFO] Shutting down NetBird..."
  kill "${NB_PID}" 2>/dev/null || true
  wait "${NB_PID}" 2>/dev/null || true
  exit 0
}
trap cleanup SIGTERM SIGINT

# ── Build netbird up args ─────────────────────────────────────────────────────
ARGS="--setup-key ${NB_SETUP_KEY}"
ARGS="${ARGS} --disable-ssh-auth"
ARGS="${ARGS} --foreground-mode"
[ -n "${NB_MANAGEMENT_URL}" ] && ARGS="${ARGS} --management-url ${NB_MANAGEMENT_URL}"
[ -n "${NB_HOSTNAME}" ]       && ARGS="${ARGS} --hostname ${NB_HOSTNAME}"

# ── Start NetBird directly (foreground, no daemon) ────────────────────────────
# --foreground-mode: netbird up blokuje, nie potrzeba osobnego `netbird service run`
# Każdy kontener dostaje nowy PrivateKey bo default.json nie istnieje.
echo "[INFO] Starting NetBird peer (foreground)..."
netbird up ${ARGS} &
NB_PID=$!

echo "[INFO] NetBird peer is up. Container will run until stopped."
wait "${NB_PID}"