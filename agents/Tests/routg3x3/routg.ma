		pushc 4
		smove			// move to node 4
		pushc 0
		setvar 0   		// heap[0] = 0
BEGIN		getvar 0
		inc
		copy
		setvar 0		// heap[0]++		
		pushc 1
		routg			// routg(<heap[0]>)
		pushc 2
		sleep			// sleep for 1/4s
		rjump BEGIN
