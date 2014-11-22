		pushcl 100
BEGIN		copy
		pushc 0
		cneq
		rjumpc CONT
		halt			// halt after executing getAgentLocation 100 times
CONT		dec
		aid
		getAgentLocation
		rjumpc SUCCESS
		pushc 25
		putled 			// toggle red LED if fail
		pushc BEGIN
		jumps
SUCCESS		pop
		pushc 26
		putled  		// toggle green LED if success
		pushc BEGIN
		jumps
