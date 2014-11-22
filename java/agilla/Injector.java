// $Id: Injector.java,v 1.5 2006/04/05 10:28:21 borndigerati Exp $
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
package agilla;

import agilla.messages.*;
import net.tinyos.message.*;
import agilla.rmi.agentInjector.*;

/**
 *  Injects an agent into the sensor network.
 *
 *  @author Chien-Liang Fok <liang@cse.wustl.edu>
 */
public class Injector implements AgillaConstants {
	private SNInterface sni;
	private AgentSender  agentSender;
	private TupleSpace ts;
	private boolean useRMI;
	private AgentInjectorRMI injectorRMI;
	private String rmihost;
	private LocationManager locMgr = null;

    public Injector(String source) throws Exception {
		this.useRMI = source.startsWith("RMI:");
		if (!useRMI) {
			sni = new SNInterface();
			sni.registerListener(new AgillaErrorMsgJ(), new ErrorDisplayer());
			agentSender = new AgentSender(sni, true);
			ts = new TupleSpace(sni);
			new TimeSync(sni);
			if (AgillaProperties.enableClustering())
				locMgr = new LocationManager(sni);
			//new SimpleTestAgent();     // debug
		}
		else {
			rmihost = source.substring(4);
			System.out.println("rmi host is " + rmihost);
			//let's go get the agent injector
			try {
				String name="//"+rmihost+"/AgentInjector";
				injectorRMI = AgentInjectorRMIFactory.agentInjectorRMI(name);
			} catch (Exception e2) {
				e2.printStackTrace();
			}
		}
    }

	public boolean useRMI() {
		return useRMI;
	}

	public String getRMIHost() {
		return rmihost;
	}

	public void setMoteIF(MoteIF moteIF) {
		sni.setMoteIF(moteIF);
	}

	public void disconnect() {
		sni.disconnect();
	}

	public void reset(int address) {
		
		sendMsg(new AgillaResetMsgJ(TOS_UART_ADDRESS, address));
	}
	
	public LocationManager getLocMgr(){
		return locMgr;
	}

	public void registerListener(MessageJ msg, MessageListenerJ listener) {
		sni.registerListener(msg, listener);
	}

	public void sendMsg(MessageJ msg) {
		try {
			if (sni != null) sni.send(msg);
		} catch(Exception e) {
			e.printStackTrace();
		}
	}

	public void inject(int dest, Agent agent) {
		if (useRMI) {
			try {
				injectorRMI.inject(dest, agent);
			} catch(Exception e) {
				e.printStackTrace();
			}
		} else {
			if (Debugger.debug)
				System.out.println("Injecting Agent to " + dest);
			agentSender.send(dest, agent);
		}
	}

	public TupleSpace getTS() {
		return ts;
	}
}
