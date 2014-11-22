	pushc unspecified	// search for any agent
	getNumAgents
	rjumpc SUCCESS
	pushc 28
	putled  		// toggle yellow LED if not successful
	halt
SUCCESS	copy
	pushc 1
	pushcl uart
	rout			// send results to the base station
	pushc 1	
	ceq
	rjumpc EQUAL
	pushc 25
	putled			// toggle red LED if not equal (not correct)
	halt
EQUAL	pushc 26
	putled  		// toggle green LED if equal (correct)
	halt
