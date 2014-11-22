#define SLEEP_PERIOD 1

BEGIN		pushc RETURN
		pushc THREEBLINK
		jumps
RETURN 		halt
THREEBLINK  	pushc 0
TBLOOP  	copy
        	pushc 6
        	cneq
        	rjumpc TBCONT
        	pop
        	jumps
TBCONT  	pushc 31
        	putled        // toggle all three LEDs        
        	pushc SLEEP_PERIOD
        	sleep
        	inc
        	rjump TBLOOP	
