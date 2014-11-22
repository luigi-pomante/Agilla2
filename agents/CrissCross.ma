// Inject this agent onto any agent on the left border, watch
// it migrate across the row.  It blinks the yellow LED when it
// lands on a mote.  Once it reaches the border of the network
// it goes in the opposite direction.

		pushc 1 
		setvar 15		// heap[15] = 1, consider only X coordinate	
GOLEFT		pushc RETURN1
		pushc BLINKY
		jumps			// blink yellow LED	
RETURN1		loc
		inc
		copy
		cisnbr
		rjumpc MOVELEFT
		pop			// pop [x+1, y] off stack
		rjump GORIGHT
MOVELEFT	smove
		pushc GOLEFT
		jumps
GORIGHT		pushc RETURN2
		pushc BLINKY
		jumps
RETURN2		loc
		dec
		copy
		cisnbr
		rjumpc MOVERIGHT
		pop			// pop [x-1, y] off stack
		pushc GOLEFT
		jumps
MOVERIGHT	smove		
		pushc GORIGHT
		jumps


BLINKY	pushc 28
	putled   	// toggle yellow LED
	pushc 1
	sleep
	pushc 28
	putled		// toggle yellow LED	
	jumps
	
