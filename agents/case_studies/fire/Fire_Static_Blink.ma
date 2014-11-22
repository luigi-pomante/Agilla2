// inject this onto mote 18
BEGIN		pushn fir
		pushc 1
		out
BLINKRED   	pushc 25
            	putled
            	pushc 1
            	sleep            
            	rjump BLINKRED		
