BEGIN		pushc 25
		putled		// toggle green LED
		pushc 12
		sleep		// sleep for 1.5 second
		pushc 25
		putled		// toggle green LED
		pushc 0
		getAgentLocation
		rjumpc FOUND
		rjump CONTINUE
FOUND		pop		// pop the location off the stack
CONTINUE	rjump BEGIN
