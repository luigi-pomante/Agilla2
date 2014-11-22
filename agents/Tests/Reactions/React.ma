BEGIN		pushc 1
		pushc 1
		pushc 2
		pushc GO
		regrxn
		pushc 1
		putled
		wait

GO		remove
		pop
		pop
		pop
		pushc 2
		putled
		endrxn
