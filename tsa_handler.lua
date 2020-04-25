TSA = {}
TSA.__index = TSA

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

function TSA:load_tilesets()
	local tilesets = {}
	for i in pairs(tile_layout_locations) do
		tilesets[i] = self:read_tsa(i)
	end
	return tilesets
end

function TSA:load_tsa_img(tiln)
	return iup.image{
		width=16,
		height=16,
		pixels=merge_tiles(
			make_img(chr_tsa_offset(self.tileset[cur_tsa][tiln][1], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
			make_img(chr_tsa_offset(self.tileset[cur_tsa][tiln][2], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
			make_img(chr_tsa_offset(self.tileset[cur_tsa][tiln][3], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
			make_img(chr_tsa_offset(self.tileset[cur_tsa][tiln][4], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
			8
		),
		colors=cur_pals[math.floor(tiln / 4) + 1]
	}
end

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

function TSA:create()
	local tsa = {}
  	setmetatable(tsa, TSA)
  	self.tileset = self:load_tilesets()
  	self.tiles, self.hboxes, self.vbox = self:initilize_gui()
  	return tsa
end

function TSA:set_tile(tiln)
	self.tiles[tiln]["image"] = self:load_tsa_img(tiln)
	iup.Update(self.tiles[tiln])
end

function TSA:reload()
	for i=1, 256 do
		self:set_tile(i)
	end
end