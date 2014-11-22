// First move to (1,3)
HOP1		pushloc 1 2
		smove
		rjumpc HOP2
		rjump HOP1
HOP2		pushloc 1 3
		smove
		rjumpc BEGIN
		rjump HOP2

// Perform a multi-hop rout back
// to the base station:
//   rout(uart, <location>))		
BEGIN		loc
		pushc 1
		pushcl uart
		rout
		halt
		