// $Id: OPdirectory.nc,v 1.1 2006/03/19 06:09:29 chien-liang Exp $

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
#include "TupleSpace.h"

/**
 * Handles the initiating side of a remote tuple space
 * operation.
 *
 * @author Chien-Liang Fok
 */
configuration OPdirectory {
	provides interface BytecodeI;
}
implementation {
	components MainC, OPdirectoryM, LocationMgrC, RemoteTSOpMgrProxy, AgentMgrC, TupleUtilC;
	components OpStackC, QueueProxy, ErrorMgrProxy, LedsC, NeighborListProxy as NbrList;

	BytecodeI = OPdirectoryM;	

	//Main.StdControl -> OPdirectoryM;
	MainC.SoftwareInit -> OPdirectoryM.Init;
	
	OPrtsM.NeighborListI -> NbrList;
	OPrtsM.LocationMgrI -> LocationMgrC;
	OPrtsM.RemoteTSOpMgrI -> RemoteTSOpMgrProxy;
	OPrtsM.AgentMgrI -> AgentMgrC;
	OPrtsM.TupleUtilI -> TupleUtilC;
	OPrtsM.OpStackI -> OpStackC;
	OPrtsM.QueueI -> QueueProxy;
	OPrtsM.ErrorMgrI -> ErrorMgrProxy;
	OPrtsM.Leds -> LedsC;
}

