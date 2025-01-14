-- Grab environment
local unpack = unpack or table.unpack
local beautiful = require("beautiful")
local wibox = require("wibox")
local timer = require("gears.timer")

local modutil = require("flex.util")
local svgbox = require("flex.gauge.svgbox")
local progressbar = require("flex.gauge.graph.bar")

-- Initialize tables for module
local notify = { last = {} }

-- Generate default theme vars
local function default_style()
	local style = {
		geometry = { width = 480, height = 100 },
		screen_gap = 0,
		set_position = nil,
		border_margin = { 20, 20, 20, 20 },
		elements_margin = { 20, 0, 10, 10 },
		bar_width = 8,
		font = "Fira Code 14",
		border_width = 2,
		timeout = 5,
		icon = nil,
		progressbar = {},
		color = { border = "#575757", icon = "#aaaaaa", wibox = "#202020" },
		shape = nil,
	}
	return modutil.table.merge(style, modutil.table.check(beautiful, "float.notify") or {})
end

-- Initialize notify widget
function notify:init()
	local style = default_style()
	-- local icon = style.icon

	self.style = style

	-- Construct layouts
	local area = wibox.layout.align.horizontal()

	local bar = progressbar(style.progressbar)
	local image = svgbox()
	local text = wibox.widget.textbox("100%")
	text:set_align("center")
	-- text:set_font(style.font)

	local align_vertical = wibox.layout.align.vertical()
	bar:set_forced_height(style.bar_width)

	area:set_left(image)
	area:set_middle(wibox.container.margin(align_vertical, unpack(style.elements_margin)))

	-- Create floating wibox for notify widget
	self.wibox = wibox({
		ontop = true,
		bg = style.color.wibox,
		border_width = style.border_width,
		border_color = style.color.border,
		shape = style.shape,
	})

	self.wibox:set_widget(wibox.container.margin(area, unpack(style.border_margin)))
	self.wibox:geometry(style.geometry)

	-- Set info function
	function self:set(args)
		args = args or {}
		align_vertical:reset()

		if args.value then
			bar:set_value(args.value)
			align_vertical:set_top(text)
			align_vertical:set_bottom(bar)
		else
			align_vertical:set_middle(text)
		end

		if args.text then
			text:set_text(args.text)
			text:set_font(args.font ~= nil and args.font or style.font)
		end

		image:set_image(args.icon ~= nil and args.icon or style.icon)
		image:set_color(args.color or style.color.icon)
	end

	-- Set autohide timer
	self.hidetimer = timer({ timeout = style.timeout })
	self.hidetimer:connect_signal("timeout", function()
		self:hide()
	end)

	-- Signals setup
	self.wibox:connect_signal("mouse::enter", function()
		self:hide()
	end)
end

-- Hide notify widget
function notify:hide()
	self.wibox.visible = false
	self.hidetimer:stop()
end

-- Show notify widget
function notify:show(args)
	if not self.wibox then
		self:init()
	end
	self:set(args)
	args = args or {}
	local target_screen = args.screen or mouse.screen
	local set_position = args.set_position or self.style.set_position or nil

	if not self.wibox.visible or target_screen.index ~= self.last.screen then
		if set_position then
			set_position(self.wibox)
		end
		modutil.placement.no_offscreen(self.wibox, self.style.screen_gap, target_screen.workarea)
		self.wibox.visible = true
	end

	self.last.screen = target_screen.index
	self.hidetimer:again()
end

return notify
