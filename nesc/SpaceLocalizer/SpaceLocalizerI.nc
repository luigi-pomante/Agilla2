
/**
 * This is the interface for a component that monitors which 
 * physical space a node is residing in and signals an event 
 * when the space changes.
 *
 * @author Chien-Liang Fok
 */
interface SpaceLocalizerI {
  
  /**
   * This event is generated whenever the closest
   * cricket beacon mote changes.  It passes the
   * name of the new closest space.
   */
  event void moved(char* spaceID);
}

