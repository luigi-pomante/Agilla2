	pushloc 1 1	// match by value
	pusht STRING	// match by type
	pushc 2		// match by value
	pusht VALUE	// match by type
	pushc 4		// 4 fields in template
	inp
	rjumpc FOUND
	pushc 1
	putled		// turn on red LED if not found
	halt
FOUND	pushc 2
	putled		// turn on green LED if found
	halt