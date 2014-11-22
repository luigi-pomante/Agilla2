BEGIN		pushc RETURN
		getvar 0     // heap 0 must contain # of times to blink LED
		pushcl BLINKGREENC
		jumps
RETURN          halt
		
BLINKGREENC 	pushc 26 
		putled // blink green
		pushc 1
		sleep
		dec
		copy
		pushc 0
		ceq
		rjumpc BLINKGREENCD
		rjump BLINKGREENC
BLINKGREENCD	pop
		jumps