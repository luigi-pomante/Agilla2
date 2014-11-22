BEGIN		pushc 1
		pushc 1
		pushc RXN
		regrxn
		wait
		
RXN		remove		// remove the tuple from the tuple space
		clear
		pushc DOROUT
		endrxn
		
DOROUT		pushc 25
		putled		// toggle the red LED
		pushc 8
		sleep		// sleep for 1 second
		pushc 1
		pushc 1		// push tuple [value:1] onto stack
		hid
		pushc 0
		ceq
		rjumpc ROUT1
ROUT0		pushc 0
		rout		// rout to mote 0
		wait
ROUT1		pushc 1
		rout		// rout to mote 1
		wait