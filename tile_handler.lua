TIL = {}
TIL.__index = TIL

TIL.ids = {}

-- Makes a simple 8x8 image that is upscaled x2 for better viewing
function TIL:make_iup_img(tiln, pal)
	if not pal then
		pal = self.mini_pal
	end
	return iup.image{
		width=16,
		height=16,
		pixels=upscale_img(self.chr_handler:get_iup_img_from_pages(tiln, cur_tsa), 8, 8, 2),
		colors=get_attribute_palette(self:get_current_pal(), pal)
	}
end

-- Create the gui elements for the tile handler
function TIL:initilize_tiles()
	local tiles, hboxes = {}, {}
	local vbox
	for i=1, 16 do
		local tilez = {}
		for j=1, 16 do
			tile = self:make_iup_img((j - 1) + (i - 1) * 0x10, nil)
			tile = iup.button{
				image=tile,
				impress=tile,
				impressboarder="no",
				rastersize="16x16"
			}
			tile.action = "TIL.ids[".. self.id .."]:btn_act(".. (j - 1) + (i - 1) * 0x10 ..")"
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

function TIL:get_current_pal()
	return get_ts_info("palettes", cur_tsa)[cur_pal]
end

function TIL:update_pal()
	return get_ts_info("palettes", cur_tsa)
end

-- Relaod a tile and update it
function TIL:set_tile(tiln)
	self.tiles[tiln]["image"] = self:make_iup_img(tiln - 1, nil)
	iup.Update(self.tiles[tiln])
end

-- Reloads every tile and updates it
function TIL:reload()
	self:update_pal()
	for i=1, 256 do
		self:set_tile(i)
	end
end

-- Creates the tsa and sets it up for use
function TIL:create(chr_handler)
	local til = {}
  	setmetatable(til, TIL)
  	table.insert(TIL.ids, til)
  	self.id = tablelength(TIL.ids)
  	self.chr_handler = chr_handler
  	self.mini_pal = 1
  	self.palette = self:update_pal()
  	self.tiles, self.hboxes, self.vbox = self:initilize_tiles()
  	self.tcnt = nil
  	return til
end

function TIL:set_tcnt(tcnt)
	self.tcnt = tcnt
end

function TIL:btn_act(tiln)
	self.tcnt:set_tile(tiln)
end