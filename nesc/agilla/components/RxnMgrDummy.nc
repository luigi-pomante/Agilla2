// $Id: RxnMgrDummy.nc,v 1.1 2006/02/06 09:40:39 chien-liang Exp $

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

/**
 * This dummy reaction manager is used to reduce the amount of instruction
 * memory consumed by AGILLA.
 *
 * It is used by setting OMIT_RXN_MGR=1 in Makefile.Agilla.
 */
module RxnMgrDummy {
	provides {
	interface StdControl;
	interface RxnMgrI;
	interface Init;
	}
}
implementation {
	
	command error_t Init.init() {
	return SUCCESS;
	}

	command error_t StdControl.start() {
	return SUCCESS;
	}

	command error_t StdControl.stop() {
	return SUCCESS;
	}
	
	/**
	 * This is the main command of the RxnMgr.	It should be called whenever
	 * there is a chance that a reaction is enabled, or when an agent becomes
	 * capable of executing a reaction.
	 *
	 * Checks whether there are any agents that are
	 * not in the midst of executing a reaction's call-back function, and 
	 * have reactions that are enabled.
	 */
	command error_t RxnMgrI.runRxnMgr() {
	return SUCCESS;
	}	// end command result_t runRxnMgr()
	
	/**
	 * Registers a reaction.	Find a free buffer and stores the reaction
	 * in it.
	 *
	 * @param rxn The reaction to register.
	 * @return SUCCESS or FAIL
	 */
	command error_t RxnMgrI.registerRxn(Reaction* rxn) {
	return FAIL;
	}
	
	command error_t RxnMgrI.deregisterRxn(Reaction* rxn) {
	return FAIL;
	}
	
	command uint16_t RxnMgrI.numRxns(AgillaAgentID* id) {
	return 0;
	}
	
	command error_t RxnMgrI.getRxn(AgillaAgentID* id, uint16_t which, Reaction* rxn) {
	return FAIL;
	}
	
	command error_t RxnMgrI.isRegistered(Reaction* rxn) {
	return FAIL;
	}
	
	/**
	 * Deregister all reactions registered by a particular agent.
	 *
	 * @param id the agent whose reactions should be removed.
	 */
	command error_t RxnMgrI.flush(AgillaAgentID* id) {
	return SUCCESS;
	}
}
