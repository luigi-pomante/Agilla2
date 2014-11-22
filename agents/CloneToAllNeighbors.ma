BEGIN		numnbrs
LOOP		copy
		pushc 0
		ceq     // zero neighbors?
		rjumpc BLINKGREEN
		dec
		copy
		getnbr
		sclone  // strong clone to neighbor
		cpush   // get condition code
		pushc 2  
		ceq     // check if condition code = 2
		rjumpc LOOP // parent jumps to LOOP		
		
// This fragment continuously blinks
// the green LED.  It never returns.
//
// An example of how to use this code is as follows:
//
//    BEGIN  pushc BLINKGREEN
//           jumps 

BLINKGREEN  	pushc 26
            	putled
            	pushc 8
            	sleep            
            	rjump BLINKGREEN