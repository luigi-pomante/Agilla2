configuration OPmorseC
{
	provides
	{
		interface BytecodeI;
	}
}

implementation
{
	components OPmorseM;
	components OpStackC;
	components ErrorMgrProxy;
	components BusyWaitMicroC;

	BytecodeI = OPmorseM;
	OPmorseM.OpStackI -> OpStackC;
	OPmorseM.Error -> ErrorMgrProxy;
	OPmorseM.BW -> BusyWaitMicroC;

#ifdef MORSE_LED_TEST
	components LedsC;
	OPmorseM.Leds -> LedsC;
#endif
}
