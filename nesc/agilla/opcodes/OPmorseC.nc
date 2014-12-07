#include <atm128hardware.h>

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
	components new TimerMilliC() as Timer0;
	components HplAtm128GeneralIOC as Port;

	MainC.SoftwareInit -> OPmorseM.Init;
	OPmorseM.AgentMgrI -> AgentMgrC;
	OPmorseM.QueueI -> QueueProxy;
	BytecodeI = OPmorseM;
	OPmorseM.OpStackI -> OpStackC;
	OPmorseM.Error -> ErrorMgrProxy;
	OPmorseM.GeneralIO -> Port.PortG2;
	OPmorseM.MainTimer -> Timer0;

#ifdef MORSE_LED_TEST
	components LedsC;
	OPmorseM.Leds -> LedsC;
#endif
}
