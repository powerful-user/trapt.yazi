# AGENTS.md

## Project Overview

**trapt.yazi** is a Yazi file manager plugin that constrains navigation to a root directory boundary. It's published as a standalone GitHub repo for installation via `ya pkg add powerful-user/trapt`.

## Repository Structure

```
trapt.yazi/main.lua   # The entire plugin (single file, ~190 lines of Lua)
README.md             # User-facing docs: install, setup, config, migration
CHANGELOG.md          # Keep Updated format
LICENSE               # MIT, Josh Osborne
designs/              # Design docs and API research (not shipped to users)
```

## How Yazi Plugins Work

- Plugins live in a `<name>.yazi/` directory containing `main.lua`
- `setup(state, opts)` runs once at init time (from user's `~/.config/yazi/init.lua`)
- `entry(self, job)` runs each time the plugin is invoked via keymap
- `--- @sync entry` annotation means `entry()` runs in sync context with access to `cx` (Yazi context)
- `os.getenv()` works in `setup()` (init time) but NOT in sync context
- Use `ya.emit()` (not the deprecated `ya.mgr_emit()`) for commands
- Minimum Yazi version: v25.5.28

## Key Architecture Decisions

- **Module-level `state` variable**: `setup()` assigns the Yazi-provided state table to a module-level `local state = {}`. This allows helper functions and callbacks (Header children, ps.sub) to access plugin state without passing it around.
- **Root captured in setup()**: `os.getenv("YAZI_ROOT") or os.getenv("PWD") or os.getenv("HOME") or "/"` — must happen at init time since env vars aren't available in sync context.
- **`ya.emit` over `ya.mgr_emit`**: The `mgr_emit` variant is deprecated since v25.5.28. Using `ya.emit("leave", {})` avoids infinite recursion when `leave` is rebound in keymap.
- **Tab.layout override for hide_parent**: Dynamically hides the parent pane by overriding `Tab.layout` (same pattern as `toggle-pane.yazi`). Original layout is saved and restored on toggle off.
- **Header:children_add for status indicator**: Works alongside yatline as long as trapt is loaded AFTER yatline in `init.lua`.
- **ps.sub("cd") for bookmark constraining**: Reactive approach — can't prevent a cd, only detect and bounce back. Fires after navigation completes.
- **normalize_path()**: Resolves `.` and `..` segments to prevent path traversal bypasses in boundary checks.

## Local Development

The plugin is symlinked into the user's Yazi config for live testing:

```
~/.config/yazi/plugins/trapt.yazi -> ~/Claude/repos/trapt/trapt.yazi
```

To test changes, just edit `trapt.yazi/main.lua` and restart Yazi. No build step.

The user's Yazi config files that reference trapt:
- `~/.config/yazi/init.lua` — `require("trapt"):setup({...})`
- `~/.config/yazi/keymap.toml` — keybindings for `plugin trapt` and `plugin trapt toggle`
- `~/.config/yazi/yazi.toml` — `ratio = [1, 4, 3]` (trapt overrides this at runtime when enabled)

## Testing

No automated tests — this is a Yazi plugin tested manually:
1. Open Yazi in a subdirectory
2. Press `h` repeatedly — should stop at root with notification
3. Press `g b` to toggle off — `h` should navigate freely
4. Press `g b` again — boundary re-enabled, parent pane hides again
5. If `constrain_bookmarks = true`: use bunny (`;`) to jump outside root — should bounce back

## Publishing

```bash
# Users install with:
ya pkg add powerful-user/trapt
```

The package manager clones the repo and symlinks the `.yazi` directory into `~/.config/yazi/plugins/`.
