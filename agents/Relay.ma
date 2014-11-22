// This agent reacts to tuples and forwards them to the gateway.
// If this is the gateway, it forwards the tuple to the base station.

		pusht VALUE
		pushc 1
		pushc REACT
		regrxn     	// register reaction sensitive to <type:value>
		wait
REACT		inp		// begin reaction
		rjumpc CONT
		endrxn		// the inp failed, abort
CONT		isgw
		rjumpc TOBS	// if this is a gateway, send it to the base station
		getgw		// otherwise get the address of the neighbor closest to the gateway
		rjumpc ROUT
TOBS		pushcl uart
ROUT     	rout
                endrxn