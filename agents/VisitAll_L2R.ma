// This agent visits every mote, turning on the red LED.
// Visits each row from left-to-right.

BEGIN		pushloc 7 7
		loc
		ceq
		pushc BLINKGREEN
		jumpc          // do not clone to next node
		loc
		pushc 1 
		setvar 11     // heap[11] = 1 (analyze x-coordinate only)		
		inc
		wclone  // clone at next node
		rjumpc BLINKGREEN  // blink green if clone succeeded
BLINKRED        pushc 25           // blink red if clone failed
                putled
                pushc 8
                sleep            
                rjump BLINKRED
BLINKGREEN  	pushc 26
            	putled
            	pushc 1
            	sleep            
            	rjump BLINKGREEN

