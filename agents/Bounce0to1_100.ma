	pushcl 100
BEGIN	dec		// decrement the counter
	copy
	pushc 0
	cneq
	rjumpc CONT
	halt		// halt the agent
CONT	pushc 25
	putled       // toggle the red LED
	pushc 2
	sleep        // sleep for 1/4 second
	pushc 25
	putled       // toggle the red LED
	addr
	pushc 0
	ceq     
	rjumpc GOTO1
GOTO0	pushc 0
 	smove 	
 	pushc BEGIN
 	jumps
GOTO1   pushc 1
	smove
	pushc BEGIN
	jumps
