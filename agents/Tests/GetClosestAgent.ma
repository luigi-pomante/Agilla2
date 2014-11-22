	pushc unspecified
	getClosestAgent
	rjumpc 	SUCCESS
	pushc 25
	putled		// toggle red LED
	halt
SUCCESS	pushc 26
	putled  	// toggle green LED if equal (correct)
	pushc 2
	pushcl uart
	rout		// send the id and location of the closest agent to the base station
	halt
