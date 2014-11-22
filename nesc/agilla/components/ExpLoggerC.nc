#include "ExpLogger.h"

configuration ExpLoggerC
{
	provides {
	interface ExpLoggerI;
	}
}
implementation
{
	components Main, ExpLoggerM, NetworkInterfaceProxy, MessageBufferM, SimpleTime;

	ExpLoggerI = ExpLoggerM;

	Main.StdControl -> ExpLoggerM;
	Main.StdControl -> MessageBufferM;
	Main.StdControl -> SimpleTime;

	ExpLoggerM.SendResults -> NetworkInterfaceProxy.SendMsg[AM_AGILLAEXPRESULTSMSG];
	ExpLoggerM.SendLatency -> NetworkInterfaceProxy.SendMsg[AM_AGILLAEXPLATENCYMSG];
	ExpLoggerM.SendTrace -> NetworkInterfaceProxy.SendMsg[AM_AGILLATRACEMSG];
	ExpLoggerM.SendGetAgentsResultsTrace -> NetworkInterfaceProxy.SendMsg[AM_AGILLATRACEGETAGENTSMSG];
	//ExpLoggerM.ReceiveQuery -> NetworkInterfaceProxy.ReceiveMsg[AM_AGILLAEXPQUERYRESULTSMSG];	
	ExpLoggerM.MessageBufferI -> MessageBufferM;
	ExpLoggerM.Time -> SimpleTime;
}
