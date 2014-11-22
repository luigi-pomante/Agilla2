	aid
	getAgentLocation
	rjumpc SUCCESS
	pushc 28
	putled 			// toggle yellow LED
	halt
SUCCESS	copy
	pushc 1
	pushcl uart
	rout
	loc	
	ceq
	rjumpc EQUAL
	pushc 25
	putled			// toggle red LED if not equal (not correct)
	halt
EQUAL	pushc 26
	putled  		// toggle green LED if equal (correct)
	halt
