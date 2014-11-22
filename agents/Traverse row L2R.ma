// Inject this agent onto any agent on the left border, watch
// it migrate across the row.  It turns on the red LED upon
// arrival

BEGIN	pushc 1
	putled   // turn on red LED
	pushc 1 
	setvar 15// heap[15] = 1, consider only X coordinate
	loc
	inc
	copy
	cisnbr
	rjumpc MOVE
	halt
MOVE	wmove
	halt
	
