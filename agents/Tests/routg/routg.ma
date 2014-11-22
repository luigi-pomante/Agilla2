		pushc 0
		setvar 0
BEGIN		getvar 0
		inc
		copy
		setvar 0
		pushloc 1 1
		pushloc 2 1
		pushc 10
		pushc 4
		routg
		pushc 2
		sleep
		rjump BEGIN
