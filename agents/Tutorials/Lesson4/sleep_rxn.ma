		pushc 0
		setvar 0		// set heap[0] = 0
		pusht value
		pushc 1
		pushc REACTION
		regrxn			// register reaction
		pushcl 80
		sleep			// sleep for 10 seconds
		getvar 0
		pushc 1
		pushloc uart_x uart_y
		rout			// send tuple to base station
		getvar 0
		pushc 7
		land
		putled			// display lower 3 bits on LEDs
		halt			// terminate agent

// reaction callback function		
REACTION	inp			// remove tuple from TS
		pop
		getvar 0
		add
		setvar 0		// heap[0] += value in tuple
		endrxn