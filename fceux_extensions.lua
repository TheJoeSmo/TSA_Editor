-- Todo: Make these have less generic names

-- Borrowed from the show palette lua script included in Fceux
function dec_to_hex_table(tablein)
	tbl = {}
	for i, v in pairs(tablein) do
		table.insert(tbl, dec_to_hex(v))
	end
	return tbl
end

function file_exists(file)
  	local f = io.open(file, "rb")
  	if f then 
  		f:close() 
  	end
  	return f ~= nil
end

function lines_from(file)
  	if not file_exists(file) then 
  		return nil
  	end
  	lines = {}
  	for line in io.lines(file) do 
    	lines[#lines + 1] = line
  	end
  	return lines
end

function get_array_from_rom(loc, len)
	ele = {}
	for i=1, len do
		ele[i] = rom.readbyte(loc + i - 1)
	end
	return ele
end

function dec_to_hex_byte(numberin)
	return string.format("%02X",numberin)
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
function get_absolute_address(bank, address)
	return bank * 0x2000 + address % 0x2000 + 0x10
end
