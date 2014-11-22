// Network Configuration:
//   [43] [44]
//   [63] [64] [65]
// Number of Columns = 20
//
// Inject this agent into mote 65

pushc	23
putled
addr
pushcl	1
add
pushcl	20
inv
add
cisnbr
rjumpc	CLONEUPDONE
addr
pushcl	20
inv
add
copy
cisnbr
rjumpc	CLONEUP
rjump	CLONEUPDONE
CLONEUP	wclone
CLONEUPDONE	addr
pushcl	1
inv
add
copy
cisnbr
rjumpc	CLONELEFT
rjump	CLONELEFTDONE
CLONELEFT	wclone
CLONELEFTDONE	clear
pushc	8
putled
halt
