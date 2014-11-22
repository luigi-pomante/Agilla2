// $Id$
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
 * AgillaClusterDebugMsgJ.java
 *
 * @author Sangeeta Bhattacharya
 */
public class AgillaClusterDebugMsgJ implements MessageJ, AgillaConstants {
	int src;
	int chId;
	AgillaRectangle boundingBox;
	
	public AgillaClusterDebugMsgJ() {		
	}
	
	public AgillaClusterDebugMsgJ(int src, int chId, AgillaRectangle boundingBox)
	{
		this.src = src;
		this.chId = chId;
		this.boundingBox = boundingBox;
	}
	
	public AgillaClusterDebugMsgJ(AgillaClusterDebugMsg msg) {
		this.src = msg.get_src();
		this.chId = msg.get_id();
		this.boundingBox = new AgillaRectangle(new AgillaLocation(msg.get_bounding_box_llc_x(), msg.get_bounding_box_llc_y()),
				new AgillaLocation(msg.get_bounding_box_urc_x(), msg.get_bounding_box_urc_y()));
	}
	
	public int getType() {	
		return AgillaClusterDebugMsg.AM_TYPE;
	}
	
	public int chId(){
		return chId;
	}
	
	public int src(){
		return src;
	}
	
	public AgillaRectangle boundingBox() {
		return boundingBox;
	}

	
	public net.tinyos.message.Message toTOSMsg() {
		AgillaClusterDebugMsg msg = new AgillaClusterDebugMsg();
		msg.set_src(src);
		msg.set_id(chId);
		msg.set_bounding_box_llc_x(boundingBox.lowerLeftCorner().getx());
		msg.set_bounding_box_llc_y(boundingBox.lowerLeftCorner().gety());
		msg.set_bounding_box_urc_x(boundingBox.upperRightCorner().getx());
		msg.set_bounding_box_urc_y(boundingBox.upperRightCorner().gety());
		return msg;
	}
	
	public String toString() {
		return "ClusterDebugMsg[Src: " + src + " \tclusterheadId: " + chId + "\tboundingBox:" + boundingBox + "]";
	}
}


