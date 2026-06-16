# labctl

A Fish shell CLI to manage a Mac lab over SSH — no MDM, no cloud, no agents.

## Why I built this

I work in a college Mac lab. Multi-system, multi-user, full chaos.

Every time there was a new exam session I had to create student accounts on every machine. Every time I needed to install software, I was going machine by machine. Remote login sessions needed to be cleared, users needed to be deleted, machines needed to be rebooted — all manual. All one at a time. 33 Macs.

I'm a laser-focused problem solver. When something is wasting my time and a computer could just do it, I can't let it go. So I started writing this — one command at a time, solving the exact thing that annoyed me that day.

The design is simple: you change the username and the hostname pattern, and everything else just works. You can block internet, send desktop notifications, reboot everything, turn machines off, create users, delete users — all from your own terminal without touching a single machine physically.

If you're managing a Mac lab, this will genuinely make your life easier. That's not marketing — that's just what it does for me every day.

---

## What it does

Every command works on a single machine first, and has an `-all` version that runs across every machine at the same time.

| What | Single machine | All machines |
|---|---|---|
| Power | `mac 23 reboot` | `mac-all reboot` |
| Status | `mac 23 status` | `mac-all status` |
| Create user | `mac-user-create 23 student pass` | `mac-all-user-create student pass` |
| Delete user | `mac-user-delete 23 student` | `mac-all-user-delete student` |
| Install app | `mac-pkg 23 cask firefox` | `mac-pkg-all cask firefox` |
| Auto-login on | `mac-autologin-on 23 pass` | `mac-all-autologin-on pass` |
| View screen | `mac-monitor 23` | — |
| Present screen | `mac-present-host 23` | `mac-present` |
| Send notification | `mac-notify 23 "Save your work"` | `mac-all-notify "Lab closing soon"` |
| Wake machine | `mac-wake 23` | `mac-all-wake` |

---

## Requirements

- Your admin Mac where you run commands from
- All lab Macs on the same local network
- Fish Shell installed on the admin Mac
- SSH key access from admin Mac to all lab Macs
- All lab Macs must have the same admin username (e.g. `labuser`)

---

## Setup

### 1. Install Fish

```bash
brew install fish
```

### 2. Clone labctl

```bash
git clone https://github.com/korelium-oss/labctl.git
cd labctl
```

### 3. Set your lab config

Edit `fish/modules/config.fish`:

```fish
set -g LAB_USER "labuser"
set -g LAB_DOMAIN "local"
```

Edit `fish/modules/hostnames.fish`:

```fish
set -g MACHINES \
  mac-001 mac-002 mac-003 mac-004 mac-005
```

### 4. Load it in your Fish config

Add this to `~/.config/fish/config.fish`:

```fish
source /path/to/labctl/fish/init.fish
```

### 5. Set up SSH key auth

```fish
ssh-keygen -t ed25519
ssh-copy-id labuser@mac-001.local
# repeat for each machine
```

### 6. Set up passwordless sudo on lab Macs

```fish
mac-sudo-setup 1      # test on one first
mac-sudo-setup-all    # then all
```

### 7. Verify

```fish
mac-all status
```

You should see something like:

```
mac-001 : ONLINE  → up 2 days
mac-002 : ONLINE  → up 1 day
mac-003 : OFFLINE
------------------------------
ONLINE: 2 | OFFLINE: 1
```

---

## Project structure

```
labctl/
└── fish/
    ├── init.fish               # Loads everything
    └── modules/
        ├── config.fish         # Lab user and domain
        ├── hostnames.fish      # List of machine names
        ├── power-management.fish
        ├── users.fish
        ├── software.fish
        ├── brew-management.fish
        ├── autologin.fish
        ├── screens.fish
        ├── notify.fish
        ├── network.fish
        ├── admin.fish
        └── emergency.fish
```

---

## GUI version

If you prefer a point-and-click interface, check out [mac-lab-dashboard](https://github.com/korelium-oss/mac-lab-dashboard) — a Flutter desktop app that wraps labctl into a proper UI.

---

## License

MIT License. See [LICENSE](LICENSE) for details.
