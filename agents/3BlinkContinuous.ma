BEGIN		pushc RETURN
		pushc THREEBLINK
		jumps
RETURN 		pushc 5
		sleep         
		pushc BEGIN
		jumps
THREEBLINK  	pushc 0
TBLOOP  	copy
        	pushc 6
        	cneq
        	rjumpc TBCONT
        	pop
        	jumps
TBCONT  	pushc 31
        	putled        // toggle all three LEDs        
        	pushc 1
        	sleep
        	inc
        	rjump TBLOOP	
