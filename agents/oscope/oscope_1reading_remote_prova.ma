// This agent takes an x-axis acceleration reading,
// packages it in a tuple, and sends it to mote 0.
// Each tuple only contains one sensor reading and
// contains a sequence number.
//
// It only works on Mica2 and MicaZ motes with the
// MTS310 sensor board.
//
// It must be injected on the mote that is attached
// to the programming board.  It will automatically
// migrate onto mote 1.
//
// Mote 0 must be attached to the programming board,
// mote 1 must be one hop away from mote 0.
//
// Author: Chien-Liang Fok

MOVE		pushc 28
		putled
		pushc 1
		smove			// move onto mote 1
		rjumpc MOVEOK
		pushc MOVE
		jumps
MOVEOK		pushc 0
		setvar 0		// set heap[0] = 0 (init seq. no.)
BEGIN		pushc 26
		putled			// toggle green LED						
		getvar 0
		copy
		inc
		setvar 0		// increment counter
		pushc PHOTO
		sense		   	// sense x axis of accelerometer
		pushc 2
		pushcl 0
		rout              	// send tuple [reading, seq. no.] to mote 0
		pushc 1
		sleep			// sleep for 1/8 of a second
		rjump BEGIN
