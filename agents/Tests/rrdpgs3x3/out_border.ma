HOP1		pushc 1
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP2		// clone goes to HOP2
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP1		// clone failed, try again		

HOP2		clear
		pushc 2
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP3		// clone goes to HOP3		
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP2		// clone failed, try again		

HOP3		clear
		pushc 5
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP4		// clone goes to HOP4		
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP3		// clone failed, try again		

HOP4		clear
		pushc 8
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP5		// clone goes to HOP5
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP4		// clone failed, try again		

HOP5		clear
		pushc 7
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP6		// clone goes to HOP6
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP5		// clone failed, try again		

HOP6		clear
		pushc 6
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc HOP7		// clone goes to HOP7
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP6		// clone failed, try again		

HOP7		clear
		pushc 3
		sclone
		cpush
		cpush
		pushc 1
		ceq
		rjumpc BEGIN		// clone goes to BEGIN
		pushc 2
		ceq
		pushcl BEGIN
		jumpc			// parent goes to BEGIN
		rjump HOP7		// clone failed, try again		


BEGIN		addr
		pushc 1
		out 			// insert a tuple containing a value
		halt