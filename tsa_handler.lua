TSA = {}
TSA.__index = TSA

-- Reads tileset information from the rom
-- Todo: tile_layout_locations should be moved into the class
function TSA:read_tsa(idx)
	local loc = tile_layout_locations[idx]
	local tileset = {}
	for j=0, 255 do
		tileset[j + 1] = {
			rom.readbyte(loc + j),
			rom.readbyte(loc + j + 0x100),
			rom.readbyte(loc + j + 0x200),
			rom.readbyte(loc + j + 0x300)
		}
	end
	return tileset
end

-- Quick load for all the tilesets we have
function TSA:load_tilesets()
	local tilesets = {}
	for i in pairs(tile_layout_locations) do
		tilesets[i] = self:read_tsa(i)
	end
	return tilesets
end

-- Forms a 16x16 block from an idx
function TSA:load_tsa_img(tiln)
	return iup.image{
		width=16,
		height=16,
		pixels=merge_tiles(
			self.chr_handler:get_iup_img_from_pages(self.tileset[cur_tsa][tiln][1], cur_tsa),
			self.chr_handler:get_iup_img_from_pages(self.tileset[cur_tsa][tiln][2], cur_tsa),
			self.chr_handler:get_iup_img_from_pages(self.tileset[cur_tsa][tiln][3], cur_tsa),
			self.chr_handler:get_iup_img_from_pages(self.tileset[cur_tsa][tiln][4], cur_tsa),
			8
		),
		colors=ram_pal:get_attribute_palette(math.floor(tiln / 0x40) + 1)
	}
end

-- Loads the tsa for the first time
-- Todo: Should use the TSA:reload() instead of the code here for readability
function TSA:initilize_gui()
	local tiles, hboxes = {}, {}
	local vbox
	for i=0, 15 do
		local hbox = {}
		for j=1, 16 do
			local tile = iup.label{image=self:load_tsa_img(j + i * 16)}
			table.insert(tiles, tile)
			hbox[j] = tile
		end
		hbox["margin"] = "0x0"
		hboxes[i + 1] = iup.hbox(hbox)
	end
	vbox = iup.vbox(hboxes)
	return tiles, hboxes, vbox
end

-- Creates the tsa and sets it up for use
function TSA:create(chr_handler)
	local tsa = {}
	setmetatable(tsa, TSA)
  	self.chr_handler = chr_handler
  	self.tileset = self:load_tilesets()
  	self.tiles, self.hboxes, self.vbox = self:initilize_gui()
  	return tsa
end

-- Reloads a tile in the TSA
function TSA:set_tile(tiln)
	self.tiles[tiln]["image"] = self:load_tsa_img(tiln)
	iup.Update(self.tiles[tiln])
end

-- Reloads the entire TSA
function TSA:reload()
	for i=1, 256 do
		self:set_tile(i)
	end
end