
  /**
   *
   *
   */
  inline void determineCluster(TOS_MsgPtr m)
  {
    int8_t i = 0, pos = -1;
    uint16_t hopsToGW;  // the number of hops to the gateway
    uint16_t nbrToGW;   // the neighbor closest to the gateway
    uint16_t nbrId;
    tos_time_t now = call Time.get();

    AgillaBeaconMsg* bmsg = (AgillaBeaconMsg *)m->data;
      
    // Get the neighbor that is closest to the basestation and the number
    // of hops it is from the basestation. 
    hopsToGW = call NeighborListI.getGW(&nbrToGW);
            
    if(hopsToGW != NO_GW)  // if a gateway is known
    {
      hopsToGW++; // add one hop to get to the neighbor

      #if DEBUG_CLUSTERING
      //dbg(DBG_USR1, "NeighborListM:determineCluster: hopsToGW=%i\n", hopsToGW);
      #endif
            
      // If this node is the gateway, and the clusterhead is unknown, 
      // set this node to be a cluster head.
      //if(hopsToGW == 1 && _chId != addr) 
      if (nbrToGW == TOS_LOCAL_ADDRESS && _chId != TOS_LOCAL_ADDRESS)
        setCH(nbrToGW);      
      
      else if(_chId == NO_CLUSTERHEAD) 
      {
        // This node is not a gateway and the clusterhead has not been set.
        
        // If the beacon is from a clusterhead, set the cluster head to
        // be the node who sent the beacon
        if (bmsg->id == bmsg->chId) 
          setCH(bmsg->id);        
        
        // If the beacon is NOT from a clusterhead and the number of hops to 
        // the gateway is even, declare self to be a cluster head.
        else if(hopsToGW % 2 == 0) 
          setCH(TOS_LOCAL_ADDRESS);
        
        // If the beacon is NOT from a clusterhead and the number of hops to
        // the gateway is NOT even...
        else if((now.low32 - initTime.low32) > 5*(BEACON_PERIOD+BEACON_RAND))
        {
            // if the node has not heard from a clusterhead in a long time
            // it should become a clusterhead
            setCH(TOS_LOCAL_ADDRESS);
        }
      }
      
      else if(_chId != TOS_LOCAL_ADDRESS)
      {
        // This node is not a gateway, or clusterhead

        // Check if it should join some other cluster
        // The node should change its clusterhead if it has
        // not heard from its current cluster head in time T
        // OR if the difference in the link quality of the
        // node sending the beacon is more than a threshold
        // OR if its clusterhead is no more a clusterhead

        i = 0;
        pos = -1;
        
        // Find the index of the neighbor that is the cluster head.
        // Store the index in variable "pos"
        while (i < numNbrs && pos == -1) 
        {
          if (nbrs[i].addr == _chId && nbrs[i].addr == nbrs[i].chId)
            pos = i;
          i++;
        }

        /*if(bmsg->id == bmsg->chId && pos != -1 && ((m->lqi - nbrs[pos].linkQuality) > 20)){
              setCH(bmsg->id);
        } else */
        
        
        if(pos == -1 || ((now.low32 - nbrs[pos].timeStamp.low32 ) > 5*(BEACON_PERIOD+BEACON_RAND)))
        {
            // if clusterhead entry not found
            // or if not heard from clusterhead for a while
            // or link quality of neighbor is much better
            // than link quality of current cluster head
            // set neighbor as cluster head
            nbrId = TOS_LOCAL_ADDRESS;
            i = 0;
            while (i < numNbrs && nbrId == TOS_LOCAL_ADDRESS) {
                if (nbrs[i].addr != _chId && nbrs[i].addr == nbrs[i].chId &&
                      ((now.low32 - nbrs[i].timeStamp.low32 ) <= 2*(BEACON_PERIOD+BEACON_RAND)))
                      nbrId = nbrs[i].addr;
                i++;
            }
            setCH(nbrId);
        }
        
      } 
      else 
      {
        // this node is a clusterhead

        #if DEBUG_CLUSTERING
          //dbg(DBG_USR1, "[%i] NeighborListM:determineCluster: Number of clustermembers = %i\n", now.low32, call CHDir.numClusterMembers());
          //dbg(DBG_USR1, "[%i] NeighborListM:determineCluster: chSelectTime = %i, 3*(BEACON_PERIOD+BEACON_RAND) = %i\n",
          //                                 now.low32, chSelectTime.low32, 3*(BEACON_PERIOD+BEACON_RAND));
        #endif
        
        // if after a time period, I see that I don't have any cluster members
        // I should stop being a clusterhead and join the neighbor that is one
        if(bmsg->id == bmsg->chId && call CHDir.numClusterMembers() == 0 &&
            (now.low32 - chSelectTime.low32) > 3*(BEACON_PERIOD+BEACON_RAND))
        {
            // check if there is a clusterhead closer to the GW than
            // the node sending the beacon msg
            // find a neighbor that is a clusterhead and from whom
            // this node has heard from recently, and join its cluster

            setCH(bmsg->id);

            /*
            // commenting this off, to save space
            pos = -1;
            i = 0;
            while (i < numNbrs && pos == -1) {
               if (nbrs[i].addr == nbrs[i].chId &&
                      ((now.low32 - nbrs[i].timeStamp.low32 ) <= 2*(BEACON_PERIOD+BEACON_RAND))){
                      pos = i;
               }
               i++;
            }
            if(pos != -1) setCH(nbrs[pos].addr);
            */
            #if DEBUG_CLUSTERING
            //dbg(DBG_USR1, "NeighborListM:determineCluster: pos = %i\n", pos);
            //dbg(DBG_USR1, "NeighborListM:determineCluster: 2*(BEACON_PERIOD+BEACON_RAND) = %i\n", 2*(BEACON_PERIOD+BEACON_RAND));
            #endif

        }
      }

    } else 
    {
      // There is no known gateway.  Set the current clusterhead to be -1.
      if(_chId != -1) setCH(-1);
    }
          //for DEBUGGING/////////////////
          //#if DEBUG_CLUSTERING
            //dbg(DBG_USR1, "NeighborListM:determineCluster: current cluster head is %i\n", chId);
            //printNbrList();
            // this is needed if reset msg sent

         // #endif
          ///////////////////////////
  } // end determineCluster
