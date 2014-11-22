// This agent takes an x-axis acceleration reading,
// packages it in a tuple, and sends it to the PC.
// Each tuple only contains one sensor reading and
// contains a sequence number.
//
// It only works on Mica2 and MicaZ motes with the
// MTS310 sensor board.
//
// It must be injected on the mote that is attached
// to the programming board.
//
// Author: Chien-Liang Fok


		pushc 0
		setvar 0		// set heap[0] = 0 (init seq. no.)
BEGIN		pushc 26
		putled			// toggle green LED						
		getvar 0
		copy
		inc
		setvar 0		// increment counter
		pushc photo
		sense		   	// sense x axis of accelerometer
		pushc 2
		pushcl uart
		rout              	// send tuple [reading, seq. no.] to the PC
		pushc 1
		sleep			// sleep for 1/8 of a second
		rjump BEGIN
