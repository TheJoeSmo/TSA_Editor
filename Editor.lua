
require 'auxlib'

tilez = {}

local NES_PAL = {
	"124 124 124", 
	"000 000 252", 
	"000 000 188", 
	"068 040 188", 
	"148 000 132", 
	"168 000 032", 
	"168 016 000", 
	"136 020 000", 
	"080 048 000", 
	"000 120 000", 
	"000 104 000", 
	"000 088 000", 
	"000 064 088", 
	"000 000 000", 
	"000 000 000", 
	"000 000 000", 
	"188 188 188", 
	"000 120 248", 
	"000 088 248", 
	"104 068 252", 
	"216 000 204", 
	"228 000 088", 
	"248 056 000", 
	"228 092 016", 
	"172 124 000", 
	"000 184 000", 
	"000 168 000", 
	"000 168 068", 
	"000 136 136", 
	"000 000 000", 
	"000 000 000", 
	"000 000 000", 
	"248 248 248", 
	"060 188 252", 
	"104 136 252", 
	"152 120 248", 
	"248 120 248", 
	"248 088 152", 
	"248 120 088", 
	"252 160 068", 
	"248 184 000", 
	"184 248 024", 
	"088 216 084", 
	"088 248 152", 
	"000 232 216", 
	"120 120 120", 
	"000 000 000", 
	"000 000 000", 
	"252 252 252", 
	"164 228 252", 
	"184 184 248", 
	"216 184 248", 
	"248 184 248", 
	"248 164 192", 
	"240 208 176", 
	"252 224 168", 
	"248 216 120", 
	"216 248 120", 
	"184 248 184", 
	"184 248 216", 
	"000 252 252", 
	"248 216 248", 
	"000 000 000", 
	"000 000 000"
}
local right

local lclick
local rclick
local llast
local rlast
local lpress
local rpress

local mxpos
local mypos

-- Borrowed from the show palette lua script included in Fceux
function dec_to_hex_table(tablein)
	tbl = {}
	for i, v in pairs(tablein) do
		table.insert(tbl, dec_to_hex(v))
	end
	return tbl
end

function dec_to_hex(numberin)
	return string.format("%X",numberin)
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- Extend the rom commands already provided by fceux to read words
function rom.readword(a, b)
	return rom.readbyte(a) + bit.lshift(rom.readbyte(b), 8)
end

-- Allows us to read pointers and get their real locaiton
local function get_absolute_address(bank, address)
	return bank * 0x2000 + address % 0x2000 + 0x10
end

local function check_input(item)
	if input.get()[item] then
		return true
	else
		return false
	end
end

local function get_inputs()
	up = check_input("up")
	down = check_input("down")
	left = check_input("left")
	right = check_input("right")

	llast = lclick
	lclick = check_input("leftclick")
	if not llast and lclick then
		lpress = true
	else
		lpress = false
	end
	rlast = rclick
	rclick = check_input("rightclick")
	if not rlast and rclick then
		rpress = true
	else
		rpress = false
	end
end

local function get_mouse_pos()
	mxpos = input.get()["xmouse"]
	mypos = input.get()["ymouse"]
end

local function make_dotted_box(x1, x2, y1, y2, color)
	trans = false
	if x1 < x2 then
		pos1 = x1
		pos2 = x2
	else
		pos1 = x2
		pos2 = x1
	end
	if y1 < y2 then
		pos3 = y1
		pos4 = y2
	else
		pos3 = y2
		pos4 = y1
	end
	for i=pos1, pos2 do
		if not trans then
			gui.setpixel(i , pos3, color)
			gui.setpixel(i , pos4, color)
			trans = true
		else
			trans = false
		end
	end
	trans = false
	for i=pos3, pos4 do
		if not trans then
			gui.setpixel(pos1 , i, color)
			gui.setpixel(pos2 , i, color)
			trans = true
		else
			trans = false
		end
	end
end

function align_grid(posx, posy, allign)
	return math.floor(posx/ allign) * allign, math.floor(posy/ allign) * allign
end

function make_selection_8x8(posx, posy)
	x, y = align_grid(posx, posy, 8)
	make_dotted_box(x, x+8, y, y+8 ,"white")
end

function make_selection_16x16(posx, posy)
	x, y = align_grid(posx, posy, 16)
	make_dotted_box(x, x+16, y, y+16 ,"white")
end

local function get_tileset_reference()

end

local function draw_tile(tiln, xpos, ypos, palette)
	til = tilez[tiln]
	for i=0, 7 do
		for j=1, 8 do
			pixel = til[j + i * 8]
			gui.drawpixel(xpos + j, ypos + i, palette[pixel])
		end
	end
end

local function make_img(tiln)
	tiln = tiln + 1
	til = tilez[tiln]
	img = {}
	for i=0, 7 do
		for j=1, 8 do
			--print(tablelength(til), tiln, (9 - j) + i * 8, til[(9 - j) + i * 8])
			t = til[(9 - j) + i * 8]
			table.insert(img, t)
		end
	end
	return img
end

-- made because iup is a total piece of shit
local function upscale_img(img, w, h, upscale)
	new_img = {}
	new_img[(w * upscale) * (h * upscale)] = 0  -- make the array a specific size
	count = 0
	for i=0, w - 1 do
		for n=0, upscale - 1 do
			for j=1, h do
				for m=0, upscale - 1 do
					new_img[count + 1] = img[j + i * h]
					count = count + 1
				end
			end
		end
	end
	return new_img
end

local function merge_tiles(ul, bl, ur, br, size)
	t = {ul, ur, bl, br}
	row_len = size
	new_img = {}
	count = 0
	for tile=0, 3 do
		x_offset = math.floor(tile/ 2) * (size * size * 2)
		y_offset = (tile % 2) * size
		for i=0, size - 1 do
			for j=1, size do
				x = x_offset + (i * row_len * 2)
				y = j + y_offset
				new_img[x + y] = t[tile + 1][(i * size) + j]
				count = count + 1
			end
		end
	end
	return new_img
end

local function chr_tsa_offset(tiln, bg1, bg2)
	if tiln <= 0x80 then
		return tiln % 0x80 + bg1 * 0x40
	else
		return tiln % 0x80 + bg2 * 0x40
	end
end

local cur_tile = 1
local cur_selection = {x=0, y=0, info=nil}
local function update_title_screen()
	make_selection_8x8(cur_selection["x"], cur_selection["y"])
	if lpress then
		cur_selection["x"] = mxpos
		cur_selection["y"] = mypos
	end

	if up then
		cur_tile = cur_tile + 1
	end
	if down then
		cur_tile = cur_tile - 1
	end
	draw_tile(cur_tile, 0x50, 0x50, {"black", "white", "black", "red", "blue"})

end

local cur_pals
function update_palette()
	cur_pals = {}
	for i=1, 8 do
		p = {}
		table.insert(p, "0 0 0")
		for j=1, 4 do
			b = memory.readbyte(0x07C0 + j + ((i - 1) * 4))
			table.insert(p, NES_PAL[b + 1])
		end
		table.insert(cur_pals, p)
	end
end

local bg_chr_page1 = {}
local bg_chr_page2 = {}
local tsa = {}
tsa_vbox = nil
cur_tsa = 2
title = 0
function update_tsa()
	tsa_hboxes = {}
	for i=0, 15 do
		tsa_hbox = {}
		for j=1, 16 do
			img = iup.label{
				title="",
				image=iup.image{
					width=16,
					height=16,
					pixels=merge_tiles(
						make_img(chr_tsa_offset(tsa[cur_tsa][j + i * 16][1], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
						make_img(chr_tsa_offset(tsa[cur_tsa][j + i * 16][2], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
						make_img(chr_tsa_offset(tsa[cur_tsa][j + i * 16][3], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
						make_img(chr_tsa_offset(tsa[cur_tsa][j + i * 16][4], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
						8
					),
					colors=cur_pals[math.floor(i / 4) + 1]
				}
			}
			table.insert(tsa_hbox, img)
		end
		tsa_hbox["margin"] = "0x0"
		table.insert(tsa_hboxes, iup.hbox(tsa_hbox))
	end

	tsa_vbox = iup.vbox(tsa_hboxes)
	print(title)
	title = title + 1
end

function update_tsa_individually()
	for i=1, 256 do
		update_tsa_tile(i)
	end
end

function update_tsa_tile(tiln)
	print(cur_tsa)
	tile = tiln % 0x10 + 1
	hbox = tsa_vbox[(math.floor((tiln - 1) / 0x10)) + 1]
	hbox[tile] = iup.label{
		title="",
		image=iup.image{
			width=16,
			height=16,
			pixels=merge_tiles(
				make_img(chr_tsa_offset(tsa[cur_tsa][tiln][1], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
				make_img(chr_tsa_offset(tsa[cur_tsa][tiln][2], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
				make_img(chr_tsa_offset(tsa[cur_tsa][tiln][3], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
				make_img(chr_tsa_offset(tsa[cur_tsa][tiln][4], bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])),
				8
			),
			colors=cur_pals[math.floor(tiln / 0x40) + 1]
		}
	}
end

-- Initialization
-- Load the roms graphics into easily formable tiles
local location = 0x10 + rom.readbyte(0x04) * 0x4000
local chr_size = rom.readbyte(0x05) * 0x2000 + location
print("loading tiles")
for i=location, chr_size, 0x10 do
	colors = {5, 2, 3, 4}
	tile = {}
	img_tile = {}
	count = 0
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
			count = count + 1
		end
	end
	table.insert(tilez, tile)
end

print("loading tile square assembly")
local location = 0x03D772
for i=location, location+22 do
	table.insert(bg_chr_page1, rom.readbyte(i))
	table.insert(bg_chr_page2, rom.readbyte(i+23))
end

local location = 0x03DAB7
local tile_layout_banks = {}
for i=location, location+18 do
	table.insert(tile_layout_banks, rom.readbyte(i))
end

local location = 0x03DA07
local tile_layout_locations = {}
for i=0, 18 do
	l = location + i * 2
	table.insert(tile_layout_locations, get_absolute_address(tile_layout_banks[i+1], rom.readword(l, l+1)))
end


for i, loc in pairs(tile_layout_locations) do
	tileset = {}
	for j=0, 255 do
		tile = {}
		--print(dec_to_hex(loc + j))
		table.insert(tile, rom.readbyte(loc + j + 0))
		table.insert(tile, rom.readbyte(loc + j + 0x100))
		table.insert(tile, rom.readbyte(loc + j + 0x200))
		table.insert(tile, rom.readbyte(loc + j + 0x300))
		if loc == 0x01E010 then
		--	print(dec_to_hex_table(tile))
		end
		table.insert(tileset, tile)
	end
	table.insert(tsa, tileset)
end

update_palette()


tsa_hboxes = {}

update_tsa(cur_tsa)

test_img = 
	iup.image{
		width=64,
		height=64,
		pixels=upscale_img(make_img(3), 8, 8, 8),
		colors=cur_pals[2]
	}

test_images = {}
for i=0, 15 do
	t_images = {}
	for j=1, 16 do
		table.insert(t_images,
			iup.label{
				title="",
				image=iup.image{
					width=16,
					height=16,
					pixels=upscale_img(make_img(chr_tsa_offset(j + i * 16, bg_chr_page1[cur_tsa], bg_chr_page2[cur_tsa])), 8, 8, 2),
					colors=cur_pals[1]
				}
			}
		)
		t_images["margin"] = "0x0"
	end
	table.insert(test_images, iup.hbox(t_images))
end
print("test")


dialogs = dialogs + 1
handles[dialogs] = 
	iup.dialog{
		iup.hbox{
			--iup.label{
			--	title="s"
			--},
			tsa_vbox,
			iup.vbox{},
			iup.vbox{
				iup.frame{
					iup.vbox(test_images)
				}
			},
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
		cur_tsa = 9
		update_tsa_individually()
		iup.Refresh(handles[dialogs])
	end

	update_title_screen()

	emu.frameadvance()
end