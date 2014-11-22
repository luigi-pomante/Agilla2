// This agent blink all three LEDs, migrates to mote 1, and
// then blinks all three LEDs again.
//
// It should be injected onto the mote that is directly 
// attached to the programming board.
//
// Author: Chien-Liang Fok

#define SLEEP_PERIOD 10

BEGIN		pushc 31
        	putled        // toggle all three LEDs        
        	pushc SLEEP_PERIOD
        	sleep
        	pushc 31
        	putled        // toggle all three LEDs   
        	pushc 1
		smove         // strong move to mote 1
		pushc 31
        	putled        // toggle all three LEDs        
        	pushc SLEEP_PERIOD
        	sleep
        	pushc 31
        	putled        // toggle all three LEDs
		halt
