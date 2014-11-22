	pushc 1
	esetvar 19
	egetvar 19
	pushc 1
	ceq
	rjumpc EQUAL
	pushc 2
	putled
	halt
EQUAL	pushc 1
	putled
	halt