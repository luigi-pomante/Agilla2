configuration TesterC {
}
implementation {
  components Main, TesterM, LEDBlinkerC, TimerC;
  
  Main.StdControl -> TesterM;
  Main.StdControl -> LEDBlinkerC;
  
  TesterM.LEDBlinkerI -> LEDBlinkerC;
  TesterM.Timer -> TimerC.Timer[unique("Timer")];
}
