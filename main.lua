-- FCEUX's iup lua handler
require 'auxlib'

-- Files required for our program
require('input_management')
require('fceux_gui')
require('fceux_extensions')
require('iup_gui')
require('nes_palette')
require('tsa_handler')
require('chr_handler')

nes_pal = Pal:create_nes_pal()
-- Todo: Fix ram palette to look better
ram_pal = Pal:create_from_ram(nes_pal["palette"], 0x07C1, 0x20)

the_chr = CHR:create(get_array_from_rom(0x03D772, 23), get_array_from_rom(0x03D772 + 23, 23))

cur_tsa = 2 -- The tileset currently used
tile_layout_banks = {} -- banks utilized for each tileset
tile_layout_locations = {} -- the absolute address for every tsa
tiles_vbox = nil -- The vbox used for the chr tiles displayed

local function load_chr(start, ennd)
	charactors = {}
	for i=start, ennd, 0x10 do
		local colors = {4, 1, 2, 3} -- Rearranges the colors into the correct format
		local tile = {} -- The array of pixels
		for j=0, 7 do
			for k=0, 7 do
				lo = AND(rom.readbyte(i + j), bit.lshift(1, k))
				if lo ~= 0 then
					lo = 2
				else
					lo = 1
				end
				hi = AND(rom.readbyte(i + j + 8), bit.lshift(1, k))
				if hi ~= 0 then
					hi = 2
				else
					hi = 0
				end
				table.insert(tile, colors[lo + hi])
			end
		end
		table.insert(charactors, tile)
	end
	return charactors
end



-- Sets numerious tileset elements from memory
tileset_elements = {bg_chr_page1, bg_chr_page2, tile_layout_banks, tile_layout_locations}
local function set_tileset_element_attribute(idx, element, attribute)
	--print(idx, element, attribute)
	tileset_elements[element][idx] = attribute
end

local function set_tileset_element_attributes(idx_start, idx_end, element, memory_start)
	count = 0
	for i=idx_start, idx_end do
		set_tileset_element_attribute(i, element, rom.readbyte(memory_start + count))
		count = count + 1
	end
end

-- Finds the actual address for the TSA
local function set_tileset_location(idx_start, idx_end, memory_start)
	local cur = memory_start
	for i=idx_start, idx_end do
		set_tileset_element_attribute(i, 4, 
			get_absolute_address(tile_layout_banks[i], rom.readword(cur, cur+1))
		)
		cur = cur + 2
	end
end



local function load_current_img(tiln, palette)
	return iup.image{
		width=16,
		height=16,
		pixels=upscale_img(the_chr:get_iup_img_from_pages(tiln, cur_tsa), 8, 8, 2),
		colors=palette
	}
end

local function load_current_tile(tiln, palette)
	return iup.label{
		image=load_current_img(tiln, palette)
	}
end

local function initilize_current_chr_gui()
	local hboxes = {}
	for i=1, 16 do
		tiles = {}
		for j=1, 16 do
			tiles[j] = load_current_tile((j - 1) + (i - 1) * 0x10, ram_pal:get_attribute_palette(2))
		end
		local hbox = iup.hbox(tiles)
		hbox["margin"] = "0x0"
		table.insert(hboxes, hbox)
	end
	tiles_vbox = iup.vbox(hboxes)
end

local function set_current_chr_tile(idx, palette)
	idx = idx - 1
	hbox = math.floor(idx / 0x10) + 1
	loc = idx % 0x10 + 1
	tile = tiles_vbox[hbox][loc]
	tile["image"] = load_current_img(idx, palette)
	iup.Update(tile)
end

local function set_current_chr_tiles(palette)
	for i=1, 256 do
		set_current_chr_tile(i, palette)
	end
end



-- Initialization
-- Load the roms graphics into easily formable tiles
local end_of_rom_file = 0x10 + rom.readbyte(0x04) * 0x4000
set_tileset_element_attributes(1, 19, 3, 0x03DAB7) -- Banks
set_tileset_location(1, 19, 0x03DA07) -- Locations

the_tsa = TSA:create(the_chr)

initilize_current_chr_gui()

dialogs = dialogs + 1
handles[dialogs] = 
	iup.dialog{
		
		iup.hbox{
			the_tsa.vbox,
			iup.vbox{}, -- Todo: Add GUI to minipulate the tsa
			tiles_vbox
		},
		menu=iup.menu{
			iup.submenu{
				iup.menu{
					iup.item{title="Open"},
    				iup.item{title="Save As"},
    				iup.item{title="Exit"}	
				},
				title="File"
			},
			iup.submenu{
				iup.menu{
					iup.item{title="tileset 1"},
					iup.item{title="tileset 2"}
				},
				title="Tileset"
			}
		},
		title="TSA Editor",
		size="512x256",
		margin="10x10"
	}
handles[dialogs]:showxy(iup.CENTER, iup.CENTER)


state = 0

-- Update
while true do
	--update_palette()
	get_inputs()
	get_mouse_pos()

	if up then
		cur_tsa = cur_tsa + 1
		if cur_tsa == 24 then cur_tsa = 23 end
		set_current_chr_tiles(ram_pal:get_attribute_palette(2))
		the_tsa:reload()
	end

	if down then
		cur_tsa = cur_tsa - 1
		if cur_tsa == 0 then cur_tsa = 1 end
		set_current_chr_tiles(ram_pal:get_attribute_palette(2))
		the_tsa:reload()
	end

	emu.frameadvance()
end