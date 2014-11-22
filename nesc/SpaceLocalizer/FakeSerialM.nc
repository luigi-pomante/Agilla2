
/**
 * Generates fake serial data for the SpaceLocalizer.
 *
 * @author Chien-Liang Fok
 */
module FakeSerialM {
  provides {
    interface Serial;
    interface StdControl;
  }
  uses {
    interface Timer;
    interface HPLUART;
    interface Leds;    
  }
}

implementation {
  #define NUM_SAMPLES 75
  uint16_t count;
  
  command result_t StdControl.init() { 
    count = 0;
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call Timer.start(TIMER_REPEAT, 1024);
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  event result_t Timer.fired() {
    char* ts[] = {"VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=55,DR=1676,TM=2034,TS=22528",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=56,DR=1683,TM=1897,TS=5126208",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=56,DR=1684,TM=2138,TS=5127040",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=78,DR=2354,TM=2568,TS=5127456",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=58,DR=1757,TM=2211,TS=5128352",                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=82,DR=2470,TM=2",                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=64,DR=1934,TM=2340,TS=5129088",                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=82,DR=2484,TM=2938,TS=5129600",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=64,DR=1943,TM=2253,TS=5129856",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=65,DR=1951,TM=2453,TS=5130688",                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=73,DR=2211,TM=2425,TS=5130816",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=69,DR=2079,TM=2581,TS=5131680"                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,TS=5132096",                                                    
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=91,DR=2751,TM=3205,TS=5132576",                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=45,DR=1350,TM=1612,TS=5133472",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=109,DR=3288,TM=3742,TS=5133888",                                                                           
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=42,DR=1284,TM=1594,TS=5134432",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=110,DR=3320,TM=3534,TS=5134944",                                                                           
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=42,DR=1289,TM=1599,TS=5135328",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=110,DR=3306,TM=371",                                                              
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=42,DR=1278,TM=1540,TS=5136672",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=106,DR=3187,TM=3545,TS=5137280",                                                                           
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=41,DR=1257,TM=1759,TS=5137952",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=85,DR=2561,TM=2919,TS=5138400",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=67,DR=2035,TM=2441,TS=5139136",                                                                          
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=67,DR=2017,TM=2519,TS=5139296 ",                                                                         
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=88,DR=2651,TM=2865,           ",                                                    
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=47,DR=1431,TM=1981,TS=5140480  ",                                                                        
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=107,DR=3213,TM=3667,TS=5141184 ",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=47,DR=1414,TM=1724,TS=5141344  ",                                                                        
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=46,DR=1404,TM=1762,TS=5142144  ",                                                                        
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=101,DR=3033,TM=3391,TS=5142464 ",                                                                          
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=47,DR=1415,TM=1677,TS=5142912  ",                                                                        
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=102,DR=3084,TM=349             ",                                                 
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=46,DR=1401,TM=1951,TS=5143808    ",                                                                      
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=105,DR=3156,TM=3706,TS=5144544   ",                                                                        
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=47,DR=1415,TM=1725,TS=5145152    ",                                                                      
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=98,DR=2962,TM=3416,TS=5145696    ",                                                                      
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=46,DR=1380,TM=1738,TS=5145920    ",                                                                      
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=52,DR=1572,TM=2074,TS=5146880    ",                                                                      
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=80,DR=2404,TM=2714,              ",                                                 
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=36,DR=1084,TM=1490,TS=5148000006 ",                                                                      
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=105,DR=3159,TM=3469,TS=5148288   ",                          
                  "VR=2.0,ID=01:9f:61:61:0b:00:00:04,SP=mobilab0",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=35,DR=1079,TM=1629,TS=5148928    ",                                  
                  "VR=2.0,ID=01:a6:61:61:0b:00:00:77,S",
                  "VR=2.0,ID=01:a6:61:61:0b:00:00:77,SP=",
                  "VR=2.0,ID=01:a6:61:61:0b:00:00:77,SP",
                  "VR=2.0,ID=01:a6:61:61:0b:00:00:77,SP=,DB=",
                  "VR=2.0,ID=01:a6:61:61:0b:00:00:77,DB",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=111,DR=3342,TM=3796,TS=5149472   ",        
                  "VR=2.0,       ",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=111,DR=3353,TM=3615,TS=5151232",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=37,DR=1127,TM=1629,TS=5151840",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=111,DR=3353,TM=3663,TS=5152448",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=36,DR=1102,TM=1412,TS=5153056",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=33,DR=1012,TM=1418,TS=5153760",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=101,DR=3059,TM=3561,TS=5153888",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=41,DR=1241,TM=1791,TS=5154944",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=79,DR=2384,TM=2742,TS=5155072",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=61,DR=1854,TM=2308,TS=5156000",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=60,DR=1829,TM=2379,TS=5156160",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=83,DR=2509,TM=2723,TS=5156896",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=50,DR=1509,TM=1867,TS=5157312",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=106,DR=3202,TM=3464,TS=5158240",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=51,DR=1539,TM=1993,TS=5158464",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=105,DR=3175,TM=3581,TS=5159392",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=50,DR=1509,TM=1915,TS=5159552",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=104,DR=3136,TM=3638,TS=5160384",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=50,DR=1519,TM=1877,TS=5160544",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=51,DR=1544,TM=1902,TS=5161440",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=81,DR=2439,TM=2989,TS=5161664",
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=73,DR=2201,TM=2415,TS=5162336",
                  "VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=57,DR=1724,TM=1986,TS=5162528",                  
                  "VR=2.0,ID=01:4c:61:61:0b:00:00:1f,SP=dock,DB=73,DR=2219,TM=2673,TS=5163008"};
    
    //dbg(DBG_USR1, "FakeSerialM: Signaling Serial.Receive()\n");
    //signal Serial.Receive("VR=2.0,ID=01:25:61:61:0b:00:00:42,SP=ship,DB=55,DR=1676,TM=2034,TS=22528\n", 74);
    if (count < NUM_SAMPLES) {
      signal Serial.Receive(ts[count], strlen(ts[count]));
      count++;
    }
    return SUCCESS;
  }
  
  command result_t Serial.SetStdoutSerial() {
    return SUCCESS;
  }
  
  default event result_t Serial.Receive(char* buf, uint8_t len) {
    return SUCCESS;
  }  
  
  /**
   * A byte of data has been received.
   *
   * @return SUCCESS always.
   */  
  async event result_t HPLUART.get(uint8_t data) {
    return SUCCESS;
  }

  /**
   * The previous call to <code>put</code> has completed; another byte
   * may now be sent.
   *
   * @return SUCCESS always.
   */
  async event result_t HPLUART.putDone() {
    return SUCCESS;
  }
}


