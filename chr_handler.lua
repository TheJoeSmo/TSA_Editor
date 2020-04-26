CHR = {}
CHR.__index = CHR

function CHR:get_tile_offset(tiln)
	local loc = (0x10 * tiln) % self.chr_size
	return loc + self.chr_start
end

-- Formats the NES images for iup
function CHR:get_iup_img(tiln)
	local colors = {4, 1, 2, 3}
	local tile = {}
	local loc = self:get_tile_offset(tiln)
	for j=0, 7 do
		for k=0, 7 do
			lo = AND(rom.readbyte(loc + j), bit.lshift(1, k))
			if lo ~= 0 then lo = 2 else lo = 1 end
			hi = AND(rom.readbyte(loc + j + 8), bit.lshift(1, k))
			if hi ~= 0 then hi = 2 else hi = 0 end
			tile[(j * 8) + (8 - k)] = colors[lo + hi]
		end
	end
	return tile
end

function CHR:get_iup_img_from_pages(tiln, partisian)
	local pages = {self.bg1[partisian], self.bg2[partisian]}
	local idx = math.floor((0x80 + tiln) / 0x80)
	--print(tiln, pages, idx, pages[idx], partisian, self.bg1[partisian], self.bg2[partisian])
	return self:get_iup_img((tiln % 0x80) + 1 + (pages[idx] * 0x40))
end

function CHR:set_new_bg(bg1, bg2)
	local bg1 = bg1 or 0
	local bg2 = bg2 or 0
	bg1 = bg1 % (self.size * 8)
	bg2 = bg2 % (self.size * 8)
	print(bg1, bg2)
	table.insert(self.bg1, bg1)
	table.insert(self.bg2, bg2)
end

function CHR:create(bg1s, bg2s)
	local chr = {}
  	setmetatable(chr, CHR)
  	self.chr_start = rom.readbyte(0x04) * 0x4000
  	self.size = rom.readbyte(0x05)
  	self.chr_size = self.size * 0x2000
  	self.bg1 = {}
  	self.bg2 = {}
  	bg1s = bg1s or {}
  	bg2s = bg2s or {}
  	for i, v in pairs(bg1s) do
  		self:set_new_bg(bg1s[i], bg2s[i])
  	end
  	print(bg1s, bg2s, self.bg1, self.bg2)
  	return chr
end

