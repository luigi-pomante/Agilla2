// $Id: MessageBufferM.nc,v 1.3 2006/04/21 21:56:58 chien-liang Exp $

/* Agilla - A middleware for wireless sensor networks.
 * Copyright (C) 2006, Washington University in Saint Louis 
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
module MessageBufferM {
	provides {
	interface StdControl;
	interface Init;
	interface MessageBufferI;
	}
}
implementation {
	message_t msgBuff[MESSAGE_BUFFER_SIZE];
	message_t* msgBuffPtr[MESSAGE_BUFFER_SIZE];
	
	command error_t Init.init() {
	uint16_t i;
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {
		msgBuffPtr[i] = &msgBuff[i];
	}
	return SUCCESS;
	}
	
	command error_t StdControl.start() {
	return SUCCESS;
	}
	
	command error_t StdControl.stop() {
	return SUCCESS;
	}
	
	command message_t* MessageBufferI.getMsg()
	{	
	uint16_t i;
	
	#if DEBUG_MESSAGE_BUFFER
		uint16_t j, k;
	#endif
	
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {
		if (msgBuffPtr[i] != NULL) {
		message_t* result = msgBuffPtr[i];
		msgBuffPtr[i] = NULL;

		#if DEBUG_MESSAGE_BUFFER
			j = 0;
			for (k = 0; k < MESSAGE_BUFFER_SIZE; k++) {
			if (msgBuffPtr[k] != NULL)
				j++;
			}
			dbg("DBG_USR1", "MessageBufferI: buffer %i allocated, %i free.\n", i, j);		
		#endif
		
		return result;
		}	
	}
	
	dbg("DBG_USR1", "MessageBufferI.getMsg(): ERROR: No free buffers.\n");			
	return NULL;
	}
	
	command error_t MessageBufferI.freeMsg(message_t* msg)
	{
	uint16_t i;
	
	#if DEBUG_MESSAGE_BUFFER
		uint16_t freeCount, k;
	#endif
	
	for (i = 0; i < MESSAGE_BUFFER_SIZE; i++) {	
		if (msgBuffPtr[i] == NULL) {
		msgBuffPtr[i] = msg;

		#if DEBUG_MESSAGE_BUFFER
			freeCount = 0;
			for (k = 0; k < MESSAGE_BUFFER_SIZE; k++) {
			if (msgBuffPtr[k] != NULL)
				freeCount++;
			}		
			dbg("DBG_USR1", "MessageBufferI: buffer %i de-allocated, %i free.\n", i, freeCount);		
		#endif
		
		return SUCCESS;
		}
	}
	return FAIL;
	}
}
