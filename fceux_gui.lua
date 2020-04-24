-- Todo: Figure out what to do with these as they serve no actual purpose atm

function make_dotted_box(x1, x2, y1, y2, color)
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

function draw_tile(tiln, xpos, ypos, palette)
	til = tilez[tiln]
	for i=0, 7 do
		for j=1, 8 do
			pixel = til[j + i * 8]
			gui.drawpixel(xpos + j, ypos + i, palette[pixel])
		end
	end
end

cur_tile = 1
cur_selection = {x=0, y=0, info=nil}
function update_title_screen()
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
