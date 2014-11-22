	pushc 20
	putled
	
	pusht VALUE
	pusht LOCATION
	pusht LOCATION
	pusht LOCATION
	pushc 4
	pushcl QUERY_GOAL
	regrxn

SLE	pushcl 1000
	sleep
	rjump SLE
	
QUERY_GOAL	inp
	pop
	pop
	pop
	pop
	pop
	
	loc
	pushloc 4 7
	pushloc 6 7
	pushc 1
	pushc 4
	pushloc uart_x uart_y
	rout
	

	
	pushc 18
	putled	
	halt
	
	
	
	
	
