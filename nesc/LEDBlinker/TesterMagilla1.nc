module TesterM {
  provides interface StdControl;
  uses {
    interface Timer;
    interface LEDBlinkerI;
  }
}
implementation {
  command result_t StdControl.init() {
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Timer.start(TIMER_ONE_SHOT, 3*1024);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
    
  event result_t Timer.fired() {
    call LEDBlinkerI.blink(RED | GREEN, 2, 128);  
    call Timer.start(TIMER_ONE_SHOT, 3*1024);
    return SUCCESS;
  }
  
  event result_t LEDBlinkerI.blinkDone() {
    return SUCCESS;
  }
}
