-- Todo: Update inputs to just utilize the built in functions opposed to storing them in variables

right = false

lclick = false
rclick = false
llast = false
rlast = false
lpress = false
rpress = false

mxpos = false
mypos = false

function check_input(item)
	if input.get()[item] then
		return true
	else
		return false
	end
end

function get_inputs()
	up = check_input("up")
	down = check_input("down")
	left = check_input("left")
	right = check_input("right")

	llast = lclick
	lclick = check_input("leftclick")
	if not llast and lclick then
		lpress = true
	else
		lpress = false
	end
	rlast = rclick
	rclick = check_input("rightclick")
	if not rlast and rclick then
		rpress = true
	else
		rpress = false
	end
end

function get_mouse_pos()
	mxpos = input.get()["xmouse"]
	mypos = input.get()["ymouse"]
end
