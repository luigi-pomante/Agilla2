// This agent takes tuples containing sensor data and
// forwards them to the PC.  It toggles the green LED
// each time it forwards a sensor reading.
//
// Author: Chien-Liang Fok

BEGIN		pushc 31
		putled
		pusht VALUE
		pushrt PHOTO
		pushc 2
		in			// read in tuples containing sensor readings
		pushc 31
		putled
		pushcl uart
		rout              	// send tuple [reading, seq. no.] to the PC
		pushc 26
		putled			// toggle green LED	
		rjump BEGIN
