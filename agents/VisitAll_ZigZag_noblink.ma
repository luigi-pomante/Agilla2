// Clones itself throughout the network by zig-zagging across
// each row, starting by going left-to-right on row 1.  
// 
// Usage: Inject this agent onto node (0,0).

BEGIN		pushc 0
		setvar 0  // heap[0] = 0, this means the agent is moving right
INIT		pushc 1
		setvar 11 // consider only x coordinate
MAINLOOP        loc
		getvar 0
		pushc 0
		ceq
		rjumpc CHECK_RIGHT
CHECK_LEFT	dec  // top of stack = (x-1,y)
		cisnbr
		rjumpc GO_LEFT // jump to GO_LEFT if there is a left neighbor
		pushc CHECK_UP
		jumps	       // jump to CHECK_UP if no left neighbor
CHECK_RIGHT	inc // top of stack = (x+1,y)
		cisnbr
		rjumpc GO_RIGHT // jump to GO_RIGHT if there is a right neighbor
		pushc CHECK_UP 
		jumps	        // jump to CHECK_UP if no right neighbor		
GO_LEFT         loc
		dec
		sclone
		cpush
		pushc 2
		ceq
		pushc MAINLOOP
		jumpc    // child jumps back to main loop
		pushc BLINKGREEN
		jumps    // parent jumps to blink green		
GO_RIGHT	loc
		inc
		sclone
		cpush
		pushc 2
		ceq
		pushc MAINLOOP
		jumpc    // jump to main loop of child
		pushc BLINKGREEN
		jumps    // blink green after clone
CHECK_UP	pushc 2
		setvar 11  // consider only y coordinate
		loc
		inc
		copy
		cisnbr
		rjumpc GO_UP
		pushc BLINKGREEN  
		jumps   // blink green if no northern neighbor
GO_UP		getvar 0
		pushc 0
		ceq
		rjumpc SET_LEFT
		pushc 0
		setvar 0 // heap[0] = 0 (go right)
		rjump GO_UP2
SET_LEFT	pushc 1
		setvar 0 // heap[0] = 1 (go left)
GO_UP2		sclone
		cpush
		pushc 2
		ceq
		pushc INIT
		jumpc        // child goes to init after moving up
		             // parent goes to BLINKGREEN
BLINKGREEN  	pushc 26
            	putled
            	halt
            	
