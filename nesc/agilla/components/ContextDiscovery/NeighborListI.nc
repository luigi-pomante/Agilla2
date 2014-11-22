// $Id: NeighborListI.nc,v 1.6 2006/04/25 22:27:38 chien-liang Exp $

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
 * The context manager is responsible for keeping track
 * of the current location of the mote, and the locations
 * of each neighbor.	It provides methods for obtaining
 * the location of the neighbors, and the location of this mote.
 *
 * @author Chien-Liang Fok
 */
interface NeighborListI {

	/**
	 * Returns SUCCESS if the specified neighbor is present.
	 */
	command error_t isNeighbor(uint16_t nbr);

	/**
	 * Returns the number of neighbors.
	 */
	command uint16_t numNeighbors();

	/**
	 * Fetches the address of the specified neighbor.
	 * Returns SUCCESS if such a neighbor exists, and
	 * FALSE otherwise.
	 */
	command error_t getNeighbor(uint16_t i, uint16_t* nbr);

	/**
	 * Fetches the address of a random neighbor.	If no neighbors are
	 * present, return FAIL.
	 */
	command error_t getRandomNeighbor(uint16_t *nbr);


	#if ENABLE_GRID_ROUTING
	/**
	 * Fetches the address of the closest neighbor to which an agent
	 * should be forwarded to.	Saves the results in the location
	 * specified by the nbr parameter.
	 *
	 * @return SUCCESS if a neighbor was found.
	 */
	command error_t getClosestNeighbor(uint16_t *nbr);
	#endif

	/**
	 * Retrieves the address of the closest gateway, or neighbor closest
	 * to the gateway.	If no gateway or neighbor is close to a gateway,
	 * return FAIL.	Otherwise, the address is stored in the parameter.
	 *
	 * @param addr A pointer to store the results.
	 * @return The minimum number of hops to the gateway, or NO_GW (0xffff) if no
	 * gateway is known.
	 */
	command uint16_t getGW(uint16_t* addr);




}
