// $Id: NeighborListDummy.nc,v 1.5 2006/02/09 17:32:55 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2004, Washington University in Saint Louis 
 * By Chien-Liang Fok.
 * 
 * Washington University states that Agilla is free software; 
 * you can redistribute it and/or modify it under the terms of 
 * the current version of the GNU Lesser General Public License 
 * as published by the Free Software Foundation.
 * 
 * Agilla is distributed in the hope that it will be useful, but 
 * THERE ARE NO WARRANTIES, WHETHER ORAL OR WRITTEN, EXPRESS OR 
 * IMPLIED, INCLUDING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.	
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * INFORMATION GENERATED USING SOFTWARE. By using Agilla you agree to 
 * indemnify, defend, and hold harmless WU, its employees, officers and 
 * agents from any and all claims, costs, or liabilities, including 
 * attorneys fees and court costs at both the trial and appellate levels 
 * for any loss, damage, or injury caused by your actions or actions of 
 * your officers, servants, agents or third parties acting on behalf or 
 * under authorization from you, as a result of using Agilla. 
 *
 * See the GNU Lesser General Public License for more details, which can 
 * be found here: http://www.gnu.org/copyleft/lesser.html
 */
#include "Agilla.h"

/**
 * A dummy neighbor list implementing the bare bones interface.
 *
 * @author Chien-Liang Fok
 */
module NeighborListDummy {
	provides interface NeighborListI;
}
implementation {
	
	/**
	 * Checks whether this node has a neighbor with the specified address.
	 *
	 * @return SUCCESS if the specified location is a neighbor.
	 */
	command error_t NeighborListI.isNeighbor(uint16_t addr) {
	return SUCCESS;
	}

	/**
	 * Returns the number of neighbors.
	 */
	command uint16_t NeighborListI.numNeighbors() {
	return 1;
	}

	/**
	 * Sets the specified AgillaLocation to be the ith
	 * neighbor.	Returns SUCCESS if such a neighbor exists, and
	 * FALSE otherwise.
	 */
	command error_t NeighborListI.getNeighbor(uint16_t i, uint16_t* addr) {
	if (TOS_NODE_ID == 0)
		*addr = 1;		
	else
		*addr = 0;
	return SUCCESS;
	}

	/**
	 * Sets the specified location equal to the location of a randomly chosen
	 * neighbor.	If no neighbors exist, return FAIL.
	 */
	command error_t NeighborListI.getRandomNeighbor(uint16_t* addr) {
	if (TOS_NODE_ID == 0)
		*addr = 1;		
	else
		*addr = 0;
	return SUCCESS;	
	}
	
	/**
	 * Retrieves the address of the gateway node, or the node that is closest
	 * to the gateway node.	The gateway node is attached directly to the
	 * base station.	The address is tored in the pointer passed as a parameter.
	 * 
	 * @param addr A pointer to store the results.
	 * @return The minimum number of hops to the gateway, or NO_GW if no 
	 * gateway is known.
	 */
	command uint8_t NeighborListI.getGW(uint16_t* addr) {
	*addr = 0;
	return 0;
	}
	
	#if ENABLE_GRID_ROUTING
	command error_t NeighborListI.getClosestNeighbor(uint16_t *nbr) { 
	return FAIL;
	}
	#endif
}
