-- Grab environment
local setmetatable = setmetatable
local math = math
local string = string

local beautiful = require("beautiful")
local wibox = require("wibox")

local modutil = require("flex.util")
local svgbox = require("flex.gauge.svgbox")

-- Initialize tables for module
local gicon = { mt = {} }

-- Generate default theme vars
local function default_style()
	local style = {
		icon = modutil.base.placeholder(),
		step = 0.05,
		is_vertical = false,
		color = { main = "#C38F8F", icon = "#a0a0a0", urgent = "#8DB8CD" },
	}
	return modutil.table.merge(style, modutil.table.check(beautiful, "gauge.icon.single") or {})
end

-- Support functions
local function pattern_string_v(height, value, c1, c2)
	return string.format("linear:0,%s:0,0:0,%s:%s,%s:%s,%s:1,%s", height, c1, value, c1, value, c2, c2)
end

local function pattern_string_h(width, value, c1, c2)
	return string.format("linear:0,0:%s,0:0,%s:%s,%s:%s,%s:1,%s", width, c1, value, c1, value, c2, c2)
end

-- Create a new gicon widget
-- @param style Table containing colors and geometry parameters for all elemets
function gicon.new(style)
	-- Initialize vars
	style = modutil.table.merge(default_style(), style or {})
	local pattern = style.is_vertical and pattern_string_v or pattern_string_h

	-- Create widget
	local widg = wibox.container.background(svgbox(style.icon))
	widg._data = {
		color = style.color.main,
		level = 0,
	}

	-- User functions
	function widg:set_value(x, force_redraw)
		if x > 1 then
			x = 1
		end

		if self.widget._image then
			local level = math.floor(x / style.step) * style.step

			if force_redraw or level ~= self._data.level then
				self._data.level = level
				local d = style.is_vertical and self.widget._image.height or self._image.width
				self.widget:set_color(pattern(d, level, self._data.color, style.color.icon))
			end
		end
	end

	function widg:set_alert(alert)
		local old_color = self._data.color
		self._data.color = alert and style.color.urgent or style.color.main
		if self._data.color ~= old_color then
			-- force redraw if color has changed
			self:set_value(self._data.level, true)
		end
	end

	return widg
end

-- Config metatable to call gicon module as function
function gicon.mt:__call(...)
	return gicon.new(...)
end

return setmetatable(gicon, gicon.mt)
