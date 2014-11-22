		pushc 0
		getAgentLocation
		rjumpc FOUND
		rjump CONTINUE
FOUND		clear
		pushc 25
		putled 		// toggle red
		halt
CONTINUE	pushc 28
		putled		// toggle yellow
		halt
