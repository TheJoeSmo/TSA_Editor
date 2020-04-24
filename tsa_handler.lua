function update_tsa()
	local tsa_hboxes = {}
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