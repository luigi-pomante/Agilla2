module FakeCC1000RadioC {
  provides {
    interface StdControl;
    interface CC1000Control;
    interface RadioControl;
  }
}
implementation {
  command result_t StdControl.init() { 
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }  

  command result_t CC1000Control.TunePreset(uint8_t freq) {
    return SUCCESS;
  }

  command uint32_t CC1000Control.TuneManual(uint32_t DesiredFreq) {
    return 0;
  }

  async command result_t CC1000Control.TxMode() {
    return SUCCESS;
  }

  async command result_t CC1000Control.RxMode() {
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOff() {
    return SUCCESS;
  }

  command result_t CC1000Control.BIASOn() {
    return SUCCESS;
  }

  command result_t CC1000Control.SetRFPower(uint8_t power) {
    return SUCCESS;
  }

  command uint8_t  CC1000Control.GetRFPower() {
    return 0;
  }

  command result_t CC1000Control.SelectLock(uint8_t LockVal) {
    return SUCCESS;
  }

  command uint8_t  CC1000Control.GetLock() {
    return 0;
  }

  command bool CC1000Control.GetLOStatus() {
    return TRUE;
  }
}

