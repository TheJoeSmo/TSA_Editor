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
require('tile_handler')
require('tile_controller')
require('saving')
require('tile_attribute_handler')

-- Todo: Fix ram palette to look better
ram_pal = Pal:create_from_ram(0x07C1, 0x20)

cur_tsa = 1 -- The tileset currently used
cur_pal = 1 -- Current palette displayed
-- Todo: Move these routines somewhere else

-- Sets numerious tileset elements from memory
tileset_elements = {bg_chr_page1, bg_chr_page2, tile_layout_banks, tile_layout_locations}
local function set_tileset_element_attribute(idx, element, attribute)
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

local function get_water_tiles()
	return get_array_from_rom(0x210, 56)
end 

local function get_semisolid_tiles()
	a = {}
	count = 1
	for i, tileset in pairs(tilesetz) do
		b = get_array_from_rom(tileset.absolute_address + 0x400, 4)
		for j, c in pairs(b) do
			a[count] = c
			count = count + 1
		end		
	end
	return a
end

local function get_solid_tiles()
	a = {}
	count = 1
	for i, tileset in pairs(tilesetz) do
		b = get_array_from_rom(tileset.absolute_address + 0x404, 4)
		for j, c in pairs(b) do
			a[count] = c
			count = count + 1
		end	
	end
	return a
end

function change_palette_til_buttons(idx)
	the_til.mini_pal = math.min(((the_til.mini_pal - 1) + idx) % 4) + 1
	the_til:reload()
end

function get_all_ts_info(info)
	a = {}
	for i, v in pairs(tilesetz) do
		a[i] = v[info]
	end
	return a
end

function get_ts_info(info, tileset)
	return tilesetz[tileset][info]
end

function get_palette_information(idx)
	local lines = lines_from("data/default_palettes.dat")
	local count = 0
	local pal = {}
	for substring in lines[idx]:gmatch("%S+") do
		table.insert(pal, tonumber(substring, 16))
	end
	pal = Pal:create_from_table(pal)
	return pal
end

local function get_tileset_palette(chunk)
	palettes = {}
	for i=1, 8 do
		palettes[i] = get_palette_information((chunk - 1) * 8 + i)
	end
	return palettes
end

local function set_tileset_information_from_file()
	local lines = lines_from("data/tileset_info.dat")
	local tilesets = {}
	for k, v in pairs(lines) do
		chunks = {}
		for substring in v:gmatch("%S+") do
			table.insert(chunks, substring)
		end
  		tilesets[k] = {
  		bank=tonumber(chunks[1]), 
  		absolute_address=get_absolute_address(chunks[1], 0),
  		bg1=tonumber(chunks[2], 16), bg2=tonumber(chunks[3], 16),
  		bg_tile=tonumber(chunks[4], 16),
  		page1=tonumber(chunks[5]), page2=tonumber(chunks[6]),
  		palettes=get_tileset_palette(tonumber(chunks[7], 16)),
  		name=chunks[8]
  		}
	end
	return tilesets
end

function update_tileset_gui(idx)
	cur_tsa = idx
	the_til:reload()
	the_tsa:reload()
end

local function set_up_ts_dlg()
	items = {}
	for k, v in pairs(tilesetz) do
		items[k] = iup.item{title=v["name"], action="update_tileset_gui(".. k ..")"}
	end
	menu = iup.menu(items)
	return menu
end

function update_palette_gui(idx)
	cur_pal = idx

	the_til:update_pal()
	the_til:reload()
	the_tsa:reload()
end

local function set_up_pal_dlg()
	items = {}
	for i=1, 8 do
		items[i] = iup.item{title="Palette ".. i, action="update_palette_gui(".. i ..")"}
	end
	return iup.menu(items)
end

-- Initialization
-- Load the roms graphics into easily formable tiles
end_of_rom_file = 0x10 + rom.readbyte(0x04) * 0x4000

-- create the dialogs for the tsa and chr
tilesetz = set_tileset_information_from_file()
the_chr = CHR:create(get_all_ts_info("bg1"), get_all_ts_info("bg2"))
the_tsa = TSA:create(the_chr)
the_til = TIL:create(the_chr)
the_tcnt = TCNT:create(the_tsa, the_til)
the_til:set_tcnt(the_tcnt)
the_tsa:set_tcnt(the_tcnt)
ts_dlg = set_up_ts_dlg()
pal_dlg = set_up_pal_dlg()
current_tile = 0
current_tile_lable = iup.label{title="tile: ".. dec_to_hex_byte(current_tile).. "  ", margin="2x2", alignment="acenter"}
the_tsa:set_current_tile_gui(current_tile_lable)
tile_attr = TATTR:create(get_water_tiles(), get_semisolid_tiles(), get_solid_tiles())
the_tsa:set_tile_attr(tile_attr)
tile_attribute_labels = {
	iup.label{title="a        a"},
	iup.label{title="a        a"},
	iup.label{title="a        a"},
	iup.label{title="a        a"}
}

dialogs = dialogs + 1
handles[dialogs] = 
	iup.dialog{
		iup.frame{
			iup.vbox{
				iup.hbox{
					iup.vbox{
						iup.frame{
							the_tsa.vbox, sunken="yes", margin="2x2", title="Tile Square Assembly"
						}, sunken="yes", margin="5x2", title="Tile Attributes"
					},
					iup.vbox{
						iup.frame{
							iup.vbox{
								the_tcnt.gui, sunken="yes", alignment="acenter"
							}, alignment="acenter"
						},
						iup.frame{
							iup.vbox{
								current_tile_lable,
								tile_attr.tile_type, sunken="yes", margin="2x2", alignment="acenter"
							}
						},
						iup.frame{
							iup.hbox{
								iup.button{title="<", action="change_palette_til_buttons(-1)"},
								iup.button{title=">", action="change_palette_til_buttons(1)"},
								alignment="acenter", margin="8x0", sunken="yes"
							}, title="Palette", alignment="acenter", margin="2x2"
						}, alignment="acenter", margin="2x2", expandchildren="yes", sunken="yes"	
					},
					iup.frame{
							iup.vbox{
								the_til.vbox
							}, sunken="yes", margin="2x2", title="Background Tiles"
					}
				},
				iup.frame{
					iup.hbox{
						iup.vbox{
							tile_attribute_labels[1],
							iup.hbox{
								tile_attr.air_gui,
								iup.button{title=">", action="tile_attr:update_values(1, 0, 0, 0)"}
							}, margin="2x2"
						},
						iup.vbox{
							tile_attribute_labels[2],
							iup.hbox{
								iup.button{title="<", action="tile_attr:update_values(0, -1, 0, 0)"},
									tile_attr.water_gui,
								iup.button{title=">", action="tile_attr:update_values(0, 0, 1, 0)"}
							}, margin="2x2"
						},
						iup.vbox{
							tile_attribute_labels[3],
							iup.hbox{
								iup.button{title="<", action="tile_attr:update_values(0, 0, -1, 0)"},
										tile_attr.semisolid_gui,
								iup.button{title=">", action="tile_attr:update_values(0, 0, 0, 1)"}
							}, margin="2x2"							
						},
						iup.vbox{
							tile_attribute_labels[4],
							iup.hbox{
								iup.button{title="<", action="tile_attr:update_values(0, 0, 0, -1)"},
								tile_attr.solid_gui
							}, margin="2x2"
						}
					}, margin="2x2", sunken="yes", title="Tile Attributes"
				}, alignment="acenter", margin="2x2"
			}
		},
		menu=iup.menu{
			iup.submenu{
				iup.menu{
					iup.item{title="Open"},
    				iup.item{title="Save As", action="save_file()"},
    				iup.item{title="Exit"}	
				},
				title="File"
			},
			iup.submenu{
				iup.menu{
					iup.item{title="Save", action="save_to_rom()"}
				},
				title="ROM"
			},
			iup.submenu{
				set_up_ts_dlg(),
				title="Tilesets"
			},
			iup.submenu{
				iup.menu{
					iup.submenu{
						pal_dlg, title="Default"
					},
					title="default"
				},
				title="Palettes"
			}
		},
		title="TSA Editor",
		size="450x240",
		margin="10x10"
	}
the_tsa:update_tile_attribute_names()
tile_attr:update_gui()
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
		the_til:reload()
		the_tsa:reload()
	end

	if down then
		cur_tsa = cur_tsa - 1
		if cur_tsa == -1 then cur_tsa = 0 end
		the_tsa:reload()
		the_til:reload()
	end

	emu.frameadvance()
end