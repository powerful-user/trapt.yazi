# Changelog

## [Unreleased]

### Added

- Root boundary enforcement: block `h`/`<Left>` at root with notification
- Auto-hide parent pane via runtime `Tab.layout` override (restores on toggle off)
- Status bar indicator in header line (works alongside yatline)
- Bookmark constraining via `ps.sub("cd")` — bounces back when navigating outside root
- Toggle on/off with notification and layout redraw
- Configurable options: `hide_parent`, `constrain_bookmarks`, `show_indicator`, `notify`
- Custom root via `$YAZI_ROOT` env var, falls back to `$PWD` then `$HOME`
- Path normalization to prevent `..` traversal bypasses
