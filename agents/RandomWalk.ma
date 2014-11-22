BEGIN		pushc 26
		putled		// toggle green LED
		pushc 1
		sleep		// sleep for 1/8 second
		pushc 26
		putled		// toggle green LED
		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		pushc BEGIN
		jumps