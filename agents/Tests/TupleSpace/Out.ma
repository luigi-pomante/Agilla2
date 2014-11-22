BEGIN		pushc 1
		pushn ncr
		pushc 2
		pushc 3
		out
		pushc RETURN
		rjump THREEBLINK
RETURN		halt		
THREEBLINK  	pushc 0
TBLOOP  	copy
        	pushc 6
        	cneq
        	rjumpc TBCONT
        	pop     // clear the opstack
        	jumps   // return to caller
TBCONT  	pushc 31
        	putled        // toggle all three LEDs        
        	pushc 1
        	sleep
        	inc
        	rjump TBLOOP		