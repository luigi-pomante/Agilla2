// $Id: LocationUtils.nc,v 1.2 2005/12/19 16:22:38 chien-liang Exp $

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
 * A collection of methods that compare AgillaLocation variables.
 *
 * @author Chien-Liang Fok
 */
module LocationUtils {
	provides interface LocationUtilI;
}
implementation {

	/**
	 * Returns SUCCESS if the specified location is the BCAST address.
	 */
	command error_t LocationUtilI.isBcast(AgillaLocation *l) {

	 if(l->x == BCAST_X && l->y == BCAST_Y) return SUCCESS;
	 else return FAIL;
	}

	/**
	 * Returns SUCCESS if the specified location is the UART address.
	 */
	command error_t LocationUtilI.isUart(AgillaLocation *l) {

	if(l->x == UART_X && l->y == UART_Y) return SUCCESS;
	else return FAIL;
	}
	
	/**
	 * Returns SUCCESS if the two locations are equal, FALSE otherwise.
	 */
	command error_t LocationUtilI.equals(AgillaLocation *l1, AgillaLocation *l2) {

	if(l1->x == l2->x && l1->y == l2->y) return SUCCESS;
	else return FAIL;
	}

	/**
	 * Returns the (simulated) distance between two locations.
	 */
	command uint16_t LocationUtilI.dist(AgillaLocation* l1, AgillaLocation* l2) {
	uint16_t deltaX, deltaY;
	if (l1->x > l2->x)
		deltaX = l1->x - l2->x;
	else
		deltaX = l2->x - l1->x;

	if (l1->y > l2->y)
		deltaY = l1->y - l2->y;
	else
		deltaY = l2->y - l1->y;
	return deltaX*deltaX + deltaY*deltaY;
	}
	
	/**
	 * Returns true if the two locations are grid neighbors, false otherwise.
	 * Two locations are neighbors if their distance is <= 2.
	 */
	command error_t LocationUtilI.isGridNbr(AgillaLocation* l1, AgillaLocation* l2) {

	if(call LocationUtilI.dist(l1, l2) <= 2) return SUCCESS;
	else return FAIL;
	}
}

