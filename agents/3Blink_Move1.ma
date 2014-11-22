// This agent blinks the LED three times on the mote that is
// attached to the base station, then migrates onto mote 1.
// Once it arrives at mote 1, it blinks its LEDs again three
// times.
//
// Author: Chien-Liang Fok

#define SLEEP_PERIOD 1

BEGIN		pushc RETURN1
		pushc THREEBLINK
		jumps             // blink LEDs three times
RETURN1		pushc 1
		smove             // strong move to mote 1
		pushc RETURN2
		pushc THREEBLINK
		jumps             // blink LEDs three times
RETURN2		halt
THREEBLINK  	pushc 0
TBLOOP  	copy
        	pushc 6
        	cneq
        	rjumpc TBCONT
        	pop
        	jumps
TBCONT  	pushc 31
        	putled        // toggle all three LEDs        
        	pushc SLEEP_PERIOD
        	sleep
        	inc
        	rjump TBLOOP	
