--- @sync entry
--- @since 25.5.28
--- trapt.yazi — Constrain Yazi navigation to a root directory boundary.

local state = {}

--- Normalize a path by resolving . and .. segments.
local function normalize_path(path)
	local parts = {}
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			if #parts > 0 then
				table.remove(parts)
			end
		elseif part ~= "." then
			parts[#parts + 1] = part
		end
	end
	return "/" .. table.concat(parts, "/")
end

local function is_at_root()
	local cwd = tostring(cx.active.current.cwd)
	return cwd == state.root
end

local function is_within_root(path)
	if path == state.root then
		return true
	end
	if state.root == "/" then
		return true
	end
	return path:sub(1, #state._root_prefix) == state._root_prefix
end

local function setup(st, opts)
	opts = opts or {}

	-- Guard against double-setup (prevents Tab.layout self-referential loop)
	if st._initialized then
		return
	end
	st._initialized = true

	-- Capture state reference for use in callbacks
	state = st

	-- Root resolution: YAZI_ROOT > PWD > HOME > "/"
	state.root = os.getenv("YAZI_ROOT") or os.getenv("PWD") or os.getenv("HOME") or "/"

	-- Capture HOME for use in sync context (os.getenv doesn't work there)
	state.home = os.getenv("HOME") or ""

	-- Normalize: strip trailing slash (unless root is "/")
	if state.root ~= "/" and state.root:sub(-1) == "/" then
		state.root = state.root:sub(1, -2)
	end

	-- Cache prefix for is_within_root checks
	state._root_prefix = state.root .. "/"

	-- Configuration
	state.enabled = true
	state.hide_parent = opts.hide_parent ~= false -- default: true
	state.constrain_bookmarks = opts.constrain_bookmarks or false -- default: false
	state.show_indicator = opts.show_indicator ~= false -- default: true
	state.notify_enabled = opts.notify ~= false -- default: true

	-- Auto-hide parent pane by overriding Tab.layout
	if state.hide_parent then
		state._original_tab_layout = Tab.layout
		Tab.layout = function(self)
			if state.enabled then
				self._chunks = ui.Layout()
					:direction(ui.Layout.HORIZONTAL)
					:constraints({
						ui.Constraint.Ratio(0, 7),
						ui.Constraint.Ratio(1, 7),
						ui.Constraint.Ratio(6, 7),
					})
					:split(self._area)
			else
				state._original_tab_layout(self)
			end
		end
	end

	-- Status bar indicator (works alongside yatline when loaded after it)
	if state.show_indicator then
		Header:children_add(function()
			local readable_root = ya.readable_path(state.root)
			if state.enabled then
				return ui.Line(ui.Span(" [trapt: " .. readable_root .. "] "):fg("blue"))
			else
				return ui.Line(ui.Span(" [trapt: off] "):fg("darkgray"))
			end
		end, 500, Header.RIGHT)
	end

	-- Bookmark constraining via cd event subscription
	if state.constrain_bookmarks then
		ps.sub("cd", function(body)
			if not body or not state.enabled then
				return
			end
			local cwd = tostring(cx.active.current.cwd)
			if not is_within_root(cwd) then
				ya.emit("cd", { state.root })
				if state.notify_enabled then
					ya.notify({
						title = "trapt",
						content = "Bookmark outside root — bounced back",
						timeout = 2,
						level = "warn",
					})
				end
			end
		end)
	end
end

local function leave()
	if not state.enabled then
		ya.emit("leave", {})
		return
	end

	if is_at_root() then
		if state.notify_enabled then
			ya.notify({
				title = "trapt",
				content = "At root: " .. ya.readable_path(state.root),
				timeout = 2,
			})
		end
	else
		ya.emit("leave", {})
	end
end

local function toggle()
	state.enabled = not state.enabled

	if state.notify_enabled then
		local status = state.enabled and "enabled" or "disabled"
		ya.notify({
			title = "trapt",
			content = "Boundary " .. status,
			timeout = 2,
		})
	end

	-- Force redraw to update layout when toggling with hide_parent
	if state.hide_parent then
		ya.emit("app:resize", {})
	end
end

local function cd(job)
	local target = job.args[2]
	if not target then
		return
	end

	if not state.enabled or not state.constrain_bookmarks then
		ya.emit("cd", { target })
		return
	end

	-- Expand ~ to home (using captured HOME from setup)
	local resolved = target
	if resolved:sub(1, 1) == "~" then
		resolved = state.home .. resolved:sub(2)
	end

	-- Resolve relative paths against cwd
	if resolved:sub(1, 1) ~= "/" then
		resolved = tostring(cx.active.current.cwd) .. "/" .. resolved
	end

	-- Normalize to resolve .. and . segments
	resolved = normalize_path(resolved)

	if is_within_root(resolved) then
		ya.emit("cd", { target })
	else
		if state.notify_enabled then
			ya.notify({
				title = "trapt",
				content = "Blocked: " .. target .. " is outside root",
				timeout = 2,
				level = "warn",
			})
		end
	end
end

local function entry(_, job)
	local args = job and job.args or {}
	local action = args[1]

	if action == "toggle" then
		toggle()
	elseif action == "cd" then
		cd(job)
	else
		leave()
	end
end

return { setup = setup, entry = entry }
