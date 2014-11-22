BEGIN		pushc 28
		putled		// toggle yellow LED
		pushc 40
		sleep		// sleep for 5 seconds
		pushc 28
		putled		// toggle yellow LED
LOOP		randnbr		// get a random neighbor
		rjumpc MIGRATE
		rjump BEGIN
MIGRATE		wmove
		rjump LOOP
