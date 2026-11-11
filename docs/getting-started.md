# Getting Started

This guide explains how to build, install, and configure Stowaway (Shards) within a Wayland desktop environment.

---

## Installation

### Prerequisites

#### Build Dependencies
- C++20 compiler (`gcc` 11+ or `clang` 14+)
- `cmake` (>= 3.19)
- `ninja`
- `pkg-config`
- `qt6-base`, `qt6-declarative`, `qt6-svg` (>= 6.5)

#### Runtime Dependencies
- `quickshell` (Wayland layer-shell presentation host)
- `wtype` (synthetic keystroke injection for auto-paste)
- `wl-clipboard` / `cliphist` (clipboard synchronization backend)

#### Optional Integration
- `caelestia-cli` (dynamic color scheme and token synchronization)
- `hyprland` (cursor tracking and window refocusing IPC)

---

### Arch Linux / AUR

Install using your preferred AUR helper:

```bash
# Stable release (builds from source)
paru -S astra-stowaway

# Development trunk
paru -S astra-stowaway-git
```

---

### Manual Compilation from Source

```bash
git clone https://github.com/SpanishSyntax/Shards.git
cd Shards

# Configure and compile using CMake & Ninja
cmake -B build -S . -GNinja -DCMAKE_BUILD_TYPE=Release
cmake --build build

# Install binary and system assets
sudo cmake --install build
```

This installs:
- Binary: `/usr/bin/stowaway`
- QML Sources: `/etc/xdg/quickshell/astra-stowaway/`
- Desktop Entry: `/usr/share/applications/stowaway.desktop`
- Systemd Service: `/usr/share/systemd/user/stowaway.service`

---

## Quick Start

### Basic Invocation

Summon the clipboard manager at the cursor position:

```bash
stowaway --toggle
```

Directly open specialized character pickers:

```bash
# Open Emoji picker
stowaway --emoji

# Open Kaomoji text faces
stowaway --kaomoji

# Open Unicode mathematical & typographical symbols
stowaway --symbols
```

Close the active overlay without selecting an item:

```bash
stowaway --hide
```

---

## Daemon Configuration

Stowaway features a background daemon mode. Rather than cold-booting Quickshell on every invocation (which takes ~150–250ms), the daemon keeps the Qt runtime, QML engine, and parsed JSON datasets warm in memory with the Wayland surface unmapped. Invoking `stowaway` then triggers the overlay via UNIX domain socket in **< 10ms**.

### Enabling Daemon Mode

Configure Stowaway to launch in daemon mode:

```bash
stowaway --enable-daemon
```

Alternatively, set `"daemon": true` in `~/.config/caelestia/stowaway.json` or `~/.config/stowaway/config.json`:

```json
{
  "daemon": true
}
```

### Managing the Running Daemon

```bash
# Start background daemon manually
stowaway --daemon

# Check whether daemon is currently running
stowaway --status

# Terminate running daemon process
stowaway --quit
```

### Disabling Daemon Mode

If you prefer one-shot execution:

```bash
# Disable daemon in config and stop any running instance
stowaway --disable-daemon

# Run an individual one-shot instance ignoring daemon state
stowaway --no-daemon
```

---

## Systemd User Service

Stowaway includes a systemd user unit to start the daemon alongside your Wayland graphical session:

```bash
systemctl --user daemon-reload
systemctl --user enable --now stowaway.service
```

To inspect status and logs:

```bash
systemctl --user status stowaway
journalctl --user-unit stowaway -f
```
