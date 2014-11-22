// Inject this agent onto any agent on the bottom border, watch
// it migrate across the column.  It turns on the red LED upon
// arrival

BEGIN	pushc 1
	putled   // turn on red LED
	pushc 2 
	setvar 11 // consider only Y coordinate
	loc
	inc
	copy
	cisnbr
	rjumpc MOVE
	halt
MOVE	wmove
	halt
	