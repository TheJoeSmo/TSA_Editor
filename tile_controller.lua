TCNT = {}
TCNT.__index = TCNT

TCNT.ids = {}

function TCNT:initialize_gui()
	buttons = {}
	for i=1, 4 do
		tile = self.til:make_iup_img(self.tsa:get_tile(self.tsa_sel, i), self.pal)
		buttons[i] = iup.button{
			image=tile,
			impress=tile,
			impressboarder="no",
			rastersize="16x16"
		}
		buttons[i].action = "TCNT.ids[".. self.id .."]:btn_act(".. i ..")"
	end

	gui = iup.vbox{
		iup.hbox{
			buttons[1], buttons[2], margin="0x0"
		},
		iup.hbox{
			buttons[3], buttons[4], margin="0x0"
		}
	}
	return gui, buttons
end

TCNT.tsa_offset = {1, 3, 2, 4}

function TCNT:set_tile(tiln)
	self.buttons[self.cur_sel]["image"] = self.til:make_iup_img(tiln, self.pal)
	iup.Update(self.buttons[self.cur_sel])
	self.tsa:set_tile(self.tsa_sel, TCNT.tsa_offset[self.cur_sel], tiln)
end

function TCNT:set_tsa_idx(idx)
	self.tsa_sel = idx
	self.pal = math.floor(idx / 0x40) + 1
	for i=1, 4 do
		self.buttons[i]["image"] = self.til:make_iup_img(self.tsa:get_tile(self.tsa_sel, TCNT.tsa_offset[i]), self.pal)
	end
end

function TCNT:btn_act(idx)
	self.cur_sel = idx
end

function TCNT:create(tsa, til)
	local tcnt = {}
  	setmetatable(tcnt, TCNT)
	table.insert(TCNT.ids, tcnt)
  	self.id = tablelength(TCNT.ids)

  	self.tsa = tsa
  	self.til = til

  	self.tsa_sel = 1
  	self.cur_sel = 1
  	self.pal = 1

  	self.gui, self.buttons = self:initialize_gui()
  	return tcnt
end