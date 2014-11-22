		pushcl 100
BEGIN		pushc 25
		putled		// toggle green LED
		pushcl 80
		sleep		// sleep for 10 seconds
		pushc 25
		putled		// toggle green LED
		pushc 0
		getClosestAgent
		rjumpc SUCCESS
		rjump CONTINUE
SUCCESS		pop
		pop
CONTINUE	dec
		copy
		pushc 0
		cneq
		pushc BEGIN
		jumpc 
		halt
