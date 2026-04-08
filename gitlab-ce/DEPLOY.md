# GitLab CE — Docker Compose Deployment Guide

Self-hosted GitLab CE with container registry, deployed via Docker Compose.

## Prerequisites

- Linux host with Docker and Docker Compose installed
- A dedicated data disk or directory (guide uses `/data`)
- A domain name pointing to your host (e.g., `gitlab.example.lan`)
- Ports `80`, `443`, `2222`, and `5050` available on the host

## Quick Start

```bash
# 1. Copy files to the host
scp -r gitlab-ce/ user@<HOST_IP>:/tmp/gitlab-ce/

# 2. SSH in and run the setup script
ssh user@<HOST_IP>
sudo bash /tmp/gitlab-ce/setup.sh
```

The setup script handles directory creation, self-signed SSL, firewall (UFW), and starts everything via Docker Compose. First boot takes 3-5 minutes.

---

## Configuration

Before running, edit these variables at the top of `setup.sh`:

| Variable | Description | Default |
|----------|-------------|---------|
| `GITLAB_HOST` | Your GitLab FQDN | `gitlab.example.lan` |
| `GITLAB_IP` | Host IP address | `10.0.0.10` |

And update the matching values in `docker-compose.yml` (the `hostname` and `GITLAB_OMNIBUS_CONFIG` URLs).

---

## What's Included

### docker-compose.yml

| Service | Image | Purpose |
|---------|-------|---------|
| `gitlab` | `gitlab/gitlab-ce:latest` | GitLab CE + Container Registry |

### Exposed Ports

| Port | Service |
|------|---------|
| 80 | HTTP (redirects to HTTPS) |
| 443 | HTTPS (GitLab web UI + API) |
| 2222 | Git over SSH |
| 5050 | Container Registry |

---

## Step 1: First Login

```bash
# Get the initial root password (expires in 24 hours!)
docker exec gitlab-ce cat /etc/gitlab/initial_root_password
```

1. Browse to `https://gitlab.example.lan`
2. Login: `root` / password from above
3. **Change the root password immediately** — Settings → Password

---

## Step 2: DNS

Point your domain to the host IP. Options:

- **Router/firewall DNS override** — add a host override for `gitlab.example.lan` → `<HOST_IP>`
- **Local `/etc/hosts`** — add `<HOST_IP>  gitlab.example.lan` on each client machine
- **Internal DNS server** — add an A record

---

## Step 3: Firewall Rules (if applicable)

If the host is on a segmented network, allow inbound traffic:

| Source | Dest | Ports | Protocol | Purpose |
|--------|------|-------|----------|---------|
| Your workstation / LAN | Host IP | 443, 80 | TCP | Web access |
| Your workstation / LAN | Host IP | 2222 | TCP | Git SSH |
| Your workstation / LAN | Host IP | 5050 | TCP | Container registry |
| CI/CD runners | Host IP | 443, 5050 | TCP | Pulling images / pushing code |

---

## Usage

### Container Registry

```bash
# Login
docker login gitlab.example.lan:5050 -u root -p <access-token>

# Tag and push
docker tag myapp:latest gitlab.example.lan:5050/root/myapp:latest
docker push gitlab.example.lan:5050/root/myapp:latest
```

### Git Operations

```bash
# HTTPS
git clone https://gitlab.example.lan/root/my-project.git

# SSH
git clone ssh://git@gitlab.example.lan:2222/root/my-project.git
```

### Backups

```bash
# Create a backup
docker exec gitlab-ce gitlab-backup create

# Backups stored in /data/gitlab/data/backups/
# Retention: 7 days (configurable in docker-compose.yml)
```

### Password Reset (without email)

```bash
docker exec -it gitlab-ce gitlab-rake "gitlab:password:reset[root]"
```

---

## Recommended Admin Settings

After first login, apply these under **Admin → Settings**:

- **Sign-up**: Disabled (General → Sign-up restrictions)
- **Default project visibility**: Private (General → Visibility)
- **Outbound requests**: Allow local network from webhooks/system hooks, add your subnets to the allowlist

## Troubleshooting

```bash
# Check GitLab status
docker exec gitlab-ce gitlab-ctl status

# View logs
docker logs gitlab-ce
docker exec gitlab-ce gitlab-ctl tail

# Restart everything
cd /opt/gitlab && docker compose restart

# Check memory usage
docker stats gitlab-ce

# Reconfigure after editing gitlab.rb
docker exec gitlab-ce gitlab-ctl reconfigure
```
