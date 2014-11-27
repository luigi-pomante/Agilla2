configuration OPmorseC
{
	provides
	{
		interface BytecodeI;
	}
}

implementation
{
	components MainC;
	components AgentMgrC;
	components QueueProxy;
	components OPmorseM;
	components OpStackC;
	components ErrorMgrProxy;
	components BusyWaitMicroC;

	MainC.SoftwareInit -> OPmorseM.Init;
	OPmorseM.AgentMgrI -> AgentMgrC;
	OPmorseM.QueueI -> QueueProxy;
	BytecodeI = OPmorseM;
	OPmorseM.OpStackI -> OpStackC;
	OPmorseM.Error -> ErrorMgrProxy;
	OPmorseM.BW -> BusyWaitMicroC;

#ifdef MORSE_LED_TEST
	components LedsC;
	OPmorseM.Leds -> LedsC;
#endif
}
