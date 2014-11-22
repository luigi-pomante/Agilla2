// $Id: TimeUtilC.nc,v 1.4 2003/11/11 21:32:46 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University	of California.	
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.	THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE	 
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.	Attention:	Intel License Inquiry.
 */

/*
 *
 * Authors:		Su Ping	(sping@intel-research.net)

 * Date last modified:	9/25/02
 *
 */

/**
 * @author Su Ping (sping@intel-research.net)
 */


#include "TosTime.h"

module TimeUtilC {
	provides interface TimeUtil;
}
implementation
{
	// compare a and b. If a>b return 1 a==b return 0 a< b return -1
	async command char TimeUtil.compare(tos_time_t a, tos_time_t b){
	if (a.high32>b.high32) return 1;
	if (a.high32 <b.high32) return -1;
	if (a.low32 > b.low32 ) return 1;
	if (a.low32 < b.low32 ) return -1;
	return 0;
	}

	// subtract b from a , return the difference. 
	async command tos_time_t TimeUtil.subtract(tos_time_t a, tos_time_t b)	{
	tos_time_t result;

	result.low32 = a.low32 - b.low32;
	result.high32 = a.high32 - b.high32;
	if (b.low32 > a.low32) {
		result.high32 --;
	}
	return result;
	}
	 

	// add a and b return the sum. 
	async command tos_time_t TimeUtil.add( tos_time_t a, tos_time_t b){
	tos_time_t result;
	result.low32 = a.low32 + b.low32 ;
	result.high32 = a.high32 + b.high32;
	if ( result.low32 < a.low32) {
		result.high32 ++;
	}
	return result;
	}

	/** increase tos_time_t a by a specified unmber of binary ms
	 *	return the new time
	 **/
	async command tos_time_t TimeUtil.addint32(tos_time_t a, int32_t ms) {
	if (ms > 0)
		return call TimeUtil.addUint32(a, ms);
	else
		// Note: ms == minint32 will still give the correct value
		return call TimeUtil.subtractUint32(a, (uint32_t)-ms);
	}
	
	/** increase tos_time_t a by a specified unmber of binary ms
	 *	return the new time 
	 **/
	async command tos_time_t TimeUtil.addUint32(tos_time_t a, uint32_t ms) {
	tos_time_t result=a;
	result.low32	+= ms ;
	if ( result.low32 < a.low32) {
		result.high32 ++;
	} 
	//dbg(DBG_TIME, "result: \%x , \%x\n", result.high32, result.low32);
	return result;
	}	
	
	/** substrct tos_time_t a by a specified unmber of binary ms
	 *	return the new time 
	 **/
	async command tos_time_t TimeUtil.subtractUint32(tos_time_t a, uint32_t ms)	{
	tos_time_t result = a;
	result.low32 -= ms;
	if ( result.low32 > a.low32) {
		result.high32--;
	} 
	//dbg(DBG_TIME, "result: \%x , \%x\n", result.high32, result.low32);
	return result;
	}

	async command tos_time_t TimeUtil.create(uint32_t high, uint32_t low) {
	tos_time_t result;
	result.high32 = high;
	result.low32 = low;
	return result;
	}

	async command uint32_t TimeUtil.low32(tos_time_t lt) {
	return lt.low32;
	}

	async command	uint32_t TimeUtil.high32(tos_time_t lt) {
	return lt.high32;
	}
}
