configuration OPbatteryC
{
	provides interface BytecodeI;
}

implementation
{
	components MainC;
	components OPbatteryM, OpStackC, TupleUtilC;
	components new VoltageC() as Voltage;
	components AgentMgrC;
	components QueueProxy, ErrorMgrProxy;

	MainC.SoftwareInit -> OPbatteryM.Init;
	BytecodeI = OPbatteryM;
	OPbatteryM.AgentMgrI -> AgentMgrC;
	OPbatteryM.OpStackI -> OpStackC;
	OPbatteryM.TupleUtilI -> TupleUtilC;
	OPbatteryM.Error -> ErrorMgrProxy;
	OPbatteryM.Voltage -> Voltage;
	OPbatteryM.QueueI -> QueueProxy;
}

