		pushcl 100
		setvar 0		// heap[0] = query count
BEGIN		pushc 25
		putled			// toggle green LED
		pushcl 80
		sleep			// sleep for 10 seconds
		pushc 25
		putled			// toggle green LED				
		pushc unspecified	// no restriction on type of agent
		pushc 10		// limit to 10 results
		getAgents		
		clear			// clear the opstack
CONTINUE	getvar 0
		dec
		copy
		setvar 0
		pushc 0
		cneq
		pushc BEGIN
		jumpc
		halt
