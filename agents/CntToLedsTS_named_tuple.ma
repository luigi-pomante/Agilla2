BEGIN	pusht value
	pusht string
	pushc 2
	inp
	rjumpc SKIP     // if a tuple was found, jump to SKIP
	pushc 0
	pushc 0
	pushc 0
SKIP	pop           	// pop the number of fields
	pop             // pop off the name
	pushc 1
	add
	copy       	
	pushn abc
	pushc 2
	out		// OUT the count tuple
	pushc 7
	land
	putled		// update the LED
	pushc 1
	sleep	
	pushc BEGIN
	jumps
