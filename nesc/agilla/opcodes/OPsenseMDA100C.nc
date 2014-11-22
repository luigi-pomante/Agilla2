#include "Agilla.h"
configuration OPsenseMDA100C
{
	provides interface BytecodeI;
}
implementation
{
	components MainC, OPsenseMDA100M as OPsenseM;
	components OpStackC;
	components new PhotoC() as Photo;
	components new TempC() as Temp;
	components AgentMgrC;
	components QueueProxy, ErrorMgrProxy;

	BytecodeI = OPsenseM;
	MainC.SoftwareInit -> OPsenseM.Init;
	OPsenseM.AgentMgrI -> AgentMgrC;
	OPsenseM.OpStackI -> OpStackC;
	OPsenseM.Photo -> Photo;
	OPsenseM.Temp -> Temp;
	OPsenseM.QueueI -> QueueProxy;	
	OPsenseM.ErrorMgrI -> ErrorMgrProxy;
}
