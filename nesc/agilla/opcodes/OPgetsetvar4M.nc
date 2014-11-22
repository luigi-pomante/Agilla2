// $Id: OPgetsetvar4M.nc,v 1.2 2006/01/10 07:45:14 chien-liang Exp $

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

/*					tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University	of California.	
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND THE UNIVERSITY OF
 * CALIFORNIA HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
 * UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */
/*					tab:4
 *					
 *	IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
 *	By downloading, copying, installing or using the software you
 *	agree to this license.	If you do not agree to this license, do
 *	not download, install, copy or use the software.
 *
 *	Intel Open Source License 
 *
 *	Copyright (c) 2002 Intel Corporation 
 *	All rights reserved. 
 *	Redistribution and use in source and binary forms, with or without
 *	modification, are permitted provided that the following conditions are
 *	met:
 * 
 *	Redistributions of source code must retain the above copyright
 *	notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *	notice, this list of conditions and the following disclaimer in the
 *	documentation and/or other materials provided with the distribution.
 *		Neither the name of the Intel Corporation nor the names of its
 *	contributors may be used to endorse or promote products derived from
 *	this software without specific prior written permission.
 *	
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *	``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *	LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *	PARTICULAR PURPOSE ARE DISCLAIMED.	IN NO EVENT SHALL THE INTEL OR ITS
 *	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *	EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *	PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/*
 * Authors:	 Philip Levis <pal@cs.berkeley.edu>
 * History:	 Apr 13, 2003		 Inception.
 *
 */

/**
 * @author Philip Levis <pal@cs.berkeley.edu>
 */


#include "Agilla.h"

module OPgetsetvar4M 
{
	provides interface BytecodeI;
	uses 
	{
	interface ErrorMgrI as Error;	
	interface OpStackI as Stacks;
	}
}

implementation 
{	
	command error_t BytecodeI.execute(uint8_t instr, AgillaAgentContext* context) {
	uint8_t arg = instr & 0xf;
	
	if (arg >= AGILLA_HEAP_SIZE) 
	{
		dbg("DBG_USR1", "VM (%i:%i): ERROR: Heap Index out of range %i.\n", context->id.id, context->pc-1, arg);
		call Error.error(context, AGILLA_ERROR_INDEX_OUT_OF_BOUNDS);
		return FAIL;	
	}

	if ((instr >> 4) & 0x01) // set var	 
	{ 
		AgillaVariable var;
		if (call Stacks.popOperand(context, &var) == SUCCESS) 
		{			 
		if (!(var.vtype & AGILLA_VAR_ASRTVL))
		{
			dbg("DBG_USR1", "VM (%i:%i): ERROR: Top of stack not an agentid, name, reading, type, or value.\n", context->id.id, context->pc-1);
			call Error.errord(context, AGILLA_ERROR_INVALID_TYPE, 0x0c);
			return FAIL;
		}
		dbg("DBG_USR1", "VM (%i:%i): Executing setvar %i, vtype = %i.\n", context->id.id, context->pc-1, arg, var.vtype);
		context->heap.pos[arg] = var;
		return SUCCESS;
		} else
		return FAIL;
	} else // get var
	{		
		dbg("DBG_USR1", "VM (%i:%i): Executing getvar %i.\n", context->id.id, context->pc-1, arg);
		if (context->heap.pos[arg].vtype == AGILLA_TYPE_INVALID) 
		{
		dbg("DBG_USR1", "\tERROR executing getvar: no variable in heap address %i.\n", (int)arg);
		context->condition = 0;
		} else 
		{		
		context->condition = 1;		
		call Stacks.pushOperand(context, &context->heap.pos[arg]);
		}
		return SUCCESS;
	}
	}
}
