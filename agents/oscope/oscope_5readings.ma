BEGIN		pushc 26
		putled 		   // toggle green LED		
		pushc 0
		setvar 0           // heap[0] = 0
LOOP		getvar 0		
		pushc 5
		ceq
		rjumpc SENDTUPLE   // jump to SENDTUPLE if took 5 temperature readings
		pushc accelx
		sense		   // take a temperature reading		
		getvar 0
		inc
		setvar 0           // increment the counter stored in heap[0]
		pushc 25
		putled             // toggle the red LED
		pushc 1
		sleep
		rjumpc LOOP      
SENDTUPLE	pushc 5   
		pushloc UART_X UART_Y         
		rout               // OUT a tuple containing 5 temperature readings to (0,0)
		pushc BEGIN
		jumps
