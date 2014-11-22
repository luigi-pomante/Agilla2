	pushloc 1 1
	pushn abc
	pushc 2	
	pushc 0		// this should NOT match!
	pushc 4		// 4 fields in template
	inp
	rjumpc FOUND
	pushc 1
	putled		// turn on red LED if not found
	halt
FOUND	pushc 2
	putled		// turn on green LED if found
	halt