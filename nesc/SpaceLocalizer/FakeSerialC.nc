/**
 * Generates fake serial data for the SpaceLocalizer.
 *
 * @author Chien-Liang Fok
 */
configuration FakeSerialC {
  provides interface Serial;
  uses {
    interface HPLUART;
    interface Leds;
   }
}

implementation {
  components Main, FakeSerialM, TimerC;
  
  Main.StdControl -> TimerC;
  Main.StdControl -> FakeSerialM;
  
  Serial = FakeSerialM;
  
  HPLUART = FakeSerialM;
  Leds = FakeSerialM;
  
  FakeSerialM.Timer -> TimerC.Timer[unique("Timer")];  
}

