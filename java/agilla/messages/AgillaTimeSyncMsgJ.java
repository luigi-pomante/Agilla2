// $Id: AgillaTimeSyncMsgJ.java,v 1.1 2006/03/16 20:42:39 chien-liang Exp $
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
 * INFRINGEMENT OF THIRD PARTY PATENT, COPYRIGHT, OR OTHE
 * PROPRIETARY RIGHTS.  THERE ARE NO WARRANTIES THAT SOFTWARE IS
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
package agilla.messages;

import agilla.*;
import agilla.variables.*;

/**
 * AgillaTimeSyncMsgJ.java
 *
 * @author Chien-Liang Fok
 */
public class AgillaTimeSyncMsgJ implements MessageJ, AgillaConstants {
	private long high32, low32;
	
	public AgillaTimeSyncMsgJ() {		
	}
	
	public AgillaTimeSyncMsgJ(long high32, long low32)
	{
		this.high32 = high32;
		this.low32 = low32;
	}
	
	public AgillaTimeSyncMsgJ(AgillaTimeSyncMsg msg) {
		this.high32 = msg.get_time_high32();
		this.low32 = msg.get_time_low32();
	}
	
	public int getType() {	
		return AgillaTimeSyncMsg.AM_TYPE;
	}
	
	public long high32() {
		return high32;
	}
	
	public long low32() {
		return low32;
	}
	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaTimeSyncMsg msg = new AgillaTimeSyncMsg();
		msg.set_time_high32(high32);
		msg.set_time_low32(low32);		
		return msg;
	}
	
	public String toString() {
		return "TimeSyncMsg: " + high32 + "." + low32;
	}
}


