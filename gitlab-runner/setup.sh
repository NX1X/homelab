#!/bin/bash
# ============================================================
# GitLab Runner — Post-deploy setup script
# Run this on the runner host after copying the project files.
#
# Usage: sudo bash setup.sh
# ============================================================

set -euo pipefail

# ----- EDIT THESE TO MATCH YOUR ENVIRONMENT -----
RUNNER_IP="10.0.0.11"
GITLAB_URL="https://gitlab.example.lan"
GITLAB_IP="10.0.0.10"
GITLAB_HOST="gitlab.example.lan"
# -------------------------------------------------

echo "========================================"
echo " GitLab Runner Setup"
echo " IP: $RUNNER_IP"
echo " GitLab: $GITLAB_URL"
echo "========================================"

# --- Check data disk is mounted ---
if ! mountpoint -q /data; then
  echo "ERROR: /data is not mounted. Data disk missing?"
  echo "Check: lsblk, cat /etc/fstab"
  exit 1
fi

# --- Create directories on data disk ---
echo "[1/7] Creating directories on /data..."
mkdir -p /data/gitlab-runner/config
mkdir -p /data/gitlab-runner/certs
mkdir -p /data/docker

# --- Move Docker storage to data disk ---
echo "[2/7] Configuring Docker to use /data..."
if [ ! -f /etc/docker/daemon.json ] || ! grep -q '/data/docker' /etc/docker/daemon.json; then
  mkdir -p /etc/docker
  cat > /etc/docker/daemon.json <<'EOF'
{
  "data-root": "/data/docker"
}
EOF
  systemctl restart docker
  echo "  Docker data-root set to /data/docker"
else
  echo "  Docker already configured for /data"
fi

# --- DNS entry for GitLab ---
echo "[3/7] Adding GitLab DNS to /etc/hosts..."
if ! grep -q "$GITLAB_HOST" /etc/hosts; then
  echo "$GITLAB_IP $GITLAB_HOST" >> /etc/hosts
  echo "  Added $GITLAB_IP $GITLAB_HOST"
else
  echo "  Already in /etc/hosts"
fi

# --- Fetch GitLab's self-signed certificate ---
echo "[4/7] Fetching GitLab SSL certificate..."
CERT_FILE="/data/gitlab-runner/certs/ca.crt"

if ! openssl s_client -showcerts -connect "$GITLAB_HOST:443" </dev/null 2>/dev/null \
  | openssl x509 -outform PEM > "$CERT_FILE" 2>/dev/null; then
  echo "  ERROR: Failed to fetch certificate from $GITLAB_HOST:443"
  echo "  Is GitLab running and reachable?"
  rm -f "$CERT_FILE"
  exit 1
fi

if [ ! -s "$CERT_FILE" ]; then
  echo "  ERROR: Fetched certificate is empty. Connection may have failed."
  rm -f "$CERT_FILE"
  exit 1
fi

echo "  Certificate fetched. Verifying..."
if ! openssl x509 -in "$CERT_FILE" -noout -text >/dev/null 2>&1; then
  echo "  ERROR: Fetched file is not a valid certificate."
  rm -f "$CERT_FILE"
  exit 1
fi

cp "$CERT_FILE" /usr/local/share/ca-certificates/gitlab.crt
update-ca-certificates
echo "  Certificate trusted system-wide"

# --- Copy docker-compose.yml ---
echo "[5/7] Setting up docker-compose..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/docker-compose.yml" ]; then
  mkdir -p /opt/gitlab-runner
  cp "$SCRIPT_DIR/docker-compose.yml" /opt/gitlab-runner/docker-compose.yml
else
  echo "ERROR: docker-compose.yml not found next to this script"
  exit 1
fi

# --- Start runner container ---
echo "[6/7] Starting GitLab Runner container..."
cd /opt/gitlab-runner
docker compose up -d

echo "[7/7] Waiting for runner container to start..."
sleep 5
if docker ps | grep -q gitlab-runner; then
  echo "  Runner container is running"
else
  echo "  ERROR: Runner container failed to start"
  docker logs gitlab-runner
  exit 1
fi

# --- Print registration instructions ---
echo ""
echo "========================================"
echo " GitLab Runner is running!"
echo "========================================"
echo ""
echo "NEXT: Register the runner with GitLab."
echo ""
echo "1. In GitLab UI: Admin → CI/CD → Runners → New instance runner"
echo "   - Tags: docker, linux"
echo "   - Check 'Run untagged jobs'"
echo "   - Click 'Create runner' → copy the registration token"
echo ""
echo "2. Run this command (paste your token):"
echo ""
echo "   docker exec -it gitlab-runner gitlab-runner register \\"
echo "     --url $GITLAB_URL \\"
echo "     --tls-ca-file /etc/gitlab-runner/certs/ca.crt \\"
echo "     --executor docker \\"
echo "     --docker-image docker:latest \\"
echo "     --docker-extra-hosts '$GITLAB_HOST:$GITLAB_IP'"
echo ""
echo "3. Verify registration:"
echo "   docker exec gitlab-runner gitlab-runner verify"
echo ""
echo "4. Check in GitLab UI: Admin → CI/CD → Runners"
echo "   The runner should show as online (green)."
echo ""
