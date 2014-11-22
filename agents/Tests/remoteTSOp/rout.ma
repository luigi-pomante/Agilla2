BEGIN		pushc 1  // push value 1 onto stack
		pushc 2  // push value 1 onto stack
		pushc 3  // push value 1 onto stack
		pushc 3  // indicate 3 fields in tuple
		pushc 1  // destination = mote 1
		rout	 // remote OUT
		pushc 25
		putled	// toggle red LED
		halt