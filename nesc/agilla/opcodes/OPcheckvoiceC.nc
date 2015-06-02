#include <mts300.h>

configuration OPcheckvoiceC
{
	provides interface BytecodeI;
}

implementation
{
	components OPcheckvoiceM;
	components ErrorMgrProxy;
	components new MicStreamC() as mic;

	BytecodeI = OPcheckvoiceM;
	OPcheckvoiceM.Error -> ErrorMgrProxy;
	OPcheckvoiceM.mic -> mic;

	components MainC;
	components OpStackC;
	components AgentMgrC;
	components QueueProxy;

	// for debug purposes
	components LedsC;
	OPcheckvoiceM.Leds -> LedsC;

	MainC.SoftwareInit -> OPcheckvoiceM.Init;
	OPcheckvoiceM.AgentMgrI -> AgentMgrC;
	OPcheckvoiceM.OpStackI -> OpStackC;
	OPcheckvoiceM.Error -> ErrorMgrProxy;
	OPcheckvoiceM.QueueI -> QueueProxy;
}

