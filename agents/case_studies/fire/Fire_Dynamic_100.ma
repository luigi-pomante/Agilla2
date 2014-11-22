BEGIN		pushn fir


		pushc 1
		rdp 
		pushc STOP 
		jumpc		
CONTINUE	pushn fir


		pushc 1
		out  // out a fire tuple
LOOP		pushc RETURN1
		pushcl 100
		
		
		pushc BLINKREDC // blink the LED between 20-51 times
		jumps
RETURN1		randnbr 
		setvar 0 // heap[0] = random neighbor
	 	pushn fir
	 	
	 	
	 	pushc 1
 		getvar 0
	 	rrdp      // check if neighbor has a fire tuple
		rjumpc SKIP  // jump to SKIP, the neighbor is not on fire
CLONE2NBR	getvar 0
		wclone
SKIP		clear  // clear op stack
		pushc LOOP
		jumps // loop back	

// This procedure expects the stack to be [val=#blinks][return address]				
BLINKREDC 	pushc 25		
		putled // blink red
		pushc 1
		sleep
		dec
		copy
		pushc 0
		ceq
		rjumpc BLINKREDCDONE
		rjump BLINKREDC
BLINKREDCDONE	pop
		jumps
STOP		halt // duplicate fire agent
		
// out a fire tuple
// select random number between 9-40
// blink that many times
// select random neighbor
// see if random neighbor has a fire tuple
// if it does NOT, blink yellow and red a few times, and weak clone there
// repeat		
