// Inject this agent onto any agent on the left border, watch
// it migrate across the row.  It blinks the yellow LED when it
// lands on a mote.  Once it reaches the border of the network
// it goes in the opposite direction.

// This agent will only bounce 9 times, visiting 10 nodes

// Note that this agent will not work on row 1 because it
// will try to migrate onto the base station when it arrives
// on mote (1,1) while going right.
		pushc 1 
		setvar 15		// heap[15] = 1, consider only X coordinate	
		pushc 10
		setvar 0		// heap[0] = number of hops
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
		pushc RETURN3
		pushc CHECKCOUNT
		jumps			// check number of migrations
RETURN3		pushc GOLEFT
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
		pushc RETURN4
		pushc CHECKCOUNT
		jumps			// check number of migrations
RETURN4		pushc GORIGHT
		jumps


BLINKY	pushc 28
	putled   	// toggle yellow LED
	pushc 1
	sleep
	pushc 28
	putled		// toggle yellow LED	
	jumps
	
CHECKCOUNT 	getvar 0
		dec
		copy		
		setvar 0
		pushc 0
		cneq
		rjumpc CONT
		halt			// halt the agent after 10 migrations
CONT		jumps
