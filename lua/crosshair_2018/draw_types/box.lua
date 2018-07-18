local base = CROSS2018.DrawType.Base

local box = {
	width = 5,
	height = 5,
	angle = 0,
}

--[[
	Size
]]--
-- Width
box.setWidth = function(self, width)
	self.width = width
end
box.getWidth = function(self)
	return self.width
end
-- Height
box.setHeight = function(self, height)
	self.height = height
end
box.getHeight = function(self)
	return self.height
end

--[[
	Angle
]]--
box.setAngle = function(self, height)
	self.angle = angle
end
box.getAngle = function(self)
	return self.angle
end

box.draw = function(self)
	surface.SetDrawColor( color_green )
	surface.DrawTexturedRectRotated( self:getX(), self:getY(), self:getWidth(), self:getHeight(), self:getAngle() )
end

setmetatable( base, { __index=box } )

CROSS2018.DrawType.Box = box

