BEGIN		pushc 26
		putled		// toggle green LED
		pushc 16
		sleep		// sleep for 2 seconds
		pushc 26
		putled		// toggle green LED
		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		pushc BEGIN
		jumps