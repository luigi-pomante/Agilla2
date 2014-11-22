/*HOP1		pushloc 1 2
		smove
		rjumpc HOP2
		rjump HOP1
HOP2		pushloc 1 3
		smove
		rjumpc BEGIN
		rjump HOP2
*/
BEGIN		pushc 0
		setvar 0
		pusht value
		pusht location
		pusht location
		pusht value
		pushc 4
		pushc RXN
		regrxn
WAIT		wait			// wait for reaction to fire
RXN		inp			// remove the tuple
		clear
		getvar 0
		inc
		setvar 0
		pushc WAIT
		endrxn
