// Inject this agent onto (1,1) and watch as it traverses the border
// of the entire sensor network. It turns on the red LED upon
// arrival.

BEGIN_RIGHT 	pushc 1
		setvar 15 // consider only X coordinate
GO_RIGHT 	pushc 1
		putled   // turn on red LED		
		loc
		inc
		copy
		cisnbr
		rjumpc MOVE_RIGHT
		pop
		rjump BEGIN_UP
MOVE_RIGHT	smove 		
		rjump GO_RIGHT
		
BEGIN_UP	pushc 2
		setvar 15  // consider only Y coordinate
GO_UP		pushc 1
		putled    // turn on red LED
		loc
		inc
		copy
		cisnbr
		rjumpc MOVE_UP
		pop
		rjump BEGIN_LEFT
MOVE_UP		smove
		rjump GO_UP
		
BEGIN_LEFT	pushc 1
		setvar 15  // consider only X coordinate
GO_LEFT		pushc 1
		putled    // turn on red LED
		loc
		dec
		copy
		cisnbr
		rjumpc MOVE_LEFT
		pop
		rjump BEGIN_DOWN
MOVE_LEFT	smove
		rjump GO_LEFT
		
		
BEGIN_DOWN	pushc 2
		setvar 15  // consider only Y coordinate
GO_DOWN		pushc 1
		putled    // turn on red LED
		loc
		dec
		copy
		cisnbr
		rjumpc MOVE_DOWN
		pop
		rjump STOP
MOVE_DOWN	smove
		rjump GO_DOWN		

STOP		pushc 2
		putled
		halt		
	
