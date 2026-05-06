<div align="center">

# labctl

**Manage 1 to 100+ macOS machines from a single terminal.**

No MDM. No agents. No cloud. No monthly fees. Just SSH.

---

Pownkumar A (Founder of Korelium) · Last updated: May 6, 2026

</div>

---

## Why labctl?

If you manage a Mac lab — a school, college, coworking space, or creative studio — you know the pain:

- **Jamf** costs $4–8/device/month ($1,500+/year for 30 Macs)
- **Mosyle/Kandji** require MDM enrollment, Apple Business Manager, cloud dependency
- **Ansible** needs YAML expertise and has no Mac-native understanding
- **Doing it manually** means SSH-ing into 30+ machines one by one

**labctl solves this.** It's a lightweight, Fish shell-based CLI that manages your entire Mac lab over SSH. No agents to install on client machines. No cloud accounts. No subscriptions. It runs entirely on your local network.

### What can it do?

| Feature | Single Machine | All Machines (Parallel) |
|---|:---:|:---:|
| **Power** — Reboot, Shutdown, Sleep | `mac 23 reboot` | `mac-all reboot` |
| **Status** — Online/Offline with uptime | `mac 23 status` | `mac-all status` |
| **Users** — Create, Delete (secure wipe), List | `mac-user-create 23 student pass` | `mac-all-user-create student pass` |
| **Software** — Install/Remove via Homebrew | `mac-pkg 23 cask firefox` | `mac-pkg-all cask firefox` |
| **Homebrew** — Install/Check/Uninstall Homebrew itself | `mac-brew-install 23` | `mac-brew-install-all` |
| **Auto-Login** — Enable/Disable/Status | `mac-autologin-on 23 pass` | `mac-all-autologin-on pass` |
| **Screen Monitor** — View student screens live | `mac-monitor 23` | — |
| **Presentation** — Push your screen to students | `mac-present-host 23` | `mac-present` |
| **Notifications** — Send alerts to desktops | `mac-notify 23 "Time's up!"` | `mac-all-notify "Time's up!"` |
| **Audio Alerts** — Play sound + notification | `mac-alert 23 "Submit now"` | `mac-all-alert "Submit now"` |
| **Network** — Scrape IPs/MACs, Wake-on-LAN | `mac-wake 23` | `mac-all-wake` |
| **Admin** — Setup passwordless sudo | `mac-sudo-setup 23` | `mac-sudo-setup-all` |
| **Emergency** — Kill all hanging processes | `mac-kill-all` | — |

> **Design pattern:** Every feature works on a single machine first (`mac-*`), then scales to all machines in parallel (`mac-all-*`). Test on one, deploy to all.

---

## Prerequisites

Before using labctl, you need:

1. **An Admin Mac** — Your machine where you'll run commands from
2. **Lab Macs** — The machines you want to manage (1 to 100+)
3. **All Macs on the same local network** (no static IP required — uses `.local` mDNS)
4. **Fish Shell** installed on the Admin Mac
5. **SSH access** from Admin Mac to all Lab Macs (key-based auth recommended)

> **Important:** All lab machines must have the **same admin username** (e.g., `labuser`). This is how labctl runs commands in parallel — it SSHs into `labuser@mac-001.local`, `labuser@mac-002.local`, etc. Create this account on every Mac during initial setup.

### What you don't need:
- Static IP addresses
- Cloud accounts or internet access
- MDM enrollment or Apple Business Manager
- Any software installed on the Lab Macs (beyond macOS defaults)
- Any monthly subscription

---

## Installation

### Step 1: Install Fish Shell (Admin Mac only)

```bash
brew install fish
```

### Step 2: Clone labctl

```bash
git clone https://github.com/iampownkumar/labctl.git
cd labctl
```

### Step 3: Configure Your Lab

Edit `fish/modules/config.fish`:
```fish
set -g LAB_USER "your-lab-username"
set -g LAB_DOMAIN "local"
```

Edit `fish/modules/hostnames.fish`:
```fish
set -g MACHINES \
  mac-001 mac-002 mac-003 mac-004 mac-005 \
  mac-006 mac-007 mac-008 mac-009 mac-010
```

### Step 4: Add to Fish config

Add this to `~/.config/fish/config.fish`:
```fish
set -gx LAB_USER "your-lab-username"
set -gx LAB_DOMAIN "local"
source /path/to/labctl/fish/init.fish
```

### Step 5: Setup SSH Key Authentication

```fish
ssh-keygen -t ed25519
ssh-copy-id your-lab-username@mac-001.local
ssh-copy-id your-lab-username@mac-002.local
# repeat for all machines
```

### Step 6: Setup Passwordless Sudo

```fish
mac-sudo-setup 1       # test on one machine first
mac-sudo-setup-all     # then all machines
```

### Step 7: Verify

```fish
mac-all status
```

Expected output:
```
Checking lab status (parallel, 5s timeout)...
mac-001 : ONLINE  → 10:23  up 2 days, 5:14, 1 user
mac-002 : ONLINE  → 10:23  up 2 days, 5:14, 1 user
mac-003 : OFFLINE
---------------------------------------------
ONLINE : 2 | OFFLINE: 1
```

---

## Usage Guide

### Power Management

```fish
mac 23 status        # Check uptime of mac-023
mac 23 reboot        # Reboot mac-023
mac 23 down          # Shutdown mac-023
mac 23 sleep         # Sleep mac-023
mac 23               # SSH into mac-023 directly

mac-all status       # Check all machines (parallel)
mac-all reboot       # Reboot all machines
mac-all down         # Shutdown all machines
```

### User Management

```fish
mac-user-create 23 student pass123              # Standard user
mac-user-create-admin 23 labadmin securepass     # Admin user
mac-user-list 23                                 # List all users
mac-user-delete 23 student                       # Delete (secure wipe)

mac-all-user-create student pass123              # Create on ALL
mac-all-user-delete student                      # Delete from ALL
mac-all-user-list                                # List on ALL
```

### Software Installation

```fish
mac-pkg 23 cask firefox                  # Install app on one machine
mac-pkg-all cask visual-studio-code      # Install on all machines
mac-pkg 23 formula git                   # Install CLI tool
mac-pkg-remove 23 cask firefox           # Remove from one
mac-pkg-remove-all cask firefox          # Remove from all
```

### Homebrew Management

```fish
mac-brew-install 23       # Install Homebrew on one machine
mac-brew-check-all        # Check status across the lab
mac-brew-install-all      # Install on all machines
```

### Auto-Login

```fish
mac-autologin-on 23 password        # Enable
mac-autologin-off 23                # Disable
mac-autologin-status 23             # Check

mac-all-autologin-on password       # Enable lab-wide
mac-all-autologin-off               # Disable lab-wide
mac-all-autologin-status            # Check lab-wide
```

### Screen Monitoring and Presentation

```fish
mac-monitor 23              # View a student's screen
mac-present                 # Push YOUR screen to all students
mac-present-host 23         # Push to one student
mac-stop-present            # Stop presentation
mac-stop-present-host 23    # Stop on one machine

mac-screen-setup 23         # One-time setup
mac-all-screen-setup        # Setup all machines
mac-screen-fix 23           # Fix screen sharing issues
```

### Notifications and Alerts

```fish
mac-notify 23 "Please save your work"       # Silent notification
mac-all-notify "Lab closing in 10 minutes"  # Notify all

mac-alert 23 "Submit your work now"         # Notification + sound
mac-all-alert "Time is up!"                 # Alert all
```

### Network and Wake-on-LAN

```fish
mac-scrape-inventory     # Scrape IP/MAC addresses from all machines
mac-wake 23              # Wake a sleeping/off machine
mac-all-wake             # Wake the entire lab
mac-wol-setup 23         # Enable Wake-on-LAN on a machine
mac-all-wol-setup        # Enable on all machines
```

### Emergency

```fish
mac-kill-all             # Kill all hanging SSH/brew processes
```

---

## Architecture

```
labctl/
├── fish/
│   ├── init.fish                    # Entry point — loads all modules
│   └── modules/
│       ├── config.fish              # Lab configuration (user, domain)
│       ├── hostnames.fish           # Machine inventory list
│       ├── power-management.fish    # SSH, status, reboot, shutdown, sleep
│       ├── users.fish               # User create, delete, list
│       ├── software.fish            # Package install/remove via Homebrew
│       ├── brew-management.fish     # Homebrew itself (install/check/uninstall)
│       ├── autologin.fish           # Auto-login enable/disable/status
│       ├── screens.fish             # Screen monitoring and presentation mode
│       ├── notify.fish              # Desktop notifications and audio alerts
│       ├── network.fish             # IP/MAC scraping, Wake-on-LAN
│       ├── admin.fish               # Passwordless sudo setup
│       └── emergency.fish           # Kill hanging processes
├── docs/
├── assets/
├── LICENSE
└── README.md
```

### Design Principles

1. **Single then All** — Every command works on one machine first, then has an `all` variant for lab-wide execution
2. **Parallel Execution** — Lab-wide commands run in parallel using background processes and `wait`
3. **No Agents** — Uses only SSH. Nothing to install on client machines
4. **No Cloud** — Runs entirely on your local network using mDNS (`.local`)
5. **Safe Passwords** — Passwords are base64-encoded for safe transport over SSH
6. **Validation First** — Dangerous operations (like sudoers changes) validate before applying

---

## Companion Tools

labctl is the CLI engine. For a GUI experience, check out:

- [Mac Lab Dashboard](https://github.com/iampownkumar/mac-os-monitering) — Flutter desktop app + FastAPI backend that provides a visual dashboard for all labctl operations

---

## License

Copyright 2026 Pownkumar A (Founder of Korelium)

Licensed under the GNU Affero General Public License v3.0 (AGPL-3.0). See [LICENSE](LICENSE) for details.

For commercial licensing inquiries, contact Pownkumar A at [Korelium](https://korelium.org).

