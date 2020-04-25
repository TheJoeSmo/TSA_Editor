-- FCEUX's iup lua handler
require 'auxlib'

-- Files required for our program
require('input_management')
require('fceux_gui')
require('fceux_extensions')
require('iup_gui')
require('nes_palette')
require('tsa_handler')

-- Todo: Figure out what to do here
NES = {}
NES["palette"] = palette

tilez = {} -- The entire chr part of the rom
cur_pals = nil -- The current palette loaded
bg_chr_page1 = {} -- BG pages used per tileset
bg_chr_page2 = {}
tsa_vbox = nil -- The vbox used for the tsa
cur_tsa = 2 -- The tileset currently used
tile_layout_banks = {} -- banks utilized for each tileset
tile_layout_locations = {} -- the absolute address for every tsa
tiles_vbox = nil -- The vbox used for the chr tiles displayed

local function load_chr(start, ennd)
	charactors = {}
	for i=start, ennd, 0x10 do
		local colors = {5, 2, 3, 4} -- Rearranges the colors into the correct format
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
	print(idx, element, attribute)
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
		pixels=upscale_img(make_img(chr_tsa_offset(tiln, bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])), 8, 8, 2),
		colors=palette
	}
end

local function load_current_tile(tiln, palette)
	return iup.label{
		title="",
		image=load_current_img(tiln, palette)
	}
end

local function initilize_current_chr_gui()
	local hboxes = {}
	for i=1, 16 do
		tiles = {}
		for j=1, 16 do
			tiles[j] = load_current_tile((j - 1) + (i - 1) * 0x10, cur_pals[1])
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
tilez = load_chr(end_of_rom_file, end_of_rom_file + rom.readbyte(0x05) * 0x2000)
update_palette() -- Gets the current palette loaded

set_tileset_element_attributes(1, 23, 1, 0x03D772) -- BG 1
set_tileset_element_attributes(1, 23, 2, 0x03D772 + 23) -- BG 2
set_tileset_element_attributes(1, 19, 3, 0x03DAB7) -- Banks
set_tileset_location(1, 19, 0x03DA07) -- Locations

the_tsa = TSA:create()

-- Todo: Add functionality for the TSA to update dynamically
--update_tsa(cur_tsa)

initilize_current_chr_gui()
--set_current_chr_tiles(cur_pals[1]) -- Todo: Fix this


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
		cur_tsa = 7
		set_current_chr_tiles(cur_pals[1])
		the_tsa:reload()
	end

	update_title_screen()

	emu.frameadvance()
end