BEGIN	pushc 25
	putled       // toggle the red LED
	pushc 8
	sleep        // sleep for 1 second
	pushc 25
	putled       // toggle the red LED
	addr
	pushc 1
	ceq         
	rjumpc GOTO2
GOTO1	pushc 1
 	wmove 	
 	pushc 28
 	putled       // toggle yellow LED when migration fails
	halt
GOTO2   pushc 2
	wmove
	pushc 28
	putled       // toggle yellow LED when migration fails
        halt
	
