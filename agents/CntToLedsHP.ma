BEGIN	getvar 0
	rjumpc SKIP
	pushc 0
SKIP	pushc 1
	add
	copy
	setvar 0
	pushc 7
	land
	putled
	pushc 1
	sleep
	rjump BEGIN
