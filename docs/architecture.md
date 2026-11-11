# Architecture & Design

Shards (Stowaway) is engineered as a hybrid C++20 and Declarative QML system, separating low-level Wayland protocol handling, process IPC, and clipboard watchers from the hardware-accelerated presentation layer.

---

## System Architecture

The runtime architecture is decoupled into three primary tiers:

```
┌────────────────────────────────────────────────────────┐
│                   Compositor & User                    │
│            (Hyprland / Sway / Wayland Clients)         │
└───────────────────────────┬────────────────────────────┘
                            │ Hotkey / CLI Invocation
                            ▼
┌────────────────────────────────────────────────────────┐
│                   stowaway Launcher                    │
│ ┌──────────────────────┐      ┌──────────────────────┐ │
│ │  sendSocketCommand   │◄────►│  /tmp/stowaway.sock  │ │
│ └──────────────────────┘      └──────────────────────┘ │
└───────────────────────────┬────────────────────────────┘
                            │ UNIX Domain Socket ("tab:0")
                            ▼
┌────────────────────────────────────────────────────────┐
│               Stowaway Resident Daemon                 │
│                                                        │
│  ┌─────────────────────────┐ ┌───────────────────────┐ │
│  │     C++ Core Plugin     │ │  Quickshell Host      │ │
│  │ • AppController         │ │ • shell.qml           │ │
│  │ • ClipboardManager      │ │ • wlr-layer-shell     │ │
│  │ • EmojiService          │ │ • Spring animations   │ │
│  │ • PositionController    │ │ • Material 3 tokens   │ │
│  │ • PasteManager          │ │                       │ │
│  └────────────┬────────────┘ └───────────┬───────────┘ │
└───────────────┼──────────────────────────┼─────────────┘
                │                          │
        wl-paste / cliphist         wtype auto-paste
                │                          │
                ▼                          ▼
┌────────────────────────────────────────────────────────┐
│                    Host Desktop                        │
│            (Active Application Window)                 │
└────────────────────────────────────────────────────────┘
```

---

## Why "Shards" & "Stowaway"? (The Lore)

> **ice shards** (`/ʃɑːdz/`) — *noun:* Sharp, freestanding slivers of splintered sea ice sheared from pressure ridges, compact enough to pocket, carry, and examine up close.

When sea ice fractures under pressure, it leaves behind small, brilliant shards—bite-sized fragments of the larger pack ice that can be easily transported and inspected.

**Stowaway carries bite-sized clipboard fragments:**
- **Pocketed Shards**: Captures recent text snippets, image thumbnails, color hex codes, and unicode symbols into an overlay that remains concealed until summoned.
- **Frictionless Handoff**: Hands content back to the active application with zero latency, releasing all GPU resources when dismiss animations conclude.

---

## Wayland Layer Shell & IPC

Stowaway runs as a Wayland Layer Surface using `wlr-layer-shell-unstable-v1` via Quickshell:

- **Layer**: `Layer.Overlay` ensures the picker displays above standard floating and tiled application windows.
- **Keyboard Interception**: `KeyboardFocusMode.Exclusive` grants full keyboard access to the search bar and arrow navigation without passing keys through to underlying applications.
- **Position Anchoring**: The `PositionController` queries Hyprland IPC (`$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`) to determine the exact coordinates of the mouse cursor and active monitor bounding box.
- **Edge Flipping**: If the overlay would extend past the right or bottom boundary of the monitor, anchor dimensions flip to prevent clipping offscreen.

---

## Sub-10ms Daemon Lifecycle

Cold-starting a graphical application on Wayland typically incurs significant overhead:
1. Dynamic linker symbol resolution (`ld.so`)
2. Initializing Qt6 Core, Gui, and Quick engines
3. Parsing QML component trees and loading shaders
4. Reading and deserializing JSON emoji datasets (>3,000 items)

### Daemon Optimization Pipeline

When running in daemon mode:
- The QML engine and dataset tables remain pre-parsed in resident RAM (~35MB RSS).
- The Wayland layer surface is kept unmapped (`visible = false`), resulting in 0% CPU and 0% GPU load during idle periods.
- Upon receiving a trigger signal on `$XDG_RUNTIME_DIR/stowaway.sock`:
  1. The daemon reads the target window address via Hyprland IPC.
  2. The window layer is mapped immediately (< 10ms).
  3. Spring animations smoothly scale the canvas from 92% to 100%.

---

## Auto-Paste Mechanics

Injecting text into an external application under Wayland requires strict focus sequencing. Because Wayland compositors enforce security boundaries, synthetic keystrokes sent via `wtype` will be dropped if the source overlay retains focus.

Stowaway implements a two-stage dismissal and injection pipeline:

$$\text{Dismissal Pipeline}: \quad \text{Select Item} \longrightarrow \text{Copy to Wayland Clipboard} \longrightarrow \text{Close Overlay} \longrightarrow \text{Refocus Target Window} \longrightarrow \text{Dispatch } \texttt{Ctrl+V}$$

```
Overlay Open (Has Focus)
       │
       ▼ [User presses Enter / clicks item]
1. Write to wl-clipboard (text or image)
2. Begin exit animation (spring shrink & fade)
3. Unmap Wayland layer surface
       │
       ▼ [Layer completely unmapped]
4. Focus target window address via Hyprland IPC
5. Execute wtype -M ctrl -k v -m ctrl
```

This guarantees that the target application (terminal, browser, editor) receives the paste event reliably without losing keyboard focus.
