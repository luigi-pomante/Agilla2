// $Id: ClusterheadDirectoryI.nc,v 1.3 2006/04/28 12:54:55 chien-liang Exp $

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
#include "LocationDirectory.h"

/**
 * The Clusterhead Directory interface allows setting and retrieving
 * clusterhead information like the cluster members, bounding box etc.
 *
 * @author Sangeeta Bhattacharya
 */
interface ClusterheadDirectoryI {


	/**
	 * Inserts a cluster member into the directory and updates the bounding box
	 *
	 * @param nbr Id of neighbor who is a clustermember
	 * @param range Communication range of neighbor
	 */
	command error_t addClusterMember(uint16_t nbr/*, uint16_t range*/);


	/**
	 * Removes a cluster member
	 *
	 * @param nbr Id of cluster member which should be removed from the database
	 */
	command error_t removeClusterMember(uint16_t nbr);

	/*
	 * Checks if the specified node is a member of the local cluster.
	 *
	 * @param id The TinyOS address of the node to check
	 * @return SUCCESS if the specified node is a member. 
	 */
	 command error_t isClusterMember(uint16_t id);

	 /*
	* Returns the number of clustermembers that this node has
	*/

	 command uint16_t numClusterMembers();

	/**
	 * Adds an agent to the clusterhead Agent Directory
	 *
	 * @param aid Agent id
	 * @param atype Agent type
	 * @param aloc Agent location
	 * @param timestamp Timestamp at which agent was detected
	 * @param known Indicates if the agent was previously reported (+ve indicates yes, 0 indicates no).
	 */
	command error_t addAgent(uint16_t aid, uint16_t atype, AgillaLocation* aloc, /*tos_time_t* timestamp,*/ uint16_t* known);


	/*
	 * Removes the agent information from the directory
	 */
	command error_t reset();
	/**
	 * Removes an agent from the clusterhead Agent Directory
	 *
	 * @param aid Agent id
	 */
	command error_t removeAgent(AgillaAgentID* aid);

	/**
	* Returns the location of the agent with the specified id.
	* The results are saved in the aLoc pointer.
	* If agent is not known, the operation returns FAIL
	*
	* @param aid Agent id
	* @param aLoc Agent location returned by the method
	 */
	command error_t getAgent(AgillaAgentID* aid, AgillaLocation* aLoc);

	/**
	* Returns the id and location of an agent closest to agent with id "aid" and location "aLoc".
	* If a nearest agent is not found, the operation returns FAIL
	*
	* @param aid Agent id of querying agent
	* @param aLoc Agent location of querying agent
	* @param aType The type of the agent to find.
	* @param nearestAgentId Agent id of nearest agent
	* @param nearestAgentLoc Agent location of nearest agent
	* @return SUCCESS if an agent was found.	The result is saved in nearestAgentId and nearestAgentLoc.
	*/
	command error_t getNearestAgent(AgillaAgentID* aid, AgillaLocation* aLoc, uint16_t* aType,
			AgillaAgentID* nearestAgentId, AgillaLocation* nearestAgentLoc);


	/**
	 * Returns the agent id and location of all agents of a certain type stored in the directory.
	 *
	 * @param agentList Pointer to an array of AgillaLocMAgentInfo structs.
	 *					This struct contains an agent id and location.
	 * @param numAgents Number of agents that are returned in the array
	 * @param aType	 Type of agents being returned
	 * @return SUCCESS	If one or more agents were added to the agentList.
	 */
	command error_t getAllAgents(AgillaLocMAgentInfo* agentList, uint8_t* num_agents, uint16_t* aType);

	#if DEBUG_CLUSTERING
	command error_t getBoundingBox(AgillaRectangle* boundingBox);
	#endif

}
