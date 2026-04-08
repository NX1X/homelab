# GitLab Runner — Docker Compose Deployment Guide

A standalone GitLab Runner using the Docker executor, deployed via Docker Compose. Connects to a self-hosted GitLab CE instance with a self-signed certificate.

> **Note:** If you want the runner on the same host as GitLab, see the `gitlab-ce/` project — it includes a runner service in the same compose file. Use this project when the runner runs on a **separate host**.

## Prerequisites

- Linux host with Docker and Docker Compose installed
- A dedicated data directory (guide uses `/data`)
- Network access to your GitLab instance (HTTPS on port 443)

## Quick Start

```bash
# 1. Copy files to the runner host
scp -r gitlab-runner/ user@<RUNNER_HOST_IP>:/tmp/gitlab-runner/

# 2. SSH in and run setup
ssh user@<RUNNER_HOST_IP>
sudo bash /tmp/gitlab-runner/setup.sh
```

The setup script:
- Creates directories on `/data`
- Moves Docker storage to `/data/docker`
- Adds GitLab hostname to `/etc/hosts`
- Fetches and validates GitLab's self-signed certificate
- Starts the runner container

---

## Configuration

Edit these variables at the top of `setup.sh`:

| Variable | Description | Default |
|----------|-------------|---------|
| `RUNNER_IP` | This host's IP | `10.0.0.11` |
| `GITLAB_URL` | GitLab URL | `https://gitlab.example.lan` |
| `GITLAB_IP` | GitLab host IP | `10.0.0.10` |
| `GITLAB_HOST` | GitLab FQDN | `gitlab.example.lan` |

---

## Step 1: Register the Runner

After `setup.sh` completes:

1. In GitLab UI: **Admin → CI/CD → Runners → New instance runner**
   - Tags: `docker`, `linux`
   - Check **Run untagged jobs**
   - Click **Create runner** → copy the `glrt-` token

2. Register:

```bash
docker exec -it gitlab-runner gitlab-runner register \
  --url https://gitlab.example.lan \
  --token <glrt-TOKEN-FROM-UI> \
  --tls-ca-file /etc/gitlab-runner/certs/ca.crt \
  --executor docker \
  --docker-image docker:latest \
  --docker-extra-hosts 'gitlab.example.lan:<GITLAB_IP>'
```

3. Verify:

```bash
docker exec gitlab-runner gitlab-runner verify
```

4. Check in GitLab UI: **Admin → CI/CD → Runners** — runner should show as online (green).

---

## Step 2: DNS (optional)

If your network has internal DNS, add an entry for the runner host. Otherwise, the `setup.sh` script handles GitLab resolution via `/etc/hosts`.

---

## Step 3: Firewall Rules (if applicable)

The runner needs to reach GitLab. If they're on separate network segments:

| Source | Dest | Ports | Protocol | Purpose |
|--------|------|-------|----------|---------|
| Runner host | GitLab host | 443 | TCP | API + Git HTTPS |
| Runner host | GitLab host | 5050 | TCP | Container registry |

If CI jobs need to deploy to other hosts, add rules for those destinations as needed.

---

## Test the Runner

Create `.gitlab-ci.yml` in any project:

```yaml
stages:
  - test
  - build

test-runner:
  stage: test
  image: alpine:latest
  script:
    - echo "Runner is working!"
    - hostname
    - whoami

build-image:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  script:
    - docker info
    - echo "Docker-in-Docker works!"
    # Uncomment to test registry push:
    # - echo $CI_REGISTRY_PASSWORD | docker login --username $CI_REGISTRY_USER --password-stdin $CI_REGISTRY
    # - docker build -t $CI_REGISTRY_IMAGE:latest .
    # - docker push $CI_REGISTRY_IMAGE:latest
```

Push and check the pipeline in GitLab UI → CI/CD → Pipelines.

---

## Troubleshooting

```bash
# Check runner status
docker exec gitlab-runner gitlab-runner verify
docker exec gitlab-runner gitlab-runner list

# View runner logs
docker logs gitlab-runner

# Re-register runner (if token expired)
docker exec gitlab-runner gitlab-runner unregister --all-runners
# Then re-run the register command from Step 1

# Restart runner
cd /opt/gitlab-runner && docker compose restart

# Check Docker storage usage
du -sh /data/docker/

# Certificate issues — re-fetch GitLab cert
openssl s_client -showcerts -connect gitlab.example.lan:443 </dev/null 2>/dev/null \
  | openssl x509 -outform PEM > /data/gitlab-runner/certs/ca.crt
docker compose restart
```
