	pusht LOCATION
	pusht STRING
	pusht VALUE
	pusht VALUE
	pushc 4		// 4 fields in template
	inp
	rjumpc FOUND
	pushc 1
	putled		// turn on red LED if not found
	halt
FOUND	pushc 2
	putled		// turn on green LED if found
	halt