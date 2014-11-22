BEGIN		pushc 26
		putled		// toggle green LED
		pushc 8
		sleep		// sleep for 1 second
		pushc 26
		putled		// toggle green LED
LOOP		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		rjump LOOP