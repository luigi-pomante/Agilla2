BEGIN		pushn abc
		pusht location
		pushc 2
		pushcl uart
		rrdp
		rjumpc SUCCESS
		pushc 25
		putled			// toggle red LED if fail
		halt
SUCCESS		pushc 26
		putled			// toggle green LED if success
		halt
