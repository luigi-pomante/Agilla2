includes SpaceLocalizer;

/**
 * Maintains a list of spaces within range and the distances to each.
 * Monitors which space is closest and signals a SpaceLocalizerI event
 * when the closest space changes.  The event contains the name of the
 * space that is now closest.
 *
 * See SpaceLocalizerM.nc for implementation.
 *
 * @author Chien-Liang Fok
 */
configuration SpaceLocalizerC {
  provides {
    interface SpaceLocalizerI;
  }
}
implementation {
  components Main, SpaceLocalizerM, TimerC, HPLUARTC;
  
  components LedsC as LEDs;
  //components NoLeds as LEDs;
  
  components SerialM as Serial;
  //components FakeSerialC as Serial;
  
  //components GenericComm as Comm; // debug
  
  Main.StdControl -> SpaceLocalizerM;
  Main.StdControl -> TimerC;
  //Main.StdControl -> Comm; // debug
  
  SpaceLocalizerI = SpaceLocalizerM;
  
  Serial.HPLUART -> HPLUARTC;
  Serial.Leds -> LEDs;  
  
  SpaceLocalizerM.Serial -> Serial;
  SpaceLocalizerM.Leds -> LEDs;
  SpaceLocalizerM.AgeTimer -> TimerC.Timer[unique("Timer")];
  
  //SpaceLocalizerM.SendMsg -> Comm.SendMsg[2]; // debug
}


