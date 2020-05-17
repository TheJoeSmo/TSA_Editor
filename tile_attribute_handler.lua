
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
  	self.attributes = self:load_custom_tiles()
  	self.tile_type = iup.label{
  		title="".. self:get_tile_type(self.current_tile).. "         "
  	}
  	self.air_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_air_start()).. "-".. dec_to_hex_byte(self:get_air_end()).. "  ", margin="2x2", alignment="acenter"
  	}
  	self.water_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_water_start()).. "-".. dec_to_hex_byte(self:get_water_end()).. " ", margin="2x2", alignment="acenter"
  	}
  	self.semisolid_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_semisolid_start()).. "-".. dec_to_hex_byte(self:get_semisolid_end()).. " ", margin="2x2", alignment="acenter"
  	}
  	self.solid_gui = iup.label{
  		title="".. dec_to_hex_byte(self:get_solid_start()).. "-".. dec_to_hex_byte(self:get_solid_end()).. " ", margin="2x2", alignment="acenter"
  	}
  	return tattr
end

function TATTR:update_values(air, water, semi, solid)
	if cur_tsa == 1 then
		self:set_semisolid(self:get_semisolid_start() + air + water)
	else
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
	end
	self:update_gui()
end

function TATTR:update_gui()
	if cur_tsa == 1 then
		self:set_gui_element_title(self.tile_type, "".. self:get_tile_type(self.current_tile))
		self:set_gui_element_title(self.air_gui, self:make_gui_text_range(self:get_air_start(), self:get_air_end()))
		self:set_gui_element_title(self.water_gui, self:make_gui_text_range(self:get_water_start(), self:get_water_end()))
		self:set_gui_element_title(self.semisolid_gui, "nil")
		self:set_gui_element_title(self.solid_gui, "nil")
	else
		self:set_gui_element_title(self.tile_type, "".. self:get_tile_type(self.current_tile))
		self:set_gui_element_title(self.air_gui, self:make_gui_text_range(self:get_air_start(), self:get_air_end()))
		self:set_gui_element_title(self.water_gui, self:make_gui_text_range(self:get_water_start(), self:get_water_end()))
		self:set_gui_element_title(self.semisolid_gui, self:make_gui_text_range(self:get_semisolid_start(), self:get_semisolid_end()))
		self:set_gui_element_title(self.solid_gui, self:make_gui_text_range(self:get_solid_start(), self:get_solid_end()))
	end
end

function TATTR:make_gui_text_range(s, e)
	return "".. dec_to_hex_byte(s).. "-".. dec_to_hex_byte(e)
end

function TATTR:set_gui_element_title(ele, title)
	ele.title = title
	iup.Update(ele)
end

function TATTR:check_custom_tiles(tiln)
	if tiln == nil then
		return nil
	end
	local custom_tiles = self.attributes[cur_tsa]
	for key, value in pairs(custom_tiles) do
		for i, v in pairs(value) do
			if tiln == v then
				return key
			end
		end
	end
	return nil
end

function TATTR:get_tile_type(tiln)
	tiln = tiln - 1
	a = self:check_custom_tiles(tiln)
	if cur_tsa == 1 then
		if not a then
			if tiln <= self:get_air_end() then
				return "solid        "
			else
				return "can enter    "
			end
		else
			return a
		end
	else
		if not a then
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
		else
			return a
		end
	end
end

function TATTR:load_custom_tiles()
	s = split(read_file_to_string("data/tsa_attribute.dat"), "|")
	eles = {}
	for i, v in pairs(s) do
		ele = {}
		for j, u in pairs(split(v, "\n")) do
			if j ~= 1 then
				e = split(u, ":")
				name = e[1]
				values = e[2]
				v = {}
				for k, w in pairs(split(values, ",")) do
					v[k] = tonumber(w, 16)
				end
				ele[name] = v
			end
		end
		eles[i] = ele
	end
	return eles
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
	if cur_tsa == 1 then
		return math.max(self:get_semisolid_start() - 1, self.idx % 4 * 0x40)
	else
		if self.water_idxes[math.max(self.idx + 1 - 4, 1)] > self.semisolid_idxes[self.idx + 1] then
			return self.semisolid_idxes[self.idx + 1] - 1
		else
			return self.water_idxes[math.max(self.idx + 1 - 4, 1)] - 1
		end
	end
end

function TATTR:set_water(w)
	w = math.min(w, 0xFF)
	w = math.max(w, 0)
	self.water_idxes[math.max(self.idx + 1 - 4, 1)] = w
end

function TATTR:get_water_start()
	if cur_tsa == 1 then
		return self:get_semisolid_start()
	else
		return self.water_idxes[math.max(self.idx + 1 - 4, 1)]
	end
end

function TATTR:get_water_end()
	if cur_tsa == 1 then
		return self:get_solid_end()
	else
		if self.semisolid_idxes[self.idx + 1] > self.solid_idxes[self.idx + 1] then
			return math.max(self.solid_idxes[self.idx + 1] - 1, self.water_idxes[math.max(self.idx + 1 - 4, 1)])
		else
			return math.max(self.semisolid_idxes[self.idx + 1] - 1, self.water_idxes[math.max(self.idx + 1 - 4, 1)])
		end
	end
end

function TATTR:set_semisolid(start)
	start = math.min(start, 0xFF)
	start = math.max(start, 0)
	self.semisolid_idxes[self.idx + 1] = math.max(start, self.idx % 4 * 0x40)
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