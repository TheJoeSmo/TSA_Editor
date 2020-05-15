TSA = {}
TSA.__index = TSA

TSA.ids = {}

-- Reads tileset information from the rom
-- Todo: tile_layout_locations should be moved into the class
function TSA:read_tsa(idx)
	local loc = get_ts_info("absolute_address", idx)
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
	for i in pairs(tilesetz) do
		tilesets[i] = self:read_tsa(i)
	end
	return tilesets
end

function TSA:get_current_pal()
	return self.palette[cur_pal]
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
		colors=get_attribute_palette(self:get_current_pal(), math.floor((tiln - 1) / 0x40) + 1)
	}
end

-- Returns the current tile that should be displayed in the tsa
function TSA:get_tile(tiln, n)
	return self.tileset[cur_tsa][tiln][n]
end

-- Loads the tsa for the first time
-- Todo: Should use the TSA:reload() instead of the code here for readability
function TSA:initilize_gui()
	local tiles, hboxes = {}, {}
	local vbox
	for i=0, 15 do
		local hbox = {}
		for j=1, 16 do
			local til = self:load_tsa_img(j + i * 16)
			local tile = iup.button{
			image=til,
			impress=til,
			impressboarder="no",
			rastersize="16x16"
			}
			tile.action = "TSA.ids[".. self.id .."]:btn_act(".. j + i * 16 ..")"
			table.insert(tiles, tile)
			hbox[j] = tile
		end
		hbox["margin"] = "0x0"
		hboxes[i + 1] = iup.hbox(hbox)
	end
	vbox = iup.vbox(hboxes)
	return tiles, hboxes, vbox
end

function TSA:update_pal()
	return get_ts_info("palettes", cur_tsa)
end

-- Creates the tsa and sets it up for use
function TSA:create(chr_handler)
	local tsa = {}
	setmetatable(tsa, TSA)
	table.insert(TSA.ids, tsa)
  	self.id = tablelength(TSA.ids)

  	self.chr_handler = chr_handler
  	self.tileset = self:load_tilesets()
  	self.palette = self:update_pal()
  	self.tiles, self.hboxes, self.vbox = self:initilize_gui()
  	self.tcnt = nil
  	self.tactt_gui = nil
  	self.attr = nil
  	return tsa
end

-- Reloads a tile in the TSA
function TSA:reload_tile(tiln)
	self.tiles[tiln]["image"] = self:load_tsa_img(tiln)
	iup.Update(self.tiles[tiln])
end

-- Reloads the entire TSA
function TSA:reload()
	self.attr:set_idx(cur_tsa * 4 + math.floor(current_tile / 0x40))
	self.attr:update_gui()
	self.palette = self:update_pal()
	for i=1, 256 do
		self:reload_tile(i)
	end
end

function TSA:set_tile(tiln, n, new)
	self.tileset[cur_tsa][tiln][n] = new
	self:reload_tile(tiln)
end

function TSA:set_tcnt(tcnt)
	self.tcnt = tcnt
end

function TSA:set_current_tile_gui(tactt_gui)
	self.tactt_gui = tactt_gui
end

function TSA:set_tile_attr(attr)
	self.attr = attr
end

function TSA:btn_act(idx)
	self.tcnt:set_tsa_idx(idx)
	current_tile = idx
	self.tactt_gui.title = "tile: ".. dec_to_hex_byte(current_tile - 1)
	print(cur_tsa)
	self.attr:set_idx(math.max(cur_tsa - 1, 0) * 4 + math.floor(current_tile / 0x40))
	self.attr:update_gui()
end
