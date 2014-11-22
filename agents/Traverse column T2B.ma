// Inject this agent onto any agent on the top border, watch
// it migrate across the column.  It turns on the red LED upon
// arrival

BEGIN	pushc 1
	putled   // turn on red LED
	pushc 2 
	setvar 11 // heap[11] = 2, consider only Y coordinate
	loc
	dec
	copy
	cisnbr
	rjumpc MOVE
	halt
MOVE	wmove
	halt
	