TIL = {}
TIL.__index = TIL

-- Makes a simple 8x8 image that is upscaled x2 for better viewing
function TIL:make_iup_img(tiln, pal)
	return iup.image{
		width=16,
		height=16,
		pixels=upscale_img(self.chr_handler:get_iup_img_from_pages(tiln, cur_tsa), 8, 8, 2),
		colors=ram_pal:get_attribute_palette(pal)
	}
end

-- Create the gui elements for the tile handler
function TIL:initilize_tiles()
	local tiles, hboxes = {}, {}
	local vbox
	for i=1, 16 do
		local tilez = {}
		for j=1, 16 do
			tile = self:make_iup_img((j - 1) + (i - 1) * 0x10, 1)
			tile = iup.label{
				image=tile
			}
			tilez[j] = tile
			table.insert(tiles, tile)
		end
		local hbox = iup.hbox(tilez)
		hbox["margin"] = "0x0"
		table.insert(hboxes, hbox)
	end
	vbox = iup.vbox(hboxes)
	return tiles, hboxes, vbox
end

-- Relaod a tile and update it
function TIL:set_tile(tiln)
	self.tiles[tiln]["image"] = self:make_iup_img(tiln - 1, 1)
	iup.Update(self.tiles[tiln])
end

-- Reloads every tile and updates it
function TIL:reload()
	for i=1, 256 do
		self:set_tile(i)
	end
end

-- Creates the tsa and sets it up for use
function TIL:create(chr_handler)
	local til = {}
  	setmetatable(til, TIL)
  	self.chr_handler = chr_handler
  	self.tiles, self.hboxes, self.vbox = self:initilize_tiles()
  	return til
end