BEGIN		pushc 26
		putled		// toggle green LED
		pushc 2
		sleep		// sleep for 1 second
		pushc 26
		putled		// toggle green LED
		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		pushc BEGIN
		jumps