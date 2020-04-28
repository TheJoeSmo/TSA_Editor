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


nes_pal = Pal:create_nes_pal()
-- Todo: Fix ram palette to look better
ram_pal = Pal:create_from_ram(nes_pal["palette"], 0x07C1, 0x20)

the_chr = CHR:create(get_array_from_rom(0x03D772, 23), get_array_from_rom(0x03D772 + 23, 23))

cur_tsa = 2 -- The tileset currently used
tile_layout_banks = {} -- banks utilized for each tileset
tile_layout_locations = {} -- the absolute address for every tsa

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

function write_file(filename, str)
  	local ifile = io.open(filename, "w")
  	if (not ifile) then
    	iup.Message("Error", "Can't open file: " .. filename)
    	return
  	end
  	if (not ifile:write(str)) then
    	iup.Message("Error", "Fail when writing to file: " .. filename)
  	end
  	ifile:close()
end

function textify_data()
	local data = [[;----------------------------------
; Super Mario Bros. 3 Tile Square Assembly Tool Output
; By Joe Smo
;
; Below is the output for each tileset.
; For more information read consult the readme
;----------------------------------
	]]
	local tileset = the_tsa.tileset
	for i, tiles in pairs(tileset) do
		data = data.. "\n; Tileset: ".. i.. "  "
		for j=1, 4 do
			count = 0
			for k, tile in pairs(tiles) do
				if count % 0x10 == 0 then
					if count == 0 then
						data = data:sub(1, -3).. "\n\n\t.byte "
					else
						data = data:sub(1, -3).. "\n\t.byte "
					end
				end
				data = data.. "$" ..dec_to_hex_byte(tile[j]).. ", "
				count = count + 1
			end
		end
	end
	return data
end

function save_file()
  	local filedlg = iup.filedlg{
    	dialogtype = "SAVE", 
    	filter = "*.txt", 
    	filterinfo = "Text Files",
    }

  	filedlg:popup(iup.CENTER, iup.CENTER)

  	if (tonumber(filedlg.status) ~= -1) then
    	local filename = filedlg.value
    	write_file(filename, textify_data())
  	end
  	filedlg:destroy()
end

-- Initialization
-- Load the roms graphics into easily formable tiles
end_of_rom_file = 0x10 + rom.readbyte(0x04) * 0x4000
set_tileset_element_attributes(1, 19, 3, 0x03DAB7) -- Banks
set_tileset_location(1, 19, 0x03DA07) -- Locations

-- create the dialogs for the tsa and chr
the_tsa = TSA:create(the_chr)
the_til = TIL:create(the_chr)
the_tcnt = TCNT:create(the_tsa, the_til)
the_til:set_tcnt(the_tcnt)
the_tsa:set_tcnt(the_tcnt)

dialogs = dialogs + 1
handles[dialogs] = 
	iup.dialog{
		iup.frame{
			iup.hbox{
				iup.frame{
					the_tsa.vbox, sunken="yes", margin="2x2", title="Tile Square Assembly"
				},
				iup.vbox{
					iup.frame{
						the_tcnt.gui, sunken="yes", margin="2x2", title="Tile"
					}
					
				},
				iup.frame{
					the_til.vbox, sunken="yes", margin="2x2", title="Background Tiles"
				}
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
					iup.item{title="tileset 1"},
					iup.item{title="tileset 2"}
				},
				title="Tileset"
			}
		},
		title="TSA Editor",
		size="420x190",
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
		the_til:reload()
		the_tsa:reload()
	end

	if down then
		cur_tsa = cur_tsa - 1
		if cur_tsa == 0 then cur_tsa = 1 end
		the_tsa:reload()
		the_til:reload()
	end

	emu.frameadvance()
end