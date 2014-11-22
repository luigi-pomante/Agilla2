BEGIN		pushc 26
		putled		// toggle green LED
		pushc 40
		sleep		// sleep for 5 seconds
		pushc 26
		putled		// toggle green LED
		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		halt
