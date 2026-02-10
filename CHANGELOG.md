# Changelog

## [Unreleased]

### Added

- trapt.yazi plugin: constrain Yazi navigation to a root directory boundary
- Root boundary enforcement: block `h`/`<Left>` at root with notification
- Auto-hide parent pane via runtime `Tab.layout` override (restores on toggle off)
- Status bar indicator in header line (works alongside yatline)
- Bookmark constraining via `ps.sub("cd")` — bounces back when navigating outside root
- Toggle on/off with notification and layout redraw
- Configurable options: `hide_parent`, `constrain_bookmarks`, `show_indicator`, `notify`
- Custom root via `$YAZI_ROOT` env var, falls back to `$PWD` then `$HOME`

### Fixed

- Path traversal bypass via `..` segments — added `normalize_path()` resolution
- Nil guard for `state.root` when all env vars are unset
- Double-setup guard to prevent `Tab.layout` self-referential loop
- Defensive `job.args` nil check in entry point
- Cached `_root_prefix` string to avoid allocation on every boundary check
