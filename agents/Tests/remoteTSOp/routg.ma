BEGIN		pushc 1  // push value 1 onto stack
		pushc 2  // push value 1 onto stack
		pushc 3  // push value 1 onto stack
		pushc 3  // indicate 3 fields in tuple
		routg	 // remote OUT
		pushc 25
		putled	// toggle red LED
		halt