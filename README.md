<![CDATA[<div align="center">

# 🖥️ labctl

### The Open-Source Mac Lab Management CLI

**Manage 1 to 100+ macOS machines from a single terminal.**

No MDM. No agents. No cloud. No monthly fees. Just SSH.

---

Built by **Pownkumar A** — Founder of [Korelium](https://korelium.org)

*Last updated: May 6, 2026*

</div>

---

## 🤔 Why labctl?

If you manage a Mac lab — a school, college, coworking space, or creative studio — you know the pain:

- **Jamf** costs $4–8/device/month ($1,500+/year for 30 Macs)
- **Mosyle/Kandji** require MDM enrollment, Apple Business Manager, cloud dependency
- **Ansible** needs YAML expertise and has no Mac-native understanding
- **Doing it manually** means SSH-ing into 30+ machines one by one

**labctl solves this.** It's a lightweight, Fish shell-based CLI that manages your entire Mac lab over SSH. No agents to install on client machines. No cloud accounts. No subscriptions. It runs entirely on your local network.

### What can it do?

| Feature | Single Machine | All Machines (Parallel) |
|---|:---:|:---:|
| 🔌 **Power** — Reboot, Shutdown, Sleep | `mac 23 reboot` | `mac-all reboot` |
| 📡 **Status** — Online/Offline check with uptime | `mac 23 status` | `mac-all status` |
| 👤 **Users** — Create, Delete (secure wipe), List | `mac-user-create 23 student pass` | `mac-all-user-create student pass` |
| 📦 **Software** — Install/Remove via Homebrew | `mac-pkg 23 cask firefox` | `mac-pkg-all cask firefox` |
| 🍺 **Homebrew** — Install/Check/Uninstall Homebrew itself | `mac-brew-install 23` | `mac-brew-install-all` |
| 🔐 **Auto-Login** — Enable/Disable/Status | `mac-autologin-on 23 pass` | `mac-all-autologin-on pass` |
| 👀 **Screen Monitor** — View student screens live | `mac-monitor 23` | — |
| 📺 **Presentation** — Push your screen to students | `mac-present-host 23` | `mac-present` |
| 🔔 **Notifications** — Send alerts to desktops | `mac-notify 23 "Time's up!"` | `mac-all-notify "Time's up!"` |
| 🔊 **Audio Alerts** — Play sound + notification | `mac-alert 23 "Submit now"` | `mac-all-alert "Submit now"` |
| 🌐 **Network** — Scrape IPs/MACs, Wake-on-LAN | `mac-wake 23` | `mac-all-wake` |
| 🔑 **Admin** — Setup passwordless sudo | `mac-sudo-setup 23` | `mac-sudo-setup-all` |
| 🛑 **Emergency** — Kill all hanging processes | `mac-kill-all` | — |

> **Design pattern:** Every feature works on a single machine first (`mac-*`), then scales to all machines in parallel (`mac-all-*`). Test on one, deploy to all.

---

## 📋 Prerequisites

Before using labctl, you need:

1. **An Admin Mac** — Your machine where you'll run commands from
2. **Lab Macs** — The machines you want to manage (1 to 100+)
3. **All Macs on the same local network** (no static IP required — uses `.local` mDNS)
4. **Fish Shell** installed on the Admin Mac
5. **SSH access** from Admin Mac to all Lab Macs (SSH key-based authentication recommended)

> [!IMPORTANT]
> **All lab machines must have the same admin username** (e.g., `labuser`). This is how labctl runs commands in parallel — it SSHs into `labuser@mac-001.local`, `labuser@mac-002.local`, etc. Create this account on every Mac during initial setup.

### What you DON'T need:
- ❌ Static IP addresses
- ❌ Cloud accounts or internet access
- ❌ MDM enrollment or Apple Business Manager
- ❌ Any software installed on the Lab Macs (beyond macOS defaults)
- ❌ Any monthly subscription

---

## 🚀 Installation

### Step 1: Install Fish Shell (Admin Mac only)

```bash
# Using Homebrew
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
# Set your lab user account name (the account that exists on all lab machines)
set -g LAB_USER "your-lab-username"

# Set the network domain (default is "local" for mDNS)
set -g LAB_DOMAIN "local"
```

Edit `fish/modules/hostnames.fish`:
```fish
# List all your machines. Naming convention: mac-001, mac-002, etc.
set -g MACHINES \
  mac-001 mac-002 mac-003 mac-004 mac-005 \
  mac-006 mac-007 mac-008 mac-009 mac-010
```

### Step 4: Add to Fish config

Add this line to your `~/.config/fish/config.fish`:
```fish
set -gx LAB_USER "your-lab-username"
set -gx LAB_DOMAIN "local"

source /path/to/labctl/fish/init.fish
```

### Step 5: Setup SSH Key Authentication

```fish
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519

# Copy to each lab machine (one-time setup)
ssh-copy-id your-lab-username@mac-001.local
ssh-copy-id your-lab-username@mac-002.local
# ... repeat for all machines
```

### Step 6: Setup Passwordless Sudo (Required for remote admin operations)

```fish
# Setup on a single machine first (test it!)
mac-sudo-setup 1

# Then setup on all machines
mac-sudo-setup-all
```

### Step 7: Verify

```fish
# Check if all machines are online
mac-all status
```

You should see:
```
📡 Checking lab status (parallel, 5s timeout)...
mac-001 : ONLINE  → 10:23  up 2 days,  5:14, 1 user, load averages: 1.23 0.98 0.87
mac-002 : ONLINE  → 10:23  up 2 days,  5:14, 1 user, load averages: 0.56 0.78 0.65
mac-003 : OFFLINE
---------------------------------------------
✅ ONLINE : 2 | ❌ OFFLINE: 1
```

---

## 📖 Usage Guide

### Power Management

```fish
mac 23 status        # Check uptime of mac-023
mac 23 reboot        # Reboot mac-023
mac 23 down          # Shutdown mac-023
mac 23 sleep         # Put mac-023 to sleep
mac 23               # SSH into mac-023 directly

mac-all status       # Check all machines (parallel)
mac-all reboot       # Reboot all machines
mac-all down         # Shutdown all machines
```

### User Management

```fish
# Create a standard user
mac-user-create 23 student pass123

# Create an admin user
mac-user-create-admin 23 labadmin securepass

# List all users on a machine
mac-user-list 23

# Delete a user (securely wipes home directory)
mac-user-delete 23 student

# Lab-wide user operations
mac-all-user-create student pass123         # Create on ALL machines
mac-all-user-create-admin admin securepass  # Create admin on ALL
mac-all-user-delete student                 # Delete from ALL machines
mac-all-user-list                           # List users on ALL machines
```

### Software Installation

```fish
# Install a macOS app (cask) on one machine
mac-pkg 23 cask firefox

# Install on all machines
mac-pkg-all cask visual-studio-code

# Install a CLI tool (formula)
mac-pkg 23 formula git
mac-pkg-all formula python

# Remove software
mac-pkg-remove 23 cask firefox
mac-pkg-remove-all cask firefox
```

### Homebrew Management

```fish
# Install Homebrew itself on a machine
mac-brew-install 23

# Check Homebrew status across the lab
mac-brew-check-all

# Install Homebrew on all machines
mac-brew-install-all
```

### Auto-Login

```fish
# Enable auto-login (useful for lab environments)
mac-autologin-on 23 password

# Disable auto-login
mac-autologin-off 23

# Check status
mac-autologin-status 23

# Lab-wide
mac-all-autologin-on password
mac-all-autologin-off
mac-all-autologin-status
```

### Screen Monitoring & Presentation

```fish
# Monitor a student's screen (opens macOS Screen Sharing)
mac-monitor 23

# Push YOUR screen to all students (presentation mode)
mac-present

# Push to a single student
mac-present-host 23

# Stop presentation
mac-stop-present
mac-stop-present-host 23

# Setup screen sharing on machines (one-time)
mac-screen-setup 23
mac-all-screen-setup

# Fix screen sharing issues
mac-screen-fix 23
mac-all-screen-fix
```

### Notifications & Alerts

```fish
# Send a silent desktop notification
mac-notify 23 "Please save your work"
mac-all-notify "Lab closing in 10 minutes"

# Send notification WITH sound
mac-alert 23 "Submit your work now"
mac-all-alert "Time is up!"
```

### Network & Wake-on-LAN

```fish
# Scrape IP and MAC addresses from all machines
mac-scrape-inventory

# Wake a sleeping/off machine
mac-wake 23
mac-all-wake

# Enable Wake-on-LAN on machines
mac-wol-setup 23
mac-all-wol-setup
```

### Emergency

```fish
# Kill all hanging SSH/brew processes
mac-kill-all
```

---

## 🏗️ Architecture

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
│       ├── screens.fish             # Screen monitoring & presentation mode
│       ├── notify.fish              # Desktop notifications & audio alerts
│       ├── network.fish             # IP/MAC scraping, Wake-on-LAN
│       ├── admin.fish               # Passwordless sudo setup
│       └── emergency.fish           # Kill hanging processes
├── docs/                            # Documentation
├── assets/                          # Assets
└── README.md
```

### Design Principles

1. **Single → All Pattern**: Every command works on one machine first, then has an `all` variant for lab-wide execution
2. **Parallel Execution**: All lab-wide commands run in parallel using background processes (`&`) and `wait`
3. **No Agents**: Uses only SSH — nothing to install on client machines
4. **No Cloud**: Runs entirely on your local network using mDNS (`.local`)
5. **Safe Passwords**: Passwords are base64-encoded for safe transport over SSH
6. **Validation First**: Dangerous operations (like sudoers changes) use validation before applying

---

## 🌐 Companion Tools

labctl is the CLI engine. For a full GUI experience, check out:

- **[Mac Lab Dashboard](https://github.com/iampownkumar/mac-os-monitering)** — Flutter desktop app + FastAPI backend that provides a visual dashboard for all labctl operations

---

## 📄 License

Copyright © 2026 **Pownkumar A** (Founder of Korelium)

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

You are free to:
- ✅ Use this software for personal and educational purposes
- ✅ Modify and distribute under the same license
- ✅ Use in your institution's Mac lab

You must:
- 📋 Include the original copyright notice
- 📋 Disclose your source code if you modify and distribute
- 📋 License derivatives under AGPL-3.0

You may NOT:
- ❌ Use this in a commercial product without permission
- ❌ Remove the copyright or attribution
- ❌ Offer this as a paid service without contacting the author

For commercial licensing inquiries, contact: **Pownkumar A** at [Korelium](https://korelium.org)

---

<div align="center">

**Built with ❤️ for Mac Lab Admins everywhere**

*If labctl saves you time, give it a ⭐ on GitHub!*

</div>

]]>
