	pushloc 1 1
	pushn abc
	pushc 2
	pushc 1
	pushc 4  	// 4 fields in template
	inp		// remove tuple
	rjumpc FOUND 	// jump to FOUND if success
	pushc 1
	putled		// turn on red LED if not found
	halt
FOUND	pushc 2
	putled		// turn on green LED if found
	halt