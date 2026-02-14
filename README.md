# trapt.yazi

Constrain [Yazi](https://yazi-rs.github.io/) file navigation to a root directory boundary.

When active, pressing `h`/`<Left>` to navigate upward is blocked at the root. The root is automatically captured from `$PWD` when Yazi launches, or can be overridden via `YAZI_ROOT`.

 <video autoplay nocontrols mute loop src="trapt.mp4" />
  
  
## Requirements

- [Yazi](https://yazi-rs.github.io/) v25.5.28+

## Installation

```bash
ya pkg add powerful-user/trapt
```

## Setup

Add to your `~/.config/yazi/init.lua`:

```lua
require("trapt"):setup({
  hide_parent = true,           -- hide parent pane at runtime (default: true)
  constrain_bookmarks = false,  -- block bookmarks outside root (default: false)
  show_indicator = true,        -- show root in header line (default: true)
  notify = true,                -- show boundary notifications (default: true)
})
```

> **Note:** If using [yatline](https://github.com/imsi32/yatline.yazi), load it **before** trapt in your `init.lua`.

Add to your `~/.config/yazi/keymap.toml`:

```toml
# Bounded navigation (required)
[[mgr.prepend_keymap]]
on = "h"
run = "plugin trapt"
desc = "Leave (bounded)"

[[mgr.prepend_keymap]]
on = "<Left>"
run = "plugin trapt"
desc = "Leave (bounded)"

# Toggle boundary on/off (optional)
[[mgr.prepend_keymap]]
on = ["g", "b"]
run = "plugin trapt toggle"
desc = "Toggle trapt boundary"
```

## Configuration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `hide_parent` | boolean | `true` | Hide the parent pane when boundary is active (restores on toggle off) |
| `constrain_bookmarks` | boolean | `false` | Block bookmark jumps (e.g., bunny) that navigate outside root |
| `show_indicator` | boolean | `true` | Show root path and active state in the header line |
| `notify` | boolean | `true` | Show notifications when hitting the boundary or toggling |

### Custom root directory

By default, trapt captures `$PWD` as the root when Yazi launches. To override:

```bash
# Set a specific root directory
YAZI_ROOT=/path/to/project yazi

# Shell alias for convenience
alias yp='YAZI_ROOT=$(pwd) yazi'
```

Root resolution order:
1. `$YAZI_ROOT` — explicit override
2. `$PWD` — launch directory
3. `$HOME` — fallback

## Features

### Root boundary enforcement

When you press `h` or `<Left>` at the root directory, navigation is blocked and a notification appears.

### Auto-hide parent pane

When `hide_parent = true` (default), the parent column is hidden since you can't navigate above root. The layout uses a `[0, 1, 6]` ratio, giving maximum space to the current directory and preview. Toggling trapt off restores the original layout.

### Toggle

Press `g` then `b` (or your configured keybinding) to toggle the boundary on/off. A notification confirms the state change. When toggled off with `hide_parent = true`, the parent pane is restored.

### Status indicator

When `show_indicator = true`, the header line shows:
- Active: `[trapt: ~/projects/myapp]`
- Inactive: `[trapt: off]`

Works alongside [yatline](https://github.com/imsi32/yatline.yazi).

### Bookmark constraining

When `constrain_bookmarks = true`, navigating outside the root via bookmarks (e.g., [bunny](https://github.com/sanjinso/bunny.yazi)) will bounce back to the root with a warning notification.

## Migration from bound-nav

If you're using a `bound-nav` plugin, here's how to migrate:

1. Remove the `BOUND_NAV_ROOT` line from `init.lua`
2. Remove `bound-nav.yazi` from your plugins directory
3. Add `require("trapt"):setup({})` to `init.lua`
4. Update `keymap.toml`: change `plugin bound-nav` to `plugin trapt`
5. Remove `ratio = [0, 1, 6]` from `yazi.toml` if you had it set manually (trapt handles this at runtime now)

## License

MIT
