BEGIN       pushc RETURN
            pushc 6
            pushcl BLINKGREENC
            jumps
RETURN      pushcl 123
            setvar 0               // put 123            into heap[0]
            pushn abc
            setvar 1               // put "abc"          into heap[1]
            pushloc uart_x uart_y
            setvar 2               // put location       into heap[2]
            aid          
            setvar 3               // put AgentID        into heap[3]
            pusht value
            setvar 4               // put template:value into heap[4]
            pushcl 789
            pushrt photo
            pushn lol
            pushc 3
            pushcl BLINKGREENC
            regrxn   // register rxn w/ template [string:lol, reading=photo, value=789]
            pushcl 456      // push 456                  onto stack
            pushn xyz       // push "xyz"                onto stack 
            aid             // push AgentID              onto stack 
            pusht string    // push type:string          onto stack 
            pushrt accelx   // push reading type: accelx onto stack
            addr            // push address              onto stack   
            pushloc uart_x uart_y
            smove        // smove to base station
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
		
