	pushc 50
	pushc 1		// push tuple <int:50>
	pushloc 1 1
	rout		// remote out tuple to location (1,1)
	pushc 25
	putled		// blink red LED
	halt