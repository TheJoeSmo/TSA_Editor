Pal = {}
Pal.__index = Pal

-- Loads the NES palette or reference palette to make all other palettes
function Pal:load_palettes()
	local lines = lines_from("data/palettes.dat")
	local pals = {}
	for k,v in pairs(lines) do
  		pals[k] = v
	end
	return pals
end

-- Makes the actual palette for the NES as a class
function Pal:create_nes_pal()
	local pal = {}
  	setmetatable(pal, Pal)
  	self.palette = self:load_palettes()
  	return pal
end

-- Returns a series of data from RAM
function Pal:read_palette_from_ram(start, len)
	local pal = {}
	for i=start, start + len do
		table.insert(pal, memory.readbyte(i) + 1)
	end
	return pal
end

-- Converts a table of ints into a palette from a reference (typically the nes palette)
function Pal:convert_from_reference(reference, new)
	local new_pal = {}
	for i, v in pairs(new) do
		table.insert(new_pal, reference[v])
	end
	return new_pal
end

-- Create a palette from ram
function Pal:create_from_ram(reference, start, len)
	local pal = self:read_palette_from_ram(start, len)
  	setmetatable(pal, Pal)
  	self.palette = self:convert_from_reference(reference, pal)
  	return pal
end

-- Gets the smaller subdivisons of the entire palette for attributes of sprites and blocks
function Pal:get_attribute_palette(attribute)
	attribute = attribute - 1
	local len = tablelength(self.palette)
	local offset = (attribute * 4) % len + 1
	return {self.palette[offset], self.palette[offset + 1], self.palette[offset + 2], self.palette[offset + 3]}
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
