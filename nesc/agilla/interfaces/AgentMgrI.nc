// $Id: AgentMgrI.nc,v 1.3 2006/02/02 06:59:37 chien-liang Exp $

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
 * Interface to operations that control the execution of Agilla agents.
 *
 * @author Chien-Liang Fok
 */
interface AgentMgrI {

	/**
	 * Start running a non-running agent.
	 *
	 * @param agent The non-running agent to run.
	 */
	command error_t run(AgillaAgentContext* agent);

	/**
	 * Returns an agent context that has partially arrived.	If a context with the
	 * specified ID is already running on this node, return NULL.	If a context
	 * with the specified ID does not exist, choose any available context and
	 * configure it for receiving the incomming agent.	If there is no more room
	 * on this node, return NULL.
	 *
	 * @param id The agent ID of the context holding the incomming agent.
	 */
	command AgillaAgentContext* getIncommingContext(AgillaAgentID* id);

	/**
	 * Allocates and returns a free context for a new agent.	This command
	 * initializes the context's id, integrity, pc, sBlock, codeSize,
	 * numBlocksNeeded, and numBlocksRecvd fields.
	 *
	 * @param id The id of the new agent.
	 * @param codeSize The number of instructions.
	 * @return The context for the agent.
	 */
	command AgillaAgentContext* getFreeContext(AgillaAgentID* id, uint16_t codeSize);

	/**
	 * Returns a context with the specified ID.
	 */
	command AgillaAgentContext* getContext(AgillaAgentID* id);

	/**
	 * Migrate an agent to the destination mote.
	 *
	 * @param context The agent to migrate.
	 * @param dest The the one-hop destination mote.	 
	 * @param final_dest The final destination mote, e.g., TOS_UART_ADDRESS.
	 * @param op The opcode that the agent is executing.
	 */
	command error_t migrate(AgillaAgentContext* context, uint16_t dest, 
	uint16_t final_dest, uint8_t op);

	/**
	 * Resets an agent context.	Frees up the memory for another agent.
	 *
	 * @param agent The agent context to reset.
	 */
	command error_t reset(AgillaAgentContext* context);
	
	/**
	 * Resets all agents running on a mote.
	 */
	command error_t resetAll();
	
	/**
	 * Returns SUCCESS the index of the agent's context 
	 * if the agent is present, -1 otherwise.	 
	 */
	command error_t isPresent(AgillaAgentID* id);

	/**
	 * Returns the number of agents running (or arriving) on this host.
	 */
	command int numAgents();
}
