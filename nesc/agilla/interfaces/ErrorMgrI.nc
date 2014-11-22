// $Id: ErrorMgrI.nc,v 1.2 2006/02/12 07:11:23 chien-liang Exp $

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
 * An interface for the components handling error reporting in Agilla.
 * @author Chien-Liang Fok
 */
interface ErrorMgrI {	

	command error_t reset();
	
	/**
	 * Called when an error with no associated data occurs.
	 *
	 * @param context The agent context that caused the error.
	 */
	command error_t error(AgillaAgentContext* context, uint8_t cause);
	
	/**
	 * Called when an error with one associated data parameter occurs.
	 *
	 * @param context The agent context that caused the error.
	 * @param data1 The associated data paramter.
	 */
	command error_t errord(AgillaAgentContext* context, uint8_t cause, 
	uint16_t data1);
	
	/**
	 * Called when an error with one associated data parameter occurs.
	 *
	 * @param context The agent context that caused the error.
	 * @param data1 The first associated data paramter.
	 * @param data2 The second associated data parameter.
	 */
	command error_t error2d(AgillaAgentContext* context, uint8_t cause, uint16_t data1, uint16_t data2);
	
	/**
	 * Returns SUCCESS if Agilla is in an error state, 
	 * else returns FAIL.
	 */
	command error_t inErrorState();
}
