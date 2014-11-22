BEGIN		pushc temperature
		sense			// take a temperature reading
		pushn tmp
		pushc 2			// 2 fields in tuple
		out			// out(<"tmp", temperature>)
		pushc 8
		sleep			// sleep for 1s
		rjump BEGIN		// repeat
