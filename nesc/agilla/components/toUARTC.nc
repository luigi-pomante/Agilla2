/*
	Configuration for toUartM module

	Author: Walter Tiberti <wtuniv@gmail.com>
*/
configuration toUARTC
{
	provides
	{
		interface Init as ProvideInit;
		interface WtUartInterface;
	}
}
implementation
{
	components toUARTM;
	components SerialActiveMessageC;
	components new SerialAMSenderC( AM_SERIAL_PACKET ) as Serial;
	components new TimerMilliC() as Timer;
	toUARTM.SerialPacket -> Serial;
	toUARTM.SerialAMPacket -> Serial;
	toUARTM.SerialSend -> Serial;
	toUARTM.SerialControl -> SerialActiveMessageC;
	ProvideInit = toUARTM.ProvideInit;
	WtUartInterface = toUARTM.WtUartInterface;
	toUARTM.Timer -> Timer;
}
