// Inject this agent onto the upper-left node, it should spread
// across top two rows
BEGIN		pushc 2
		setvar 11 // consider Y coordinate only
		loc
		dec
		pushc 11
		clearvar  // empty heap
		copy
		cisnbr
		rjumpc CLONE_ROW
		rjump OUT_FIRE
CLONE_ROW	sclone
OUT_FIRE	pushc 1
		setvar 11
		pushn fir
		pushc 1
		out         // out a fire tuple
		pushc 1
		setvar 11 // consider X coordinate only
		loc
		inc
		pushc 11
		clearvar // empty heap
		copy
		cisnbr
		rjumpc CLONE_COLUMN
		rjump BLINKRED //FINISH
CLONE_COLUMN	sclone
		pushc 2
		cpush   // push cond onto op stack
		ceq     // the clone has cond = 2   
		pushc OUT_FIRE
		jumpc     // go back to OUT_FIRE if the clone

BLINKRED    	pushc 25
            	putled
            	pushc 1
            	sleep            
            	rjump BLINKRED //FINISH		