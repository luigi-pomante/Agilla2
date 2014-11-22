		pusht value
		pushc 1
		rrdpgs
		rjumpc SUCCESS
		halt
SUCCESS 	getvar 0
NEXT		copy
		getvars
		pop
		dec
		copy
		pushc 0
		ceq
		rjumpc DONE
		rjump NEXT
DONE		halt		
