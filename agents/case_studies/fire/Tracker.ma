BEGIN		pushn det  
		pushc 1
		rdp  		// Check whether a tracker agent is already here
		rjumpc DIE	// die if tracker agent already present
OUT_DETECTOR	pushn det  	


		pushc 1 
		out  		// OUT a detector tuple	
		rjump REGISTER_RXN
DIE		halt						
RXN_FIRED	pushc 9 // 01001
		putled // turn off green and yellow LEDs
		pushn det
		
		
		pushc 1
		inp  // remove fire detector tuple
		halt		
REGISTER_RXN	pushn fir


		pushc 1
		pushc RXN_FIRED
		regrxn  // register fire reaction, die when reaction fires							
CHECK_NEIGHBORS	pushc 28
		putled  // toggle yellow LED
		pushn fir


		pushc 1
		rrdpg  // check if any neighbors are on fire		
		rjumpc FORM_BARRIER
RANDOM_MOVE	pushn det  
		
		
		pushc 1
		inp  // remove the detector tuple				
		pushc 9 // 01001
		putled  // turn off yellow and green LEDs
		randnbr			
		wmove  // weak move to random neighbor					
		halt
FORM_BARRIER	pushc 2
		putled  // turn on the green LED (turn everything else off)
		pushc 0 // for each neighbor whose dist <= 2 of fire, wclone to it
		setvar 9 // heap[9] = neighbor counter, init=0
BARRIER_LOOP	getvar 9
		numnbrs
		ceq
		rjumpc BARRIER_DONE // done checking all neighbors
		getvar 9
		getnbr // get the i'th neighbor
		vicinity
		rjumpc BARRIER_FIRE
		pushcl  BARRIER_NXT2  // not close to fire, skip 
		
		
		jumps
BARRIER_DONE	rand  
		pushc 31 // 63=111111b 31=11111b 15=1111b
		land     
		pushc 10
		add
		sleep // sleep between 10/8-36/8 seconds  //5/8-20/8 seconds
		pushc CHECK_NEIGHBORS
		jumps
BARRIER_FIRE	pushn det  // check if neighbor is on fire

		
		pushc 1
		getvar 9
		getnbr  
		rrdp	// check if neighbor has a detector
		pushcl BARRIER_NXT // jump to BARRIER_NXT if neighbor is on fire						
		
		
		jumpc
		pushn fir


		pushc 1
		getvar 9
		getnbr
		rrdp   // check if neighbor is on fire
		rjumpc BARRIER_NXT
		getvar 9
		getnbr
		wclone // clone self on neighbor
		rjumpc BARRIER_NXT2
BARRIER_NXT	clear // clear the op stack
BARRIER_NXT2	getvar 9
		inc
		setvar 9  // proceed to next neighbor
		pushcl BARRIER_LOOP
		
		
		jumps  // proceed to next neighbor		
