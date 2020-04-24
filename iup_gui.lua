-- Formats the NES images for iup
function make_img(tiln)
	local til = tilez[tiln + 1]
	local img = {}
	for i=0, 7 do
		for j=1, 8 do
			t = til[(9 - j) + i * 8]
			table.insert(img, t)
		end
	end
	return img
end

-- Upscales images by an intager
function upscale_img(img, w, h, upscale)
	local new_img = {}
	--new_img[(w * upscale) * (h * upscale)] = 0  -- make the array a specific size 
	local count = 0
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

-- Merges the TSA to allow for 16x16 tiles
function merge_tiles(ul, bl, ur, br, size)
	local t = {ul, ur, bl, br}
	local new_img = {}
	for tile=0, 3 do
		x_offset = math.floor(tile/ 2) * (size * size * 2)
		y_offset = (tile % 2) * size
		for i=0, size - 1 do
			for j=1, size do
				x = x_offset + (i * size * 2)
				y = j + y_offset
				new_img[x + y] = t[tile + 1][(i * size) + j]
			end
		end
	end
	return new_img
end
