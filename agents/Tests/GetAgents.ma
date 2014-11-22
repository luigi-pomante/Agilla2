	pushc unspecified	// search for any agent
	pushc 5			// limit results to 5
	getAgents		// get the locations of the agents
	rjumpc SUCCESS
	pushc 28
	putled  		// toggle yellow LED if not successful
	halt
SUCCESS	pushc 26
	putled  		// toggle green LED
	setvar 0		// heap[0] = number of results
LOOP	getvar 0
	copy
	dec
	setvar 0		// heap[0]--
	pushc 0
	ceq
	rjumpc DONE
	pushc 2
	pushcl uart
	rout			// send results to the base station	
	rjumpc LOOP
DONE	halt
