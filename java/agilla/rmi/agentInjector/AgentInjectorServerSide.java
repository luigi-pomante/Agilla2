// $Id: AgentInjectorServerSide.java,v 1.1 2005/10/13 17:12:19 chien-liang Exp $

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
 * @author Daniel Massaguer <dmassagu@uci.edu>
 */
package agilla.rmi.agentInjector;

import java.rmi.*;
import java.rmi.server.*;
import java.net.ConnectException;
import java.net.UnknownHostException;
import java.net.MalformedURLException;
import agilla.*;
public class AgentInjectorServerSide extends UnicastRemoteObject implements AgentInjectorRMI {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	protected Injector agillaInjector;
	private String name;
	public AgentInjectorServerSide(Injector injector) throws RemoteException,ConnectException,UnknownHostException,MalformedURLException {
		super();
		if (System.getSecurityManager() == null) {
			System.setSecurityManager(new RMISecurityManager());
		}
		name="//"+java.net.InetAddress.getLocalHost().getHostAddress()+"/AgentInjector";
		Naming.rebind(name, this);
		//System.out.println("Injector bound as "+name);
		agillaInjector=injector;
	}
	
	public String getBoundName() {
		return name;
	}
	public void unbind() {
		try{
			String name="//"+java.net.InetAddress.getLocalHost().getHostAddress()+"/AgentInjector";
			Naming.unbind(name);
			//System.out.println("Injector "+name+" unbound");
		} catch(Exception e) {
			//just ignore the exception, since it might be due to the object didn't exist (it was never bound)
		}
	}
	public boolean inject(int dest, Agent ma) {
		//System.out.println(ma);
		try{
			System.out.println("injecting agent at mote "+dest+" ...");
			agillaInjector.inject(dest,ma);
		} catch(Exception exc) {
			System.out.println("exception while injecting agent at mote "+dest+" :"+exc);
			return false;
		}
		return true;
	}
}
