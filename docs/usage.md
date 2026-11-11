# Integration & Usage Guide

This guide covers integrating Stowaway (Shards) with Wayland compositors, tuning animation rules, managing dynamic sizing, and synchronizing color palettes.

---

## Compositor Keybindings

### Hyprland Configuration (`~/.config/hypr/hyprland.conf`)

Bind global shortcuts to invoke Stowaway overlays:

```ini
# Toggle clipboard overlay anchored to cursor
bind = SUPER, V, exec, stowaway --toggle

# Open Emoji picker directly
bind = SUPER, PERIOD, exec, stowaway --emoji

# Open Unicode mathematical & typographical symbols
bind = SUPER SHIFT, S, exec, stowaway --symbols

# Open Kaomoji picker
bind = SUPER SHIFT, K, exec, stowaway --kaomoji
```

### Sway Configuration (`~/.config/sway/config`)

```ini
# Toggle clipboard overlay
bindsym $mod+v exec stowaway --toggle

# Open Emoji picker
bindsym $mod+period exec stowaway --emoji
```

---

## Hyprland Animation Rules

Stowaway provides custom QML spring physics animations (`Anim.qml` / `CAnim.qml`). If Hyprland applies default window animations simultaneously, the window geometry can jitter or conflict during map and unmap transitions.

To disable external compositor animations and allow Stowaway's internal physics to render exclusively, add this layer rule to your Hyprland configuration:

```ini
# ~/.config/hypr/hyprland.conf
layerrule = noanim, namespace:stowaway
```

Or within dynamic Lua configurations (`~/.config/caelestia/hypr-user.lua`):

```lua
hl.layer_rule({
    match = {
        namespace = "stowaway",
    },
    no_anim = true,
})
```

---

## Dynamic Sizing & Scaling

Stowaway allows live dynamic adjustment of both popup window boundaries and UI typography/icon scaling.

### Live Hotkeys Inside the Overlay

When the overlay is focused:
- `Ctrl` + `+` (or `Ctrl` + `=`): Increments dimensions by 20px and enlarges scale by 5%.
- `Ctrl` + `-`: Decrements dimensions by 20px and shrinks scale by 5%.
- `Ctrl` + `0`: Restores default dimensions (`390x500`) and scale (`1.0x`).

All adjustments are debounced and saved automatically to your configuration file.

### CLI Geometry Overrides

You can launch customized instances for specific monitors or setups:

```bash
# Set specific width and height
stowaway --width 480 --height 650

# Set dimensions simultaneously
stowaway --size 480x650

# Enforce a 1.25x scaling factor for 4K displays
stowaway --scale 1.25

# Reset dimensions and scaling
stowaway --reset-size
```

---

## Theme & Token Integration

Stowaway dynamically consumes Material 3 design tokens. If present, it binds to Caelestia shell color tokens located at `~/.config/caelestia/shell-tokens.json`:

```json
{
  "scale": 1.15,
  "sizes": {
    "stowaway": {
      "width": 420,
      "height": 560
    }
  },
  "colors": {
    "surface": "#0F172A",
    "surfaceContainer": "#1E293B",
    "primary": "#38BDF8",
    "onSurface": "#F8FAFC",
    "outline": "#334155"
  }
}
```

When no external token server is detected, Stowaway falls back to its default dark palette (`#0F172A` background, `#38BDF8` cyan accents, `#F8FAFC` high-contrast typography).
