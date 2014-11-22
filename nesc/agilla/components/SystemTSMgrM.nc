// $Id: SystemTSMgrM.nc,v 1.3 2006/02/01 07:29:38 chien-liang Exp $

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
 * IMPLIED, TSMGR_INCLUDTSMGR_ING BUT NOT LIMITED TO, IMPLIED WARRANTIES OF 
 * MERCHANTABILITY OR FITNESS FOR A PARTICULAR USE.
 *
 * YOU UNDERSTAND THAT AGILLA IS PROVIDED "AS IS" FOR WHICH NO 
 * WARRANTIES AS TO CAPABILITIES OR ACCURACY ARE MADE. THERE ARE NO 
 * WARRANTIES AND NO REPRESENTATION THAT AGILLA IS FREE OF 
 * TSMGR_INFRTSMGR_INGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHER 
 * PROPRIETARY RIGHTS.	THERE ARE NO WARRANTIES THAT SOFTWARE IS 
 * FREE FROM "BUGS", "VIRUSES", "TROJAN HORSES", "TRAP DOORS", "WORMS", 
 * OR OTHER HARMFUL CODE.	
 *
 * YOU ASSUME THE ENTIRE RISK AS TO THE PERFORMANCE OF SOFTWARE AND/OR 
 * ASSOCIATED MATERIALS, AND TO THE PERFORMANCE AND VALIDITY OF 
 * TSMGR_INFORMATION GENERATED USTSMGR_ING SOFTWARE. By using Agilla you agree to 
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
#include "TupleSpace.h"

module SystemTSMgrM {
	provides
	{
		interface StdControl;
		interface Init;
		interface SystemTSMgrI as SysTSMgr;
	}
	uses
	{
		interface TupleSpaceI as TS;
		interface TupleUtilI as TupleUtil;
	}
}

implementation {

	#define TSMGR_IN 0
	#define TSMGR_OUT 1

	command error_t Init.init()
	{
		return SUCCESS;
	}

	command error_t StdControl.start()
	{
		return SUCCESS;
	}

	command error_t StdControl.stop()
	{
		return SUCCESS;
	}
	
	inline error_t doit(int op, AgillaAgentID id)
	{
		AgillaTuple tuple;

		call TupleUtil.createAgentIDTuple(&tuple, id);

		if (op == TSMGR_IN)
		{
			return call TS.hinp(&tuple); 
		}
		else
			return call TS.out(&tuple);		
		return SUCCESS;
	}

	command error_t SysTSMgr.outAgentTuple(AgillaAgentID aID)
	{
		return doit(TSMGR_OUT, aID);
	}

	command error_t SysTSMgr.inAgentTuple(AgillaAgentID aID)
	{
		return doit(TSMGR_IN, aID);		 
	}

	/**
	 * Signaled when a new tuple is inserted into the tuple space.
	 * This is necessary so blocked agents can be unblocked.
	 */
	event error_t TS.newTuple(AgillaTuple* tuple)
	{
		return SUCCESS; 
	}

	/**
	 * Signals that the tuple space has shifted bytes.	
	 * This indicates that a tuple is removed.
	 *
	 * @param from The first byte that was shifted.
	 * @param amount The number of bytes it was shifted by.
	 */
	event error_t TS.byteShift(uint16_t from, uint16_t amount)
	{
		return SUCCESS;
	}	
}
