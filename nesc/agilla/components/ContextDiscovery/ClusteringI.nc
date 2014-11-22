// $Id: ClusteringI.nc,v 1.4 2006/04/25 22:27:38 chien-liang Exp $

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
 * The Clustering algorithm sets up clusters by selecting cluster heads
 * based on a routing tree rooted at the Gateway node. The clustering module
 * maintains cluster information like whether a node is a cluster head and
 * if not, who its cluster head is. It also stores the id of the parent node.
 *
 * @author Sangeeta Bhattacharya
 */
interface ClusteringI {

	/**
	 * Returns SUCCESS if it is a cluster head.
	 */
	command error_t isClusterHead();

	/**
	* Returns SUCCESS if nbr is this nodes cluster head.
	*/
	//command error_t isNbrClusterHead(uint16_t* nbr);

	/**
	 * Returns the id of the cluster head of the cluster to which it belongs.
	 * Returns its own id if it is the cluster head.
	 */
	command error_t getClusterHead(uint16_t* chID);


	/**
	 * Returns the approximate communication range of this node. The communication
	 * range is calculated as the average distance to neighbors.
	 */
	//command uint8_t getCommRange();

	/*
	 * Returns if this node is known to belong to the same cluster.
	 */
	command error_t isClusterMember(uint16_t id);

	#if DEBUG_CLUSTERING
	command void sendClusterDebugMsg();
	#endif


}
