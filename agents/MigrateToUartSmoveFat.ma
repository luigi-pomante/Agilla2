BEGIN       pushc RETURN
            pushc 6
            pushcl BLINKGREENC
            jumps
RETURN      pushcl 123
            setvar 0     // put 123 into heap[0]
            pushn abc
            setvar 1     // put "abc" into heap[1]
            pushloc uart_x uart_y
            setvar 2     // put location into heap[2]
            aid          
            setvar 3      // put AgentID into heap[3]
            pusht value
            setvar 4      // put value template into heap[4]
            pushrt magx
            setvar 9       
            addr
            setvar 10
            pushc 1
            setvar 11
            pushcl 789
            pushrt photo
            pushn lol
            pushc 3
            pushcl BLINKGREENC
            regrxn        // register a reaction with template [string:lol, reading=photo, value=789]
            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
//            pushc 63     // push stuff onto stack
            pushcl 456   
            pushn xyz     
            aid           
            pusht string  
            pushrt accelx
            addr            
            pushloc uart_x uart_y
            smove        // strong migration to base station
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
		
