BEGIN       pushc RETURN
            pushc 6
            rjump BLINKGREENC
RETURN      pushloc uart_x uart_y

            wmove
            halt

// Blinks the green LED a certain number of times, as specified by the
// value on top of the stack. 
//
// Opstack Parameters: [val=#blinks][return address]				        	
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
		