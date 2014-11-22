// $Id: TimeSet.nc,v 1.5 2003/10/07 21:46:15 idgay Exp $

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
 * Authors:		Su Ping	<sping@intel-research.net>
 *
 */

/**
 * The TimeSet interface. 
 * @author Su Ping <sping@intel-research.net>
 */

#include "TosTime.h"

interface TimeSet {

	/**
	 *	Set the 64 bits logical time to a specified value 
	 *	@param t Time in the unit of binary milliseconds
	 *			 type is tos_time_t
	 *	@return none
	 */
	command void set(tos_time_t t);


	/**
	 *	Adjust logical time by n	binary milliseconds.
	 *
	 *	@param us unsigned 16 bit interger 
	 *			positive number advances the logical time 
	 *			negtive argument regress the time 
	 *			This operation will not take effect immidiately
	 *			The adjustment is done duing next clock.fire event
	 *			handling.
	 *	@return none
	 */
	command void adjust(int16_t n);

	/**
	 *	Adjust logical time by x milliseconds.
	 *
	 *	@param x	32 bit interger
	 *			positive number advances the logical time
	 *			negtive argument regress the time
	 *	@return none
	 */
	command void adjustNow(int32_t x);
	 
}











