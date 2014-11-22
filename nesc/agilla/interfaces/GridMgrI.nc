// $Id: GridMgrI.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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
 * Enforces a multi-hop grid layout for the sensor
 * network by determining which neighbors a mote
 * can receive a message from.
 */
interface GridMgrI {

	/**
	 * Updates the current location based on the TOS_LOCAL_ADDRESS
	 * and the list of possible neighbor addresses.	This should be called
	 * during init() and each time TOS_LOCAL_ADDRESS is changed.
	 */
	//command result_t updateNbrList();
	
	/**
	 * This is signalled whenever the location is changed, meaning
	 * the node has a new set of possible neighbors.
	 */
	event error_t locChanged();

	/**
	 * Returns SUCCESS if the specified location
	 * is a possible neighbor.	This is used to drop
	 * messaged received from nodes that are supposed to be
	 * multiple hops away.
	 */
	command error_t isPossibleNbr(AgillaLocation loc);

	/**
	 * Converts an address to a location.
	 *
	 * @param addr The address.
	 * @param loc The location.
	 */
	command error_t addr2Loc(uint16_t addr, AgillaLocation* loc);
	
	/**
	 * Converts a location to an address.
	 *
	 * @param loc The location to convert.
	 * @return The corresponding address.
	 */
	command error_t loc2addr(AgillaLocation* loc, uint16_t* addr);
	
	/**
	 * Returns a pointer to the location of this mote.
	 */
	command AgillaLocation* getLoc();

	/**
	 * Returns the location of the ith potential neighbor, where i is
	 * between 0 and numNbrs().
	 */
	command error_t getPosNbr(uint16_t i, AgillaLocation* loc);

	/**
	 * Returns the number of possible neighbors.
	 */
	command error_t numPosNbrs(uint16_t* numPosNbr);
}
