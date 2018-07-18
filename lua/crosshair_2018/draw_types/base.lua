-- Default values
local base = {
	x = 1,
	y = 1,

	color = Color(0, 0, 0, 255),
}

--[[
	Position
]]--
-- X
base.setX = function(self, x)
	self.x = x
end
base.getX = function(self)
	return self.x
end
-- Y
base.setY = function(self, y)
	self.y = y
end
base.getY = function(self)
	return self.y
end

--[[
	Colour
]]--
base.setColor = function(self, color)
	self.color = color
end
base.getColor = function(self)
	return self.color
end

CROSS2018.DrawType.Base = base
