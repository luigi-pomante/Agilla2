BEGIN		pushc 25
		putled		// toggle green LED
		pushc 24
		sleep		// sleep for 2 second
		pushc 25
		putled		// toggle green LED
		pushc 0
		getAgentLocation
		rjumpc FOUND
		rjump CONTINUE
FOUND		pop		// pop the location off the stack
CONTINUE	randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		halt