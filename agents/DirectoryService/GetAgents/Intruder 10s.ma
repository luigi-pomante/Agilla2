BEGIN		pushc 26
		putled		// toggle green LED
		pushcl 80
		sleep		// sleep for 10 second
		pushc 26
		putled		// toggle green LED
LOOP		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		rjump LOOP
