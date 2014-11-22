BEGIN	pusht value
	pushc 1
	inp
	rjumpc SKIP     // if a tuple was found, jump to SKIP
	pushc 0	
	pushc 0
SKIP	pop           	// pop the number of fields
	pushc 1
	add
	copy       	
	pushc 1
	out		// OUT the count tuple
	pushc 7
	land
	putled		// update the LED
	pushc 1
	sleep	
	pushc BEGIN
	jumps
