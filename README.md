# NX1X LAB

![Active Since](https://img.shields.io/badge/Active%20Since-15%20July%202024-blue?style=flat-square)
![Visitors](https://visitor-badge.laobi.icu/badge?page_id=NX1X.homelab)


## About This Project

I've always been a multi-disciplinary person - every aspect of technology interests me. The problem is never the curiosity, it's finding enough time. Well, I never found enough of it, but I built this anyway.

I planned and built a multi-node Proxmox cluster, a managed enterprise switch, a professional pfSense firewall, and a massive UPS. Yes, I have a server rack. And yes, my office is a bit warmer than the rest of the house. That's a sacrifice I can live with.

This project is genuinely addicting - tons of fun. I get to work at the bare metal level, start from power, move up through the physical networking layer, and build everything above it from scratch. I started it out of pure love for trying, discovering, and exploring new things. I wanted to level up my skills across the board. It became my greatest hobby - I stopped gaming, and whenever I have free time, this is where I go.

The idea is simple: build a company-like infrastructure covering every aspect I can think of. My nickname is NX1X and I call my projects **NX1X LAB** - where I try, test, break, and learn.

I won't go into the full architecture details here for privacy and security reasons. If you have questions or want to know more, feel free to reach out: [nx1xlab.dev/contact](https://nx1xlab.dev/contact/)

---

> Configs, internal details, and some tools are intentionally not published here for security and privacy reasons.

> I'll be publishing configurations from time to time. Latest upload: Self-hosted GitLab & GitLab Runner. Enjoy!
---


## Infrastructure

![Proxmox](https://img.shields.io/badge/Proxmox-E57000?style=flat-square&logo=proxmox&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![Debian](https://img.shields.io/badge/Debian-A81D33?style=flat-square&logo=debian&logoColor=white)
![ZFS](https://img.shields.io/badge/OpenZFS-F00000?style=flat-square&logo=openzfs&logoColor=white)

- **Hypervisor** - Proxmox VE, multi-node cluster
- **Firewall / Router** - pfSense (DNS, DHCP, VPN, Next-Generation Firewall)
- **Networking** - Managed switch, VLAN-segmented zones, encrypted VPN for remote access
- **Storage** - ZFS (RAIDZ1, snapshots), software RAID, NFS, TrueNAS Scale
- **Backups** - Scheduled cluster-wide VM backups + ZFS snapshots
- **UPS** - Graceful cluster shutdown on power loss (NUT)

## Containers & Orchestration

![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Portainer](https://img.shields.io/badge/Portainer-13BEF9?style=flat-square&logo=portainer&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white)

- Docker + Docker Compose + Portainer
- Kubernetes
- ArgoCD

## IaC & Dev

![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white)
![Ansible](https://img.shields.io/badge/Ansible-EE0000?style=flat-square&logo=ansible&logoColor=white)
![GitLab](https://img.shields.io/badge/GitLab-FC6D26?style=flat-square&logo=gitlab&logoColor=white)

- Terraform - VM provisioning as code
- Ansible - configuration management across all nodes
- GitLab (self-hosted) - Git, CI/CD, issue tracking

## Security & Monitoring

![pfSense](https://img.shields.io/badge/pfSense-212670?style=flat-square&logoColor=white)
![Wazuh](https://img.shields.io/badge/Wazuh-005571?style=flat-square&logoColor=white)
![Slack](https://img.shields.io/badge/Slack_Alerts-4A154B?style=flat-square&logo=slack&logoColor=white)

- Wazuh XDR & SIEM - centralized log analysis and intrusion detection on all nodes
- Syslog - centralized log collection from all infrastructure components
- Next-Generation Firewall (NGFW) with IDS/IPS - application-aware traffic inspection, intrusion detection and prevention
- Internal CA - TLS for all internal services, no plain HTTP
- Zero trust network access - all remote access goes through identity-verified encrypted tunnels
- Cluster monitoring - real-time Slack alerts for VM events, resource usage, ZFS health, and security events

## Self-hosted Apps

![Nextcloud](https://img.shields.io/badge/Nextcloud-0082C9?style=flat-square&logo=nextcloud&logoColor=white)
![Jellyfin](https://img.shields.io/badge/Jellyfin-00A4DC?style=flat-square&logo=jellyfin&logoColor=white)
![Immich](https://img.shields.io/badge/Immich-4250AF?style=flat-square&logo=immich&logoColor=white)

| App | Purpose |
|---|---|
| Nextcloud | Personal cloud, file sync, calendar |
| Jellyfin | Media streaming |
| Immich | Photo and video library |
| ARMA 3 server | Private game server |

## Tools I Built

| Tool | Description | Status |
|---|---|---|
| SwitchSentinel | Python CLI for automated switch configuration backups | Personal / Private |
| [pfSentinel](https://github.com/nx1x/pfSentinel) | Python CLI for pfSense management and automation | Open Source |

