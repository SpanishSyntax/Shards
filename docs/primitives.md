# Primitives Reference

This document provides a comprehensive reference for the command-line interfaces, configuration schemas, C++ core controllers, and QML presentation primitives in Shards.

---

## CLI Primitives & Triggers

The `stowaway` launcher binary accepts commands and options that control the active overlay or daemon process.

### Triggers & Modes

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--toggle` | `-t` | Opens or toggles the clipboard history tab beside cursor (default action). |
| `--emoji` | `-e` | Opens overlay directly to the Emoji picker tab. |
| `--kaomoji` | `-k` | Opens overlay directly to the Kaomoji picker tab. |
| `--symbols` | `-s` | Opens overlay directly to the Unicode Symbols picker tab. |
| `--hide` | `--close` | Dismisses any open overlay. |
| `--clear` | | Wipes unpinned clipboard history via `cliphist wipe`. |

### Daemon Management

| Flag | Short | Description |
| :--- | :--- | :--- |
| `--daemon` | `-d` | Starts the background daemon (preloads QML, begins listening on UNIX socket). |
| `--foreground` | `-f` | Runs the daemon in the foreground (used by systemd user units). |
| `--no-daemon` | | Executes a one-shot overlay instance without connecting to the daemon. |
| `--enable-daemon` | | Writes `"daemon": true` to user configuration. |
| `--disable-daemon` | | Writes `"daemon": false` to configuration and terminates active daemon. |
| `--status` | | Returns exit code 0 if daemon is running, 1 otherwise. |
| `--quit` | `--kill` | Sends shutdown signal to running daemon. |

### Appearance & Geometry

| Flag | Short | Argument | Description |
| :--- | :--- | :--- | :--- |
| `--width` | `-W` | `<pixels>` | Overrides overlay width in pixels (e.g. `480`). |
| `--height` | `-H` | `<pixels>` | Overrides overlay height in pixels (e.g. `620`). |
| `--size` | `-S` | `<WxH>` | Overrides both dimensions (e.g. `480x620`). |
| `--scale` | | `<factor>` | Sets UI scaling factor (e.g. `1.25` for HiDPI). |
| `--reset-size` | | | Resets window dimensions and scaling to default (`390x500`, `1.0x`). |

---

## Configuration Schema

Stowaway searches for user configuration at:
1. `~/.config/caelestia/stowaway.json`
2. `~/.config/stowaway/config.json`

### Schema Definition

```json
{
  "daemon": true,
  "width": 390,
  "height": 500,
  "scale": 1.0,
  "max_history": 250,
  "auto_paste": true,
  "paste_delay_ms": 60,
  "filter_order": ["all", "text", "code", "urls", "colors", "images"]
}
```

### Parameter Reference

| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `daemon` | `boolean` | `true` | When true, daemon stays resident in background. |
| `width` | `integer` | `390` | Default popup width in pixels (clamped between 320 and 1600). |
| `height` | `integer` | `500` | Default popup height in pixels (clamped between 350 and 1200). |
| `scale` | `float` | `1.0` | UI font and element scaling multiplier. |
| `max_history` | `integer` | `250` | Maximum number of unpinned entries to retain. |
| `auto_paste` | `boolean` | `true` | Whether to automatically dispatch `Ctrl+V` on selection. |
| `paste_delay_ms` | `integer` | `60` | Delay in milliseconds before dispatching `wtype` keystroke. |

---

## C++ Core Controllers

The C++ plugin exposes singletons and data models to the QML runtime:

### `AppController` (`stowaway::core::AppController`)

Singleton orchestrating application state, socket IPC, geometry, and paste handoff.

- Properties: `visible`, `activeTab`, `popupWidth`, `popupHeight`, `uiScale`, `toastMessage`, `toastVisible`, `isDaemon`.
- Invokable Methods:
  - `showOverlay(int tab = -1)`
  - `hideOverlay()`
  - `toggleOverlay(int tab = -1)`
  - `dismissAndPasteText(const QString& text, const QString& targetAddress)`
  - `dismissAndPasteImage(const QString& filePath, const QString& targetAddress)`
  - `resetPopupSize()`

### `ClipboardManager` (`stowaway::core::ClipboardManager`)

Interacts with Wayland clipboard watchers (`wl-paste`) and `cliphist`.

- Properties: `items`, `filteredItems`, `filterQuery`, `onlyPinned`, `itemCount`, `pinnedCount`, `imageCount`.
- Invokable Methods:
  - `selectItem(const QString& id, const QString& targetWindowAddress)`
  - `copyItem(const QString& id)`
  - `togglePin(const QString& id)`
  - `deleteItem(const QString& id)`
  - `clearHistory()`

### `EmojiService` (`stowaway::core::EmojiService`)

Manages Unicode characters, Kaomoji, and typographical symbols.

- Properties: `emojiCategories`, `kaomojiCategories`, `symbolCategories`, `recentList`, `favoritesList`.
- Invokable Methods:
  - `searchEmojis(query, category)`
  - `searchKaomoji(query, category)`
  - `searchSymbols(query, category)`
  - `toggleFavorite(character, name, type)`
  - `recordUsage(character, name, type)`

---

## QML Presentation Components

Located under `qml/components/`:

| Component | Responsibility |
| :--- | :--- |
| `Anim.qml` / `CAnim.qml` | Reusable spring and bezier transition animators. |
| `Badge.qml` | Small metadata pills for item counts and categorization chips. |
| `IconButton.qml` | Interactive icon button with ripple and hover state layers. |
| `MaterialIcon.qml` | Vector glyph renderer using bundled Google Material Symbols font. |
| `SearchBar.qml` | Text input field with clear action, leading icon, and keyboard focus routing. |
| `SegmentedTabBar.qml` | Top tab navigation bar with sliding animated indicator strip. |
| `StateLayer.qml` | Material 3 hover, focus, and pressed state opacity overlays. |
| `StyledRect.qml` | Rounded rectangle container with elevation, borders, and smooth clipping. |
| `StyledScrollBar.qml` | Non-intrusive scrollbar indicator. |
| `StyledText.qml` | Font-scaled typography component mapped to Caelestia shell tokens. |
| `VerticalFadeListView` | List container featuring top and bottom edge gradient fade masks. |

---

## Data Providers & Assets

Stowaway bundles offline dataset files and fonts under `assets/`:

- `assets/data/emojis.json`: Complete Unicode 15.0 emoji database with keywords and categories.
- `assets/data/kaomoji.json`: Curated collection of expressive ASCII / Unicode Japanese Kaomoji text faces.
- `assets/data/symbols.json`: Mathematical operators, arrows, fractions, Greek characters, and currency glyphs.
- `assets/fonts/MaterialSymbolsRounded.ttf`: Google Material Symbols rounded font.
- `assets/fonts/GoogleSansFlex.ttf`: Variable sans-serif typography font.
