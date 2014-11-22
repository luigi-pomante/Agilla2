BEGIN	pushc 25
	putled       // toggle the red LED
	pushc 2
	sleep        // sleep for 1/4 second
	pushc 25
	putled       // toggle the red LED	
	addr
	pushc 0
	cneq
	rjumpc DONE
GOTO1   pushc 1
	wmove
	pushc 28
	putled       // toggle yellow LED when migration fails
DONE    halt
	
