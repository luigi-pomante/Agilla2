	pushcl 1000	// push 1000 onto stack
BEGIN	dec
	copy	
	pushc 0
	ceq
	rjumpc DONE
	pushc 1
	pushc 1
	pop
	pop
DONE	pushc uart
	wmove