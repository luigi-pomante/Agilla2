// $Id: TimeoutTimer.java,v 1.3 2006/02/13 08:40:40 chien-liang Exp $

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
/**
 * TimeoutTimer.java
 *
 * @author Chien-Liang Fok
 */

package agilla;

import java.util.*;
import agilla.messages.*;

public class TimeoutTimer implements AgillaConstants, Runnable 
{
	
	private boolean alive = true;
	private Vector msgQueue;
	private Thread thread;
	private long duration;
	private int id;
	
	/**
	 * @param lock the lock to notify when the timer fires.
	 * @param duration the timeout in ms
	 */
	public TimeoutTimer(Vector msgQueue, long duration, int id) 
	{
		this.msgQueue = msgQueue;
		this.duration = duration;
		this.id = id;
		thread = new Thread(this);
		thread.start();		
		Debugger.dbg("TimoutTimer", "Starting TimeoutTimer, duration " + duration);
	}
	
	public void kill() {
		synchronized(msgQueue) {
			alive = false;
		}
		try {
			thread.interrupt();
			//thread.join();
		} catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	public int id() {
		return id;
	}
	
	public void run() {
		try {
			Thread.sleep(duration);
		} catch(InterruptedException e) {
			if (alive) 
				e.printStackTrace();
		}
		//Debugger.dbg("AgentSender.TimoutTimer", "TIMER FIRED!");
		
		synchronized(msgQueue) 
		{
			if (alive) {
				Debugger.dbg("TimoutTimer", "TIMED OUT!");
				try {
					msgQueue.add(new TimeoutMsgJ(id));
					msgQueue.notifyAll();
				} catch(Exception e) {
					e.printStackTrace();
				}
			}
		}// else Debugger.dbg("TimoutTimer", "TIMER FIRED BUT WAS NOT ALIVE!");
	}
}
