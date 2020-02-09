CrosshairDesigner.CreateFonts = function(fontSize)

	surface.CreateFont( "CrosshairDesignerMenu", {
		font = "Arial",
		extended = false,
		size = fontSize,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

	surface.CreateFont( "CrosshairDesignerMenuTitle", {
		font = "Arial",
		extended = false,
		size = fontTitleSize,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = true,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )

end