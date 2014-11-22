BEGIN	pushc fire
	setdesc			// change the description to "fire"
	pushc 8
	sleep
	pushc cargo
	setdesc			// change the description to "cargo"
	pushc 8
	sleep
	rjumpc BEGIN
