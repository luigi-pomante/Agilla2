BEGIN		pushc RETURN1
		pushcl THREEBLINK
		jumps
RETURN1		pushc 2
		setvar 11 // consider only Y axis
		loc
		inc
		copy 
		cisnbr
		rjumpc CHECK_FIRE
		halt   // no northern neighbor, halt

CHECK_FIRE	setvar 0  // heap[0] = address of north neighbor
		pushn fir
		pushc 1
		getvar 0
		rrdp      // remote rdp for <"fir"> tuple
		rjumpc FIRE_FOUND
		getvar 0
		wmove  // go to northern neighbor
		halt
FIRE_FOUND	clear // clear the stack
		pushn det
		pushc 1
		out  // out a detection tuple
		pushc 1
		setvar 11 // consider only the X axis
		loc
		inc
		copy
		cisnbr
		rjumpc CHECK_RIGHT
		rjump CHECK_LEFT
CHECK_RIGHT     setvar 0 // heap[0] = address of right neighbor
		pushn det
		pushc 1
		getvar 0
		rrdp
		rjumpc CHECK_LEFT
		getvar 0
		wclone  // weak clone on right neighbor
CHECK_LEFT	loc
		dec
		copy		
		cisnbr
		rjumpc POLL_LEFT
		rjump DONE
POLL_LEFT	setvar 0
		pushn det
		pushc 1
		getvar 0
		rrdp
		rjumpc DONE
		getvar 0
		wclone						

DONE		clear 
		//halt
BLINKGREEN  	pushc 26
            	putled
            	pushc 1
            	sleep            
            	rjump BLINKGREEN     
		
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
        	
   	
