// $Id: VarUtilM.nc,v 1.1 2005/10/13 17:12:13 chien-liang Exp $

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

module VarUtilM {
	provides interface VarUtilI;
	uses interface ErrorMgrI;
}
implementation {
	/**
	 * Returns the size (in bytes) of the specified variable.
	 *
	 * @param vtype The type of the variable
	 * @return The size in bytes of the variable.	Returns 0 if error.
	 */
	command uint16_t VarUtilI.getSize(AgillaAgentContext* context, uint8_t vtype)
	{
		uint16_t varSize;

		switch(vtype)
		{
			case AGILLA_TYPE_VALUE:
				varSize = sizeof(AgillaValue);
				break;
			case AGILLA_TYPE_STRING:
				varSize = sizeof(AgillaString);
				break;
			case AGILLA_TYPE_TYPE:
				varSize = sizeof(AgillaType);
				break;
			case AGILLA_TYPE_STYPE:
				varSize = sizeof(AgillaRType);
				break;
			case AGILLA_TYPE_AGENTID:
				varSize = sizeof(AgillaAgentID);
				break;
			case AGILLA_TYPE_LOCATION:
				varSize = sizeof(AgillaLocation);
				break;
			case AGILLA_TYPE_READING:
				varSize = sizeof(AgillaReading);
				break;
			default:
				dbg("DBG_USR1", "Error: VarUtilM.getSize(): Invalid field type: %i\n", vtype);
				call ErrorMgrI.error2d(context, AGILLA_ERROR_INVALID_TYPE, 0x05, vtype);
				return 0;			
		}
		return varSize;	
	}
}
