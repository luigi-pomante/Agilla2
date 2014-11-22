configuration OPcleartsC
{
	provides interface BytecodeI;
}

implementation
{
	components OPcleartsM;
	components TupleSpaceC;
	components TupleUtilC;
	components ErrorMgrProxy;

	BytecodeI = OPcleartsM;
	OPcleartsM.TupleSpaceI -> TupleSpaceC;
	OPcleartsM.TupleUtilI -> TupleUtilC;
	OPcleartsM.Error -> ErrorMgrProxy;
}

