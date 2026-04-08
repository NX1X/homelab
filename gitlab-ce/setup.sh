#!/bin/bash
# ============================================================
# GitLab CE — Post-deploy setup script
# Run this on the host after copying the project files.
#
# Usage: sudo bash setup.sh
# ============================================================

set -e

# ----- EDIT THESE TO MATCH YOUR ENVIRONMENT -----
GITLAB_IP="10.0.0.10"
GITLAB_HOST="gitlab.example.lan"
# -------------------------------------------------

echo "========================================"
echo " GitLab CE Setup"
echo " IP: $GITLAB_IP"
echo " URL: https://$GITLAB_HOST"
echo "========================================"

# --- Check data disk is mounted ---
if ! mountpoint -q /data; then
  echo "ERROR: /data is not mounted. Data disk missing?"
  echo "Check: lsblk, cat /etc/fstab"
  exit 1
fi

# --- Create directories ---
echo "[1/6] Creating directories on /data..."
mkdir -p /data/gitlab/config/ssl
mkdir -p /data/gitlab/logs
mkdir -p /data/gitlab/data
# --- SSL certificate ---
echo "[2/6] Checking SSL certificate..."
if [ -f "/data/gitlab/config/ssl/${GITLAB_HOST}.crt" ]; then
  echo "  Certificate found for ${GITLAB_HOST}"
else
  echo "  No certificate found — generating self-signed (replace with CA cert later)"
  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout "/data/gitlab/config/ssl/${GITLAB_HOST}.key" \
    -out "/data/gitlab/config/ssl/${GITLAB_HOST}.crt" \
    -subj "/CN=${GITLAB_HOST}" \
    -addext "subjectAltName=DNS:${GITLAB_HOST},IP:${GITLAB_IP}"
fi
chmod 600 "/data/gitlab/config/ssl/${GITLAB_HOST}.key"

# --- Open firewall ports ---
echo "[3/6] Opening UFW ports..."
ufw allow 80/tcp comment "GitLab HTTP"
ufw allow 443/tcp comment "GitLab HTTPS"
ufw allow 2222/tcp comment "GitLab Git SSH"
ufw allow 5050/tcp comment "GitLab Container Registry"
ufw reload

# --- Copy docker-compose.yml ---
echo "[4/6] Setting up docker-compose..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
  mkdir -p /opt/gitlab
  cp "$SCRIPT_DIR/docker-compose.yml" /opt/gitlab/docker-compose.yml
else
  echo "ERROR: docker-compose.yml not found next to this script"
  exit 1
fi

# --- Start GitLab ---
echo "[5/6] Starting GitLab (first boot takes 3-5 minutes)..."
cd /opt/gitlab
docker compose up -d

# --- Wait for GitLab to become healthy ---
echo "[6/6] Waiting for GitLab to start..."
echo "  This takes 3-5 minutes on first boot. Be patient."
echo ""

TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  if docker exec gitlab-ce gitlab-ctl status &>/dev/null; then
    # Check if web is responding
    if curl -sk -o /dev/null -w "%{http_code}" "https://localhost" 2>/dev/null | grep -q "302\|200"; then
      echo ""
      echo "GitLab is UP!"
      break
    fi
  fi
  printf "."
  sleep 10
  ELAPSED=$((ELAPSED + 10))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo ""
  echo "WARNING: GitLab didn't respond within ${TIMEOUT}s."
  echo "It may still be starting. Check: docker logs gitlab-ce"
fi

# --- Print next steps ---
echo ""
echo "========================================"
echo " GitLab CE is running!"
echo "========================================"
echo ""
echo "Get the initial root password:"
echo "  docker exec gitlab-ce cat /etc/gitlab/initial_root_password"
echo ""
echo "Access GitLab:"
echo "  https://$GITLAB_HOST  (add a DNS entry first)"
echo "  https://$GITLAB_IP    (direct IP, cert warning expected)"
echo ""
echo "Container Registry:"
echo "  docker login $GITLAB_HOST:5050"
echo ""
echo "Git clone (HTTPS):"
echo "  git clone https://$GITLAB_HOST/root/my-project.git"
echo ""
echo "Git clone (SSH):"
echo "  git clone ssh://git@${GITLAB_HOST}:2222/root/my-project.git"
echo ""
echo "IMPORTANT: The initial root password expires after 24 hours."
echo "Log in and change it immediately!"
echo ""
