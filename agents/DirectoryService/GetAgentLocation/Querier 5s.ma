		pushc 50
BEGIN		pushc 25
		putled		// toggle green LED
		pushc 40   
		sleep		// sleep for 5 second
		pushc 25
		putled		// toggle green LED
		pushc 0
		getAgentLocation
		rjumpc FOUND
		rjump CONTINUE
FOUND		pop		// pop the location off the stack
CONTINUE	dec
		copy
		pushc 0
		cneq
		rjumpc BEGIN