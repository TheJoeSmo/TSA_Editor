Pal = {}
Pal.__index = Pal

-- Todo: Fix this...  It kinda got screwed in the name of getting stuff actually done.

function load_palettes()
	local lines = lines_from("data/palettes.dat")
	local pals = {}
	for k,v in pairs(lines) do
  		pals[k] = v
	end
	return pals
end

Pal.reference = load_palettes()


-- Returns a series of data from RAM
function Pal:read_palette_from_ram(start, len)
	local pal = {}
	for i=start, start + len do
		table.insert(pal, memory.readbyte(i) + 1)
	end
	return pal
end


-- Converts a table of ints into a palette from a reference (typically the nes palette)
function Pal:convert(new)
	local new_pal = {}
	for i, v in pairs(new) do
		table.insert(new_pal, Pal.reference[v])
	end
	return new_pal
end

function Pal:create_from_table(tbl)	
	local pall = tbl or {}
	setmetatable(pall, self)
  	self.palette = self:convert(pall)
  	return pall
end

-- Create a palette from ram
function Pal:create_from_ram(start, len)
	local pall = self:read_palette_from_ram(start, len)
  	setmetatable(pall, self)
  	self.palette = self:convert(pall)
  	return pall
end

-- Gets the smaller subdivisons of the entire palette for attributes of sprites and blocks
function Pal:get_attribute_palette(attribute)
	attribute = attribute - 1
	local len = tablelength(self.palette)
	local offset = (attribute * 4) % len + 1
	return {self[offset], self[offset + 1], self[offset + 2], self.palette[offset + 3]}
end

function get_attribute_palette(tbl, attribute)
	attribute = attribute - 1
	local len = tablelength(tbl)
	local offset = (attribute * 4) % len + 1
	return {Pal.reference[tbl[offset] + 1], Pal.reference[tbl[offset + 1] + 1], 
	Pal.reference[tbl[offset + 2] + 1], Pal.reference[tbl[offset + 3] + 1]}
end

-- Todo: Add the ability to update the ram palette at runtime
-- Todo: Add the ability to make a palette from the rom
-- Todo: Move this to the chr tile file
function chr_tsa_offset(tiln, bg1, bg2)
	if tiln <= 0x80 then
		return tiln % 0x80 + bg1 * 0x40
	else
		return tiln % 0x80 + bg2 * 0x40
	end
end
