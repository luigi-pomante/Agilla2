		pusht VALUE
		pushc 1
		pushc DORXN
		regrxn			// register reaction (addr=DORXN, template=<int:1>)
		
// continuously blink green LED
BLINKGREEN	pushc 26
		putled
		pushc 1
		sleep
		rjump BLINKGREEN

// The reaction callback function
DORXN		pop
		pop			// pop tuple off stack
		pushc BLINKRED		// push address BLINKRED onto stack
		endrxn			// end reaction & jump to BLINKRED

// Blink the red LED		
BLINKRED	pushc 25
		putled			// toggle red LED
		pushc 1
		sleep			// sleep for 1/8s
		pushc 25
		putled			// toggle red LED
		jumps			// jump back to address before rxn occurred