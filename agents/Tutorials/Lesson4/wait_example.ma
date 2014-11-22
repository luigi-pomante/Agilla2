// Blips the green LED when a tuple containing a value is
// inserted into the local tuple space.  Blips the red LED
// when a tuple containing a string is inserted into the 
// local tuple space.
		pusht value
		pushc 1
		pushc DOGREEN
		regrxn
		pusht string
		pushc 1
		pushc DORED
		regrxn
WAIT		wait


// reaction DOGREEN call-back function
DOGREEN		inp  		// remove tuple from TS
		clear		// clear OpStack
		pushc BLIPGREEN
		endrxn
		
// reaction DORED call-back function
DORED		inp  		// remove tuple from TS
		clear		// clear OpStack
		pushc BLIPRED
		endrxn

// turn on the green LED for 1 second
BLIPGREEN	pushc 2
		putled		// turn on green LED
		pushc 8
		sleep		// sleep 1 second
		pushc 0
		putled		// turn off green LED
		pushc WAIT
		jumps
		
// turn on the red LED for 1 second
BLIPRED		pushc 1
		putled		// turn on red LED
		pushc 8
		sleep		// sleep 1 second
		pushc 0
		putled		// turn off red LED
		pushc WAIT
		jumps