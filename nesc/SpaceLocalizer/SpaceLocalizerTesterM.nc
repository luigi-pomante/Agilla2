/**
 * Tests the SpaceLocalizer.  Listens for events generated by it.
 *
 * @author Chien-Liang Fok
 */
module SpaceLocalizerTesterM {
  provides {
    interface StdControl;
  }
  uses {
    interface SpaceLocalizerI;
    interface SendMsg;
    interface Leds;
    interface CC1000Control;
    interface StdControl as RadioControl;
  }
}
implementation {
  TOS_Msg _msg;
  char* dock = "dock";
  char* ship = "ship";
  
  command result_t StdControl.init() { 
    call Leds.init();
    call RadioControl.init();
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call RadioControl.start();
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    call RadioControl.stop();
    return SUCCESS;
  }

  /**
   * This event is generated whenever the closest
   * cricket beacon mote changes.  It passes the
   * name of the new closest space.
   */      
  event void SpaceLocalizerI.moved(char* spaceID) {     
    uint32_t freq;
    call RadioControl.stop();
    if (strcmp(dock, spaceID) == 0) {
      freq = call CC1000Control.TuneManual(CC1000_CHANNEL_2);
       if (freq != CC1000_CHANNEL_2)
         call Leds.yellowToggle();
    } else  {
      freq = call CC1000Control.TuneManual(CC1000_CHANNEL_4);
       if (freq != CC1000_CHANNEL_4)
         call Leds.yellowToggle();      
    }
    call RadioControl.start();

    dbg(DBG_USR1, "SpaceLocalizerTesterM: New Space!!  %s\n", spaceID);
    strncpy(_msg.data, spaceID, strlen(spaceID));
    call SendMsg.send(TOS_BCAST_ADDR, strlen(spaceID), &_msg);
    call Leds.redToggle();
  }
  
  event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    return SUCCESS;
  }
}


