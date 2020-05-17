
-- Writes a string to a file
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

-- Textify all data that we want into a file
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
		data = data .."\n Tile_Attributes_TS".. i .. ":\n\t.byte "
		for j=1, 4 do
			data = data.. "$" ..dec_to_hex_byte(tile_attr.semisolid_idxes[i * 4 + j - 4])..  ", "
		end
		for j=1, 4 do
			if j == 4 then
				data = data.. "$" ..dec_to_hex_byte(tile_attr.solid_idxes[i * 4 + j - 4]).. "\n"
			else
				data = data.. "$" ..dec_to_hex_byte(tile_attr.solid_idxes[i * 4 + j - 4])..  ", "
			end
		end
	end

	data = data.. "\nLevel_MinTileUWByQuad:\n\t.byte"
	for j, value in pairs(tile_attr.water_idxes) do
		if j % 0x10 == 0 then
			if j ~= 0 then
				data = data:sub(1, -3).. "\n\t.byte "
			end
		end
		data = data.. "$" ..dec_to_hex_byte(value).. ", "
	end
	return data
end

-- Saves to a file
function save_file()
  	local filedlg = iup.filedlg{
    	dialogtype = "SAVE", 
    	filter = "*.txt", 
    	filterinfo = "Text Files",
    }

  	filedlg:popup(iup.CENTER, iup.CENTER)

  	if (tonumber(filedlg.status) ~= -1) then
    	local filename = filedlg.value
    	print(filename)
    	write_file(filename, textify_data())
  	end
  	filedlg:destroy()
end

-- Saves the tileset directly to the rom
function save_tileset_to_rom()
	local tileset = the_tsa.tileset
	for i, tileset in pairs(tilesetz) do
		local loc = get_ts_info("absolute_address", i)

		for j=1, 4 do
			for k=1, 256 do
				rom.writebyte(loc, the_tsa:get_tile(k, j, i))
				loc = loc + 1
			end
		end
	end
end

-- Saves the tileset attributes directly to the rom
function save_tileset_attributes_to_rom()
	local tileset = the_tsa.tileset
	local count = 1
	for i, tileset in pairs(tilesetz) do
		local loc = get_ts_info("absolute_address", i)

		if i == 1 then
			for j=1, 4 do
				rom.writebyte(loc + 0x400 + j, tile_attr.semisolid_idxes[count])
				rom.writebyte(loc + 0x404 + j, tile_attr.semisolid_idxes[count])
			end
		else
			for j=1, 4 do
				rom.writebyte(loc + 0x400 + j, tile_attr.semisolid_idxes[count])
				rom.writebyte(loc + 0x404 + j, tile_attr.solid_idxes[count])
				count = count + 1
			end
		end
	end

	for i, value in pairs(tile_attr.water_idxes) do
		rom.writebyte(0x210 + i, value)
	end
end

-- Saves to the rom directly
function save_to_rom()
	error("saving does not work properly")
	save_tileset_to_rom()
	--save_tileset_attributes_to_rom()
end
