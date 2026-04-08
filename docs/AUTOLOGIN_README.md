# macOS Auto-Login Troubleshooting & Implementation

## The Goal
The objective was to remotely enable the automatic login feature on 100+ macOS machines inside a computer lab using our headless SSH infrastructure (`labctl`).

## The Problem
When using the modern documented approach for macOS Ventura and Sonoma via the `sysadminctl` tool, we repeatedly encountered `Error 22` when attempting to set the login password over SSH:

```bash
sudo sysadminctl -adminUser admin -adminPassword pass -autologin set -userName target_user -password target_pass
2026-04-08 12:28:23.483 sysadminctl[446:4856] SACSetAutoLoginPassword error:22
```

### Why does this happen?
`Error 22` is a standard `EINVAL` (Invalid Argument) system error. However, in this specific context within the Apple `sysadminctl` service interacting with `loginwindow`, it signifies a deeper security context issue:
1. **Headless SSH Context:** `sysadminctl` expects to be run in an environment that has active connection to the GUI window server and proper security context wrappers. An SSH session lacks the appropriate entitlements that a standard terminal application (running within the Desktop) would possess.
2. **Secure Token Dependency:** Starting in macOS Monterey (and enforced stricter later), password changes related to auto-authentication expect robust Secure Token health.
3. **Private APIs:** `SACSetAutoLoginPassword` is an internal private API that blocks programmatic calls un-blessed by an MDM (Mobile Device Management) or non-interactive daemon execution.

## The Workaround (Legacy `/etc/kcpassword`)
Because `sysadminctl` simply refuses to mutate the auto-login password over an interactive pseudo-terminal via SSH, we implemented the legacy standard that Apple used internally for 20 years. 

This approach completely bypasses `sysadminctl`:

1. **The XOR Cipher:** macOS stores the auto-login password in a hidden, root-owned file at `/etc/kcpassword`. This file is not plain-text but is obfuscated using exactly 11 bytes of a static XOR key (`0x7D, 0x89, 0x52, 0x23, 0xD2, 0xBC, 0xDD, 0xEA, 0xA3, 0xB9, 0x1F`).
2. **The Perl Script:** Our automated script encodes the provided plaintext password using this algorithm on-the-fly and writes it directly to `/etc/kcpassword`.
3. **The Plist:** We use the native `defaults` command to tell `loginwindow` which user to automatically map that password to:
   ```bash
   sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "username"
   ```

### Advantages
- Completely immune to `Error 22`.
- Executes invisibly and instantaneously in parallel across all lab systems.
- Easy to revert: disabling simply means deleting `/etc/kcpassword`.

### Prerequisites
- **FileVault MUST BE OFF.** The entire concept of auto-login completely conflicts with Full Disk Encryption because the hard drive cannot decrypt itself without an interactive password prompt upon a cold boot.
