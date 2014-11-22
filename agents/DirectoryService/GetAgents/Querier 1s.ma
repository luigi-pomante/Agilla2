BEGIN		pushc 25
		putled			// toggle green LED
		pushc 8
		sleep			// sleep for 1 second
		pushc 25
		putled			// toggle green LED		
		pushc 10		// limit to 10 results
		pushc unspecified	// no restriction on type of agent
		getAgents		
		clear			// clear the opstack
CONTINUE	rjump BEGIN