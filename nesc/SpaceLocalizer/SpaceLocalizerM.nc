
/**
 * Maintains a list of spaces within range and the distances to each.
 * Monitors which space is closest and signals a SpaceLocalizerI event
 * when the closest space changes.  The event contains the name of the
 * space that is now closest.
 *
 * Some parameters that can be modified include:
 *   AGE_TIMER_PERIOD - The maximum time a space will remain in the list
 *                      before it is removed. (default 5000ms)
 *   NUM_SPACES       - The maximum number of spaces to monitor 
 *                      simultaneously. (default: 2)
 *   NAME_SIZE        - The maximum number of characters in a space's name.
 *                      (default: 8)
 *
 * @author Chien-Liang Fok
 */
module SpaceLocalizerM {
  provides {
    interface StdControl;
    interface SpaceLocalizerI;
  } 
  uses {
    interface Timer as AgeTimer;  // for timming out old spaces
    interface Serial;
    interface Leds;
    
    //interface SendMsg;  // debug
  }
}

// user-customizable definitions
#define AGE_TIMER_PERIOD 5000
#define NUM_SPACES 2
#define NAME_SIZE 8

// non-customizable definitions (do not modify!)
#define EMPTY  0x01
#define OLD  0x02
#define NILL 255


implementation {
  #define DEBUG_SPACE_LOCALIZER 0
  
  //TOS_Msg _msg; // debug
  //bool sending; // debug
  
  /* Info about spaces in the vicinity */
  struct SpaceInfo {
    char name[NAME_SIZE];
    uint8_t status;
    uint16_t dist;
  };  
  struct SpaceInfo spaces[NUM_SPACES];
  
  // The index of the closest space
  uint8_t closest;
  
  /* Removes the entry at the specified index.*/
  void clear_space(uint8_t i) {
    #if DEBUG_SPACE_LOCALIZER
      dbg(DBG_USR1, "SpaceLocalizerM: clear_space(%i), name = %s.\n", i, spaces[i].name);
    #endif  
    memset(spaces[i].name, 0, NAME_SIZE);
    spaces[i].status = EMPTY;
  }
  
  /* Retrieve the space with the specified name. 
     Return the index of the space, or NILL
     if not found.*/
  uint8_t find_space(uint8_t* n, size_t len) {
    uint8_t i;
    for (i = 0; i < NUM_SPACES; i++) {
      if (!(spaces[i].status & EMPTY) &&
          strncmp(spaces[i].name, n, len) == 0)
        return i;
    }
    return NILL;
  }
  
  /* Retrives the space with the specified name.  If no
     entry is found, allocate a position for it.  Return
     the index of the entry. If no position is available
     return NILL*/
  uint8_t get_space(uint8_t* n, size_t len) {
    uint8_t result = find_space(n, len);
    if (result != NILL)
      return result;
    else {
      uint8_t i;
      for (i = 0; i < NUM_SPACES; i++) {
        if (spaces[i].status & EMPTY) {
          strncpy(spaces[i].name, n, len);
          spaces[i].status &= ~EMPTY; // set EMPTY bit = 0
          return i;
        }
      }
      return NILL;
    }
  }    
  
  /* Finds the nearest space and saves its index in frame variable closest.
     Returns SUCCESS if a new closer space is found, FAIL otherwise.*/
  void updateClosest() {
    uint8_t i;
    result_t foundCloser = FAIL;
    if (closest == NILL) {  // first time called
      for (i = 0; i < NUM_SPACES; i++) {
        /*#if DEBUG_SPACE_LOCALIZER
          dbg(DBG_USR1, "SpaceLocalizerM: updateClosest(): spaces[%i].status = %i.\n", i, spaces[i].status);
          dbg(DBG_USR1, "SpaceLocalizerM: updateClosest(): spaces[%i].status & EMPTY = %i.\n", i, (spaces[i].status & EMPTY));
          dbg(DBG_USR1, "SpaceLocalizerM: updateClosest(): !(spaces[%i].status & EMPTY) = %i.\n", i, !(spaces[i].status & EMPTY));
        #endif*/
        if (!(spaces[i].status & EMPTY)) {
          closest = i;
          foundCloser = SUCCESS;      
        }
      }
      for (i = 0; i < NUM_SPACES; i++) {
        if (!(spaces[i].status & EMPTY) && spaces[closest].dist > spaces[i].dist) {
          closest = i;
          
        }
      }       
    } else {  // not first time called
      for (i = 0; i < NUM_SPACES; i++) {
        if (!(spaces[i].status & EMPTY) && spaces[closest].dist > spaces[i].dist) {
          closest = i;
          foundCloser = SUCCESS;
        }
      }       
    }
    if (foundCloser) {
      #if DEBUG_SPACE_LOCALIZER
        dbg(DBG_USR1, "SpaceLocalizerM: updateClosest(): signalling event %s.\n", spaces[closest].name);
      #endif      
      signal SpaceLocalizerI.moved(spaces[closest].name);
    }
  }
  
  command result_t StdControl.init() {
    uint8_t i;
    for (i = 0; i < NUM_SPACES; i++) {
      clear_space(i);
    }
    closest = NILL;
    //sending = FALSE;
    call Leds.init();  // InitLeds    
    call Serial.SetStdoutSerial();  // Init serial port
    
    return SUCCESS;
  }
  
  command result_t StdControl.start() {
    call AgeTimer.start(TIMER_REPEAT, AGE_TIMER_PERIOD);    
    return SUCCESS;
  }
  
  command result_t StdControl.stop() {
    return SUCCESS;
  }
  
  /**
   * Whenever a serial event occurs, extract the space's name
   * and distance and save it in the spaces buffer.  Also
   * check whether the closest space has changed.
   */
  event result_t Serial.Receive(char* buf, uint8_t len) {
    const char* pos;
    char tmp[128], sp[NAME_SIZE];
    char* pos1;
    char* pos2;
    uint16_t dist;          
    
    // save buf into the tmp buffer
    strncpy(tmp, buf, len);
    pos = tmp;

// debug
/*call Leds.yellowToggle();
strncpy(_msg.data, buf, len);                   
if (! sending) {
  if (call SendMsg.send(TOS_BCAST_ADDR, len, &_msg)) {  
    call Leds.greenToggle();
    sending = TRUE;
  }
}*/  
    memset(&sp, 0, NAME_SIZE);   // clear the string

    // Parse out the distance to the space
    // Use the space buffer to temporarily hold the distance in ASCII format
    pos1 = strstr(pos, "DB");         // find "DB"    
    if (!pos1) return FAIL;

    pos2 = strchr(pos1, ',');         // find ',' after "DB"
    if (!pos2 || pos2 - pos1 < 4) return FAIL;    
    
    dist = atoi(strncpy(sp, pos1+3, pos2-pos1-3)); // find the distance
    memset(&sp, 0, NAME_SIZE);  // clear the string
    
    // Parse out the space name
    pos1 = strstr(pos, "SP");         // find "SP"    
    if (!pos1) return FAIL;
    pos2 = strchr(pos1, ',');         // find ',' after "SP"
    if (!pos2 || pos2 - pos1 < 4) return FAIL;
    strncpy(sp, pos1+3, pos2-pos1-3); // save the space name
            
    #if DEBUG_SPACE_LOCALIZER
      dbg(DBG_USR1, "SpaceLocalizerM: space = %s, distance = %i\n", sp, dist);
    #endif    
    if (dist != 0) {
      uint8_t i = get_space(sp, strlen(sp));
      if (i != NILL) {
        spaces[i].dist = dist;
        spaces[i].status &= ~OLD; // set OLD bit = 0       
        updateClosest();              
      } else {
        #if DEBUG_SPACE_LOCALIZER
          dbg(DBG_USR1, "SpaceLocalizerM: could not get space.\n", sp, dist);
        #endif      
      }
    }    
    return SUCCESS;
  }
  
  /**
   * Remove any spaces that are expired (Haven't heard from since
   * the last time this timer fired.
   */
  event result_t AgeTimer.fired() {
    uint8_t i;
    for (i = 0; i < NUM_SPACES; i++) {
      if (!(spaces[i].status & EMPTY)) {
        if(spaces[i].status & OLD)
          clear_space(i);  // remove old entries
        else
          spaces[i].status |= OLD;  // set OLD bit = 1
      }
    }
    return SUCCESS;
  }  
  
  default event void SpaceLocalizerI.moved(char* spaceID) {    
  }
  
  /*event result_t SendMsg.sendDone(TOS_MsgPtr msg, result_t success) {
    sending = FALSE;
    return SUCCESS;
  }*/  
}

