
--; BLT = air (tile < attr)
--; BGE = solid/semi-solid (tile >= attr)-
--;-
--;Tile_Attributes_TSX:
--;                            ; ranges for air           ; 00 - 24, 40 - 4F, 80 - 9F, C0 - D9
--;   .byte $25, $50, $A0, $E2 ; ranges for semi-solid    ; 25 - 2D, 50 - 53, A0 - AD, E2 - F0
--;   .byte $2D, $53, $AD, $F0 ; ranges for solid         ; 2D - 3F, 53 - 7F, AD - BF, F0 - FF
--;
--; This combines with Level_MinTileUWByQuad for water.
--; For plains it is these values...
--;   .byte $FF, $FF, $FF, $DA ; ranges for water         ; FF - FF, FF - FF, FF - FF, DA - E1
--;

TATTR = {}
TATTR.__index = TATTR

function TATTR:create(water_idxes, semisolid_idxes, solid_idxes)
	local tattr = {}
  	setmetatable(tattr, TATTR)
  	self.idx = 0
  	self.water_idxes = water_idxes
  	self.semisolid_idxes = semisolid_idxes
  	self.solid_idxes = solid_idxes
  	self.current_tile = 0
  	self.tile_type = iup.label{
  		title="".. self:get_tile_type(self.current_tile).. "            "
  	}
  	self.air_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_air_start()).. "-".. dec_to_hex_byte(self:get_air_end()).. "  "
  	}
  	self.water_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_water_start()).. "-".. dec_to_hex_byte(self:get_water_end()).. " "
  	}
  	self.semisolid_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_semisolid_start()).. "-".. dec_to_hex_byte(self:get_semisolid_end()).. " "
  	}
  	self.solid_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_solid_start()).. "-".. dec_to_hex_byte(self:get_solid_end()).. " "
  	}
  	return tattr
end

function TATTR:update_values(air, water, semi, solid)
	if self:get_water_start() > self:get_semisolid_start() then
		self:set_semisolid(self:get_semisolid_start() + air)
	elseif self:get_water_start() == self:get_semisolid_start() then
		self:set_semisolid(self:get_semisolid_start() + air)
		self:set_water(self:get_water_start() + air)
	else
		self:set_water(self:get_water_start() + air)
	end
	self:set_water(self:get_water_start() + water)
	self:set_semisolid(self:get_semisolid_start() + semi)
	self:set_solid(self:get_solid_start() + solid)

	self:update_gui()
end

function TATTR:update_gui()
	self.tile_type.title = "".. self:get_tile_type(self.current_tile)
	iup.Update(self.tile_type)
	self.air_gui.title = "".. dec_to_hex_byte(self:get_air_start()).. "-".. dec_to_hex_byte(self:get_air_end())
	iup.Update(self.air_gui)
  	self.water_gui.title = "".. dec_to_hex_byte(self:get_water_start()).. "-".. dec_to_hex_byte(self:get_water_end())
  	iup.Update(self.water_gui)
  	self.semisolid_gui.title = "".. dec_to_hex_byte(self:get_semisolid_start()).. "-".. dec_to_hex_byte(self:get_semisolid_end())
  	iup.Update(self.semisolid_gui)
  	self.solid_gui.title = "".. dec_to_hex_byte(self:get_solid_start()).. "-".. dec_to_hex_byte(self:get_solid_end())
  	iup.Update(self.solid_gui)
end

function TATTR:get_tile_type(tiln)
	tiln = tiln - 1
	if tiln <= self:get_air_end() then
		return "air"
	elseif tiln >= self:get_solid_start() then
		return "solid"
	else
		if self:get_water_end() > self:get_semisolid_end() then
			if self:get_semisolid_end() >= tiln then
				return "semisolid"
			else
				return "water"
			end
		else
			if self:get_water_end() >= tiln then
				return "water"
			else
				return "semisolid"
			end
		end
	end
end

function TATTR:set_current_tile(tiln)
	self.current_tile = tiln % 0xFF
	self.tile_type.title = "".. self:get_tile_type(self.current_tile)
	iup.Update(self.tile_type)
end

function TATTR:set_idx(idx)
	self.idx = idx
end

function TATTR:get_air_start()
	return self.idx % 4 * 0x40
end

function TATTR:get_air_end()
	if self.water_idxes[math.max(self.idx + 1 - 4, 1)] > self.semisolid_idxes[self.idx + 1] then
		return self.semisolid_idxes[self.idx + 1] - 1
	else
		return self.water_idxes[self.idx + 1] - 1
	end
end

function TATTR:set_water(w)
	w = math.min(w, 0xFF)
	w = math.max(w, 0)
	self.water_idxes[math.max(self.idx + 1 - 4, 1)] = w
end

function TATTR:get_water_start()
	return self.water_idxes[math.max(self.idx + 1 - 4, 1)]
end

function TATTR:get_water_end()
	if self.semisolid_idxes[self.idx + 1] > self.solid_idxes[self.idx + 1] then
		return math.max(self.solid_idxes[self.idx + 1] - 1, self.water_idxes[math.max(self.idx + 1 - 4, 1)])
	else
		return math.max(self.semisolid_idxes[self.idx + 1] - 1, self.water_idxes[math.max(self.idx + 1 - 4, 1)])
	end
end

function TATTR:set_semisolid(start)
	start = math.min(start, 0xFF)
	start = math.max(start, 0)
	self.semisolid_idxes[self.idx + 1] = start
	if start > self:get_solid_start() then
		self:set_solid(start)
	end
end

function TATTR:get_semisolid_start()
	return self.semisolid_idxes[self.idx + 1]
end

function TATTR:get_semisolid_end()
	return math.max(self.solid_idxes[self.idx + 1] - 1, self.semisolid_idxes[self.idx + 1])
end

function TATTR:set_solid(start)
	start = math.min(start, 0xFF)
	start = math.max(start, 0)
	self.solid_idxes[self.idx + 1] = start
	if start < self:get_semisolid_start() then
		self:set_semisolid(start)
	end
	if start < self:get_water_end() then
		self:set_water(start)
	end
end

function TATTR:get_solid_start()
	return self.solid_idxes[self.idx + 1]
end

function TATTR:get_solid_end()
	return self.idx % 4 * 0x40 + 0x3F
end