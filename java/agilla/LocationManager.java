// $Id: LocationManager.java,v 1.22 2006/05/01 16:09:01 chien-liang Exp $

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

import java.util.*;
import agilla.messages.*;
import agilla.variables.*;

public class LocationManager implements AgillaConstants {

	final static int QUERY_CHECK_INTERVAL			= 5;	// seconds
	final static int QUERY_TIMEOUT					= 5;	// seconds
	
	/**
	 * This is the period at which cluster heads are expected to update
	 * the base station letting the base station know they still exist.
	 */
	final static int CH_UPDATE_INTERVAL				= 15;	// seconds
	
	final static int BS_UPDATE_INTERVAL				= 20;	// seconds
	final static int AGENT_INFO_TIMEOUT				= 120;	// seconds
	final static int AGENT_LOC_FRESHNESS_INTERVAL	= 10;	// milliseconds  
	final static int GW_ID							= 0;	// id of the gateway node
	final static int INFINITY						= 10000;
	final static long QUERY_TIMEOUT_INTERVAL		= 900;	// milliseconds
	
	
	public final static boolean ENABLE_CLUSTERING = agilla.AgillaProperties.enableClustering();	// indicates whethering clustering is enabled
	final static boolean DEBUG = true;

	public enum PktType { UNKNOWN, RTPKT, CMPKT, CHPKT, BBPKT, APKT, ADPKT, AUPKT, QPKT, QRPKT }
	public enum QueryType { UNKNOWN,  QUERYALL, QUERYNUMBER, QUERYAGENT, QUERYNEARESTNEIGHBOR }
	public enum RoleType { UNKNOWN, AGENT, CLUSTERMEMBER, CLUSTERHEAD, BASESTATION}
	double NOW;

	// Basestation data

	SNInterface sni;
	Node me;									// my id and pos;
	double t0;									// start time
	int kmin, kmax;								// cluster size
	double max_agent_speed;						// maximum agent speed
	Directory directory;						// directory of agents in the system
	QueryList queryList;						// list of outstanding queries
	AgillaString networkName;
	

	// Message handlers

	LocMsgHandler locMsgHandler;
	QueryNumAgentsMsgHandler queryNumAgentsMsgHandler;
	QueryAgentLocMsgHandler queryAgentLocMsgHandler;
	QueryNearestAgentMsgHandler queryNearestAgentMsgHandler;
	QueryAllAgentsMsgHandler queryAllAgentsMsgHandler;
	QueryReplyAgentLocMsgHandler queryReplyAgentLocMsgHandler;
	QueryReplyAllAgentsMsgHandler queryReplyAllAgentsMsgHandler;
	QueryReplyNearestAgentMsgHandler queryReplyNearestAgentMsgHandler;
	ClusterMsgHandler clusterMsgHandler;
	ClusterDebugMsgHandler clusterDebugMsgHandler;

	class Pos
	{
		public double x, y, z;

		Pos(){ x = y = z = 0;}

		Pos(Pos p){ x = p.x; y = p.y; z = p.z;}

		Pos(double x, double y){this.x = x; this.y = y; z = 0;}

		Pos(AgillaLocation loc){x = (double)loc.getx(); y = (double)loc.gety(); z = 0;}

		public boolean equals(Pos p)
		{
			if(x == p.x && y == p.y && z == p.z) return true; else return false;
		}

		public String toString()
		{
			return ("<"+ x + "," + y + "," + z +">");
		}
	}

	class Rectangle
	{
		public Pos p1, p2;

		Rectangle(){p1 = new Pos(); p2 = new Pos(); }

		Rectangle(Pos pos1, Pos pos2){ p1 = pos1; p2 = pos2;}
		
		Rectangle(AgillaRectangle rect){
			p1 = new Pos(); p2 = new Pos();
			p1.x = rect.lowerLeftCorner().getx();
			p1.y = rect.lowerLeftCorner().gety();
			p2.x = rect.upperRightCorner().getx();
			p2.y = rect.upperRightCorner().gety();
		}
		
		public boolean isZero(){
			if(p1.x == 0 && p1.y == 0 && p2.x == 0 && p2.y == 0) return true; else return false;
		}

		public void merge(Rectangle rect)
		{
			if(p1.x == -1)
			{
				p1.x = rect.p1.x;
				p1.y = rect.p1.y;
				p2.x = rect.p2.x;
				p2.y = rect.p2.y;
			} 
			else 
			{
				if(rect.p1.x < p1.x) p1.x = rect.p1.x;
				if(rect.p1.y < p1.y) p1.y = rect.p1.y;
				if(rect.p2.x > p2.x) p2.x = rect.p2.x;
				if(rect.p2.y > p2.y) p2.y = rect.p2.y;
			}
		}	

		public boolean isInside(Pos pos)
		{
			if(pos.x >= p1.x && pos.x <= p2.x && pos.y >= p1.y && pos.y <= p2.y) return true; else return false;
		}

		public boolean isCompletelyInside(Pos pos)
		{
			if(pos.x > p1.x && pos.x < p2.x && pos.y > p1.y && pos.y < p2.y) return true; else return false;
		}

		public String toString()
		{
			return ("[" + p1 + p2 + "]");
		}

	}

	class Circle
	{
		public Pos center;
		public double radius;

		Circle(){center = new Pos(); radius = 0;}

		Circle(Pos c, double rad){center = c; radius = rad;}
	}

	class Node
	{
		public int id;
		public Pos pos;

		Node(){id = 0; pos = new Pos();}

		Node(int nid){id = nid; pos = new Pos();}

		Node(int nid, Pos p){id = nid; pos = p;}

		public String toString()
		{
			return ("Node(id:" + id + "pos:" + pos + ")");
		}
	}

	class Agent
	{
		public int id;
		public double timestamp;
		public Pos pos;
		public AgillaAgentType type;
		public long bs_timestamp;			// when agent info was received at the BS

		Agent(){
			id = 0; 
			timestamp = 0; 
			pos = new Pos();  
			type = new AgillaAgentType();
			bs_timestamp = 0;
		}

		Agent(int aid, double ts, Pos p, AgillaAgentType type){
			id = aid; 
			timestamp = ts; 
			pos = p;
			this.type = type;
			bs_timestamp = 0;
		}
		
		Agent(int aid, double ts, Pos p, AgillaAgentType type, long bs_timestamp){
			id = aid; 
			timestamp = ts; 
			pos = p;
			this.type = type;
			this.bs_timestamp = bs_timestamp;
		}

		public String toString()
		{
			return ("Agent(id:" + id + " timestamp:" + timestamp +
					" pos:" + pos + " type:" + type + " bs_timestamp:" + bs_timestamp + ")");
		}
	}

	class AgentInfo
	{
		private Agent agent;
		private boolean valid;
		

		AgentInfo(){agent = new Agent(); valid = false;}

		AgentInfo(Agent ag){agent = ag; ag.bs_timestamp = (new Date()).getTime(); valid = true;}

		public boolean isValid(){return valid;}

		public void makeInvalid(){valid = false;}

		public void makeValid(){valid = true;}

		public Agent getAgent(){return agent;}
	}

	class Cluster
	{
		private int ch_id;
		private Rectangle bounding_box;
		private Vector<AgentInfo> agent_list;
		private double expiry_time;
		
		/**
		 * The time at which the last heartbeat was heard.
		 */
		private long timestamp = (new Date()).getTime(); // added by liang 

		Cluster(){
			ch_id = -1; 
			agent_list = new Vector<AgentInfo>(); 
			expiry_time = 0; 
			bounding_box = new Rectangle();
		}

		Cluster(int id, Rectangle bb, double exptime)
		{
			ch_id = id;
			agent_list = new Vector<AgentInfo>();
			bounding_box = bb;
			expiry_time = exptime;
		}

		Cluster(int id, double exptime)
		{
			ch_id = id;
			agent_list = new Vector<AgentInfo>();
			bounding_box = new Rectangle();
			expiry_time = exptime;
		}

		public void clear(){
			agent_list.clear();
		}
		
		public void addAgent(Agent agent)
		{
			// insert or update agent info
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo aginf = agent_list.get(i);
				Agent ag = aginf.getAgent();
				if(ag.id == agent.id )//&& ag.type.equals(ag.type)
				{
					if(ag.timestamp < agent.timestamp)
					{
						ag.timestamp = agent.timestamp;
						ag.pos = agent.pos;
						ag.type = agent.type;
						ag.bs_timestamp = (new Date()).getTime();
						aginf.makeValid();
					}
					return;
				}
			}
			AgentInfo aginf = new AgentInfo(agent);
			agent_list.add(aginf);
		}

		public void deleteAgent(Agent agent) throws IllegalAccessException{
			// insert or update agent info
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo aginf = agent_list.get(i);
				Agent ag = aginf.getAgent();
				if(ag.id == agent.id )//&& ag.type.equals(ag.type)
				{
					agent_list.remove(i);
					return;
				}
			}
			// agent not present should throw exception
			throw new IllegalAccessException("Cluster:deleteAgent() ERROR! Did not find agent with id " + agent.id);
		}

		public void validateInfo()
		{
			assert (expiry_time > 0);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo aginf = (AgentInfo)agent_list.get(i);
				if(aginf.isValid() && (NOW - aginf.getAgent().timestamp) >= expiry_time) aginf.makeInvalid();
			}
		}

		public Agent getAgent(int agentId) throws IllegalAccessException
		{
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo aginf = agent_list.get(i);
				//if(aginf.isValid() && (NOW - aginf.getAgent().timestamp) >= expiry_time) aginf.makeInvalid();
				if(aginf.isValid() && aginf.getAgent().id == agentId) 
					return aginf.getAgent();
			}
			throw new IllegalAccessException("Cluster:getAgent() ERROR! Could not find agent with id "+agentId);
		}
		
		public boolean allAgentDataFresh(AgillaAgentType type){
			for(int i = 0; i < agent_list.size(); i++)
			{
				Agent agent = agent_list.get(i).getAgent();
				if((type.isUnspecified() || agent.type.equals(type)) && 
						((new Date()).getTime() - agent.bs_timestamp) > AGENT_LOC_FRESHNESS_INTERVAL)
					return false;
			}
			return true;
		}
		
		public Vector<Agent> getAgents(AgillaAgentType type) {
			Vector<Agent> agents = new Vector<Agent>();
			for(int i = 0; i < agent_list.size(); i++)
			{
				Agent agent = agent_list.get(i).getAgent();
				if(type.isUnspecified() || agent.type.equals(type))
						agents.add(agent);
			}
			return agents;
		}
		

		public boolean hasAgent(int agentId)
		{
			try{
				getAgent(agentId);
				return true;
			} catch (IllegalAccessException e){
				return false;
			}
		}

		public void cleanUp()
		{
			try
			{
				for(int i = 0; i < agent_list.size(); i++)
				{
					AgentInfo aginf = agent_list.get(i);
					if(!aginf.isValid() || (NOW - aginf.getAgent().timestamp) >= expiry_time) { agent_list.remove(i); i--;}
				}
			}
			catch(Exception e)
			{
				System.err.println("Error in Cluster.cleanUp(): "+e);
			}
		}

		public String toString()
		{
			String res = "Cluster[id:" + ch_id + " bounding_box:" + bounding_box.toString() + " expiry_time:" + expiry_time;
			res += " num_agents:" + agent_list.size() + " Agents{";
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo aginf = agent_list.get(i);
				if(aginf.isValid()) { res += aginf.getAgent().toString();}
			}
			res += "}]";
			return res;
		}

		public int getId(){return ch_id;}
		public void setId(int id){ch_id = id;}

		public double getExpiryTime(){return expiry_time;}
		public void setExpiryTime(double exptime){expiry_time = exptime;}

		public Rectangle getBoundingBox(){return bounding_box;}
		public void setBoundingBox(Rectangle bb){bounding_box = bb;}
		
		public int getNumAgents(){return agent_list.size();}
		
		public int getNumAgents(AgillaAgentType type){
			if(type.isUnspecified()) return getNumAgents();
			int count = 0;
			for(int i = 0; i < agent_list.size(); i++)
			{
				Agent agent = agent_list.get(i).getAgent();
				if(agent.type.equals(type))
						count++;
			}
			return count;
		}
		
		public Agent findNearestAgent(int agentId, AgillaAgentType agentType, Pos agentLoc) throws OperationFailedException{
			Agent nearestAgent = new Agent();
			double min_dist = INFINITY;
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentInfo agentinf = agent_list.get(i);
				Agent agent = agentinf.getAgent();
				double dist;
				if((agentType.getVal() == AgillaAgentType.UNSPECIFIED || agent.type.equals(agentType)) 
						&& agent.id != agentId && (dist = eucDist(agent.pos, agentLoc)) < min_dist)
				{
					min_dist = dist;
					nearestAgent.id = agent.id;
					nearestAgent.pos = agent.pos;
					nearestAgent.timestamp = agent.timestamp;
					nearestAgent.type = agent.type;
				}
			}
			if(min_dist == INFINITY)
				throw new OperationFailedException("Cluster.findNearestAgent()! Did not find nearest agent!");
			else
				return nearestAgent;
		}

		/**
		 *  Updates the timestamp to the current time.  This is used to determine when to
		 *  remove a cluster from the Directory.		 
		 *  
		 *  <p>Added by Liang Fok
		 */
		public void updateTimestamp() {
			timestamp = (new Date()).getTime();
		}
		
		/**
		 * Determines whether this cluster has expired.  A cluster expires when it
		 * does not receive a beacon for two CH_UPDATE_INTERVAL periods.
		 * 
		 * <p>Added by Liang Fok
		 * 
		 * @return true if this cluster is expired.
		 */
		public boolean isExpired() {
			return (new Date()).getTime() - timestamp > CH_UPDATE_INTERVAL*2*1000;
		}

	} // Cluster

	class ClusterSet
	{
		private Vector<Cluster> clusters;

		ClusterSet(){clusters = new Vector<Cluster>();}
		
		public void clear(){
			// remove all data
			clusters.clear();
			/*
			for(int i = 0; i < clusters.size(); i++)
			{
				clusters.get(i).clear();
			}*/
		}
		
		public void clear(int ch_id){
			// remove cluster with id ch_id
			
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == ch_id)
				{
					clusters.remove(i);
					//cluster.clear();
					return;
				}
			}
		}

		public Cluster addCluster(Cluster cl)
		{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == cl.getId())
				{
					cluster.setBoundingBox(cl.getBoundingBox());
					cluster.setExpiryTime(cl.getExpiryTime());
					cluster.updateTimestamp();	// update the time at which the last beacon was received
					return cluster;
				}
			}
			clusters.add(cl);
			return (Cluster)clusters.lastElement();
		}

		public void addAgent(Cluster cl, Agent agent)
		{
			Cluster cluster = getCluster(cl.ch_id);
			if(cluster == null)
			{
				cluster = addCluster(cl);
			} 
			cluster.addAgent(agent);
		}

		public void deleteAgent(Cluster cl, Agent agent) throws IllegalAccessException
		{
			deleteAgent(cl.getId(), agent);
		}
		
		public void deleteAgent(int ch_id, Agent agent) throws IllegalAccessException
		{
			//System.out.println("ClusterSet:deleteAgent(chID, Agent) Trying to delete agent "+agent.id);
			//System.out.println(this);
			Cluster cluster = getCluster(ch_id);
			if(cluster == null)
			{
				// should throw exception
				throw new IllegalAccessException("ClusterSet:deleteAgent(chID, Agent) ERROR! Could not find cluster with id " + ch_id);
			} 
			cluster.deleteAgent(agent);
			if(!ENABLE_CLUSTERING){
				if(cluster.getNumAgents() == 0){
					// cluster has no agents; should delete cluster
					deleteClusterFromClusterSet(ch_id);
				}
			}
			//System.out.println("ClusterSet:deleteAgent(chID, Agent) Finished deleting agent "+agent.id);
			//System.out.println(this);
		}
		
		public Vector<Agent> getAgents(int chId, AgillaAgentType agentType) throws IllegalAccessException{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == chId)
				{
					return cluster.getAgents(agentType);
				}
			}
			throw new IllegalAccessException("ClusterSet.getAgents(): Could not find cluster with id "+chId);
		}
		
		public int getNumAgents(int chId) throws IllegalAccessException{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == chId)
				{
					return cluster.getNumAgents();
				}
			}
			throw new IllegalAccessException("ClusterSet.getAgents(): Could not find cluster with id "+chId);
		}

		public Cluster getCluster(int chId)
		{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == chId)
				{
					return cluster;
				}
			}
			return null;
		}
		
		public Vector<Cluster> getClusters(){
			return this.clusters;
		}
		
		public void deleteClusterFromClusterSet(int chId) throws IllegalAccessException
		{
			//System.out.println("ClusterSet:deleteCluster");
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				if(cluster.getId() == chId)
				{
					clusters.remove(i);
					return;
				}
			}
			// should throw exception if cluster not found
			throw new IllegalAccessException("ClusterSet:deleteCluster() ERROR! Could not find cluster with id " + chId);
		}
		
		/**
		 * Goes through the clusters and finds those that are expired.		 
		 * 
		 * <p>Added by Liang Fok
		 * 
		 * @return a vector containing the cluster head IDs of the clusters that
		 * are expired.
		 */
		public Vector<Integer> getExpiredClusters() 
		{
			Vector<Integer> result = new Vector<Integer>();
			for(int i = 0; i < clusters.size(); i++) 
			{
				Cluster cluster = clusters.get(i);
				if (cluster.isExpired()) 
				{
					//print("Cluster " + cluster.getId() + " is expired.");
					result.add(new Integer(cluster.getId()));		
				}
			}
			return result;
		}

		public void validateInfo()
		{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				cluster.validateInfo();
			}
		}

		public void cleanUp()
		{
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				cluster.cleanUp();
			}
		}
		
		public String toString(){
			String res = "ClusterSet[NumClusters:"+clusters.size()+" Clusters{";
			for(int i = 0; i < clusters.size(); i++)
			{
				Cluster cluster = clusters.get(i);
				res += "\n\t" + cluster + ",";
			}
			res += "\n}]";
			return res;
		}
	}

	class AgentIndex
	{
		public int aid;
		public double timestamp;
		public Pos pos;
		public AgillaAgentType type;
		public long bs_timestamp;		// time when the base station received the info

		public int ch_id;
		public boolean valid;
		public double expiry_time;
		//public Vector clusters;

		AgentIndex(){
			aid = -1; 
			type = new AgillaAgentType();
			ch_id = -1; 
			pos = new Pos(); 
			timestamp = 0; 
			valid = false; 
			expiry_time = 0;
			bs_timestamp = 0;
		}
		
		AgentIndex(int chId, Agent agent, double exptime)
		{
			aid = agent.id; 
			ch_id = chId; 
			pos = agent.pos; 
			timestamp = agent.timestamp;
			type = agent.type;
			valid = true;
			expiry_time = exptime;
			bs_timestamp = (new Date()).getTime();
		}
		
		public String toString(){
			return "(id:" + aid + " pos:" + pos + " timestamp:" + timestamp + " ch_id:" + ch_id + " bs_timestamp:" + bs_timestamp + ")";
		}

	}

	class Directory extends ClusterSet
	{
		private Vector<AgentIndex> agent_list;

		Directory(){
			agent_list = new Vector<AgentIndex>();

			// This timer looks for and removes expired clusters.
			// Added by Liang Fok.
			new Timer().scheduleAtFixedRate(new TimerTask(){
				public void run(){					
					Vector<Integer> expiredClusters = getExpiredClusters();
					print("***" + expiredClusters.size() + " EXPIRED CLUSTERS***");
					for (int i = 0; i < expiredClusters.size(); i++) {
						try {
							int ch_id = expiredClusters.get(i).intValue();
							print("Cluster " + ch_id + " expired, removing it from the directory");
							deleteCluster(ch_id);
						} catch(IllegalAccessException e) {
							e.printStackTrace();
						}
					}										
				}
			}, 0, CH_UPDATE_INTERVAL* 1000);			
		}

		public int size(){return agent_list.size();}
		
		public int size(AgillaAgentType agentType){
			if(agentType.getVal() == AgillaAgentType.UNSPECIFIED) return size();
			int count = 0;
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.type.equals(agentType)) count++;
			}
			return count;
		}
		
		public void clear(){
			agent_list.clear();
			super.clear();
			print("Cleared directory: "+ this.toString());
		}
		
		
		public void clear(int ch_id){
			// remove info about cluster with ID ch_id
			super.clear(ch_id);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.ch_id == ch_id)
				{
					agent_list.remove(i);
				}
			}
		}
		
		public void addAgent(Cluster cl, Agent agent)
		{
			super.addAgent(cl, agent);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.aid == agent.id ) //&& agindex.type.equals(agent.type)
				{
					if(agent.timestamp > agindex.timestamp)
					{
						agindex.timestamp = agent.timestamp;
						agindex.pos = agent.pos;
						agindex.valid = true;
						int old_ch_id = agindex.ch_id;
						AgillaAgentType old_type = agindex.type;
						agindex.ch_id = cl.ch_id;
						agindex.expiry_time = cl.expiry_time;
						agindex.type = agent.type;
						agindex.bs_timestamp = (new Date()).getTime();
						
						if(old_type.toString() != agent.type.toString()){
							System.out.println("Agent "+agent.id +" type changed from "+old_type + " to " + agent.type);
						}
						
						// if agent has moved to new cluster, delete agent from old cluster
						if(old_ch_id != cl.ch_id){
							print("Agent "+agindex.aid+" has moved from cluster "+ old_ch_id +" to cluster "+agindex.ch_id);
							try{
								super.deleteAgent(old_ch_id, agent);
							}catch(IllegalAccessException e){
								print("Directory.addAgent(): ERROR! could not delete agent from cluster "+old_ch_id);							
							}
						}
					}
					return;
				}
			}
			
			// DEBUG:LIANG
			if (agent.id > 10) {
				System.out.println("ERROR: agent id is HUGE (" + agent.id + ")");
			}
			
			// agent index not present; add
			AgentIndex agindex = new AgentIndex(cl.ch_id, agent, cl.expiry_time);
			agent_list.add(agindex);
		}

		public void deleteAgent(Cluster cl, Agent agent) throws IllegalAccessException
		{
			//System.out.println("Directory.deleteAgent(Cluster, Agent) Trying to delete agent "+ agent.id);
			//System.out.println(this);
		
			super.deleteAgent(cl, agent);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.aid == agent.id )// && agindex.type.equals(agent.type)
				{
					//System.out.println("Directory.deleteAgent(Cluster, Agent) Trying to delete agent with index "+i);
					//System.out.println(this);
					agent_list.remove(i);
					//System.out.println(this);
					return;
				}
			}
			
			// agent index not present; should throw an exception
			throw new IllegalAccessException("Directory:deleteAgent() ERROR! Could not find agent with id " + agent.id);
		}
		
		public void deleteCluster(int chId) throws IllegalAccessException{
			//System.out.println("Directory:deleteCluster");
			super.deleteClusterFromClusterSet(chId);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.ch_id == chId){
					agent_list.remove(i);
				}
			}
		}
		
		public void deleteAgent(Agent agent) throws IllegalAccessException{
			//System.out.println("Directory.deleteAgent(Agent) Trying to delete agent "+ agent.id);
			//System.out.println(this);
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				
				if(agindex.aid == agent.id ) //&& agindex.type.equals(agent.type)
				{
					
					super.deleteAgent(agindex.ch_id, agent);
					//System.out.println("Directory.deleteAgent(Agent) Trying to delete agent with index "+i);
					//System.out.println(this);
					agent_list.remove(i);
					//System.out.println(this);
					return;
				}
			}
			// agent index not present; should throw an exception
			throw new IllegalAccessException("Directory:deleteAgent() ERROR! Could not find agent with id " + agent.id);
		}

		public String toString()
		{
			String res = "Directory[num_agents:" + agent_list.size() + " Agents{";
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.valid)
				{
					res += "\n\t" + agindex.toString();
				}
			}
			res += "}]";
			if (ENABLE_CLUSTERING)
				res += "\n" + getClusterSet();
			return res;
		}

		public void validateInfo()
		{
			super.validateInfo();
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.valid && (NOW - agindex.timestamp) >= agindex.expiry_time) agindex.valid = false;
			}
		}

		public void cleanUp()
		{
			super.cleanUp();
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(!agindex.valid || (NOW - agindex.timestamp) >= agindex.expiry_time) {agent_list.remove(i); i--;}
			}
		}

		public Agent getAgent(int aid) throws IllegalAccessException
		{
			Agent agent;
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.aid == aid)
				{
					if(agindex.valid)
					{
						agent = new Agent(agindex.aid, agindex.timestamp, agindex.pos, agindex.type, agindex.bs_timestamp);
						return agent;
					}
					throw new IllegalAccessException("Directory:getAgent() ERROR! Agent "+aid+" data is not valid.");
				}
			}
			throw new IllegalAccessException("Directory:getAgent() ERROR! Agent " + aid + " was not found!");
		}
		
		public AgentIndex getAgentIndex(int aid) throws IllegalAccessException
		{
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(agindex.aid == aid)
				{
					if(agindex.valid)
					{
						return agindex;
					}
					throw new IllegalAccessException("Directory:getAgentIndex() ERROR! Agent "+aid+" data is not valid.");
				}
			}
			throw new IllegalAccessException("Directory:getAgentIndex() ERROR! Agent " + aid + " was not found!");
		}
		
		public Agent getAgentAt(int i) throws IllegalAccessException
		{
			if(agent_list.size() == 0) 
				throw new IllegalAccessException("Directory:getAgentAt() ERROR! Agent list is empty.");
			if(i < 0 || i >= agent_list.size()){
				throw new IllegalAccessException("Directory:getAgentAt() ERROR! Index " + i + " outside array bound.");
			}
			AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
			Agent agent = new Agent(agindex.aid, agindex.timestamp, agindex.pos, agindex.type, agindex.bs_timestamp);
			return agent;		
		}

		public Agent findNearestAgent(Agent agent) throws OperationFailedException
		{
			Agent nearestAgent = new Agent();
			double min_dist = INFINITY;
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				double dist;
				if((agent.type.getVal() == AgillaAgentType.UNSPECIFIED || agindex.type.equals(agent.type)) 
						&& agindex.aid != agent.id && (dist = eucDist(agent.pos, agindex.pos)) < min_dist)
				{
					min_dist = dist;
					nearestAgent.id = agindex.aid;
					nearestAgent.pos = agindex.pos;
					nearestAgent.timestamp = agindex.timestamp;
					nearestAgent.type = agindex.type;
				}
			}
			if(min_dist == INFINITY)
				throw new OperationFailedException("Directory.findNearestAgent()! Did not find nearest agent!");
			else
				return nearestAgent;
		}
		
		public Vector<Agent> getAllAgents(AgillaAgentType type){
			Vector<Agent> agents = new Vector<Agent>();
			for(int i = 0; i < agent_list.size(); i++)
			{
				AgentIndex agindex = (AgentIndex)agent_list.elementAt(i);
				if(type.getVal() == AgillaAgentType.UNSPECIFIED || agindex.type.equals(type)){
					Agent agent = new Agent(agindex.aid, agindex.timestamp, agindex.pos, agindex.type, agindex.bs_timestamp);
					agents.add(agent);
				}
			}	
			return agents;
		}
		
		public String getClusterSet(){
			return super.toString();
		}
	}

	class Query
	{
		
		protected QueryType qtype;			// type of query
		private int qid;					// query id, copied from seq number
		private int sid;					// node sending the query
		private int aid;					// agent that issued the query
		private long query_recv_ts;       // time when the query was received
		private long result_recv_ts;      // time when the query result was received
		private boolean queryAllNetworks;	// if true, indicates that the query should be executed in all sensor networks
		private Rectangle area;				// area in which to find agents
		private boolean areaSpecified;		// true if a query area is specified
		
		
		Query()
		{
			sid = aid =  qid = -1;
			area = new Rectangle();
			result_recv_ts = 0;
			qtype = QueryType.UNKNOWN;
			queryAllNetworks = false;
			areaSpecified = false;
			query_recv_ts = (new Date()).getTime();
		}
		
		public String toString(){
			String res = "QueryType: " + qtype.toString() + 
						" QueryID: " + qid + "(" + ((qid >> 8)& 0xff) + ":" + (qid & 0xff) + ")" +
						" Source: " + sid +
						" AgentID: " + aid +
						" QueryReceivedAt: " + query_recv_ts +
						" ResultReceivedAt: " + result_recv_ts +
						" QueryAllNetworks: " + queryAllNetworks;
			if(areaSpecified) res += " QueryArea: " + area.toString();
			return res;
		}
		
		public QueryType getQueryType(){
			return qtype;
		}
		
		public int getQueryId(){
			return qid;
		}
		
		public int getSource(){
			return sid;
		}
		
		public int getAgentId(){
			return aid;
		}
		
		public Rectangle getQueryArea(){
			if(areaSpecified){
				return area;
			} else {
				return null;
			}
		}
		
		public boolean isAreaSpecified(){
			return areaSpecified;
		}
		
		public boolean queryAllNetworks(){
			return queryAllNetworks;
		}
		
		public long getQueryReceiveTime(){
			return query_recv_ts;
		}
		
		public long getResultReceivedTime(){
			return result_recv_ts;
		}
		
		public void setQueryType(QueryType qtype){
			this.qtype = qtype;
		}
		
		public void setQueryId(int qid){
			this.qid = qid;
		}
		
		public void setSource(int sid){
			this.sid = sid;
		}
		
		public void setAgentId(int aid){
			this.aid = aid;
		}
		
		public void setQueryArea(Rectangle area){
			areaSpecified = true;
			this.area = area;
		}
		
		public void setQueryAllNetworks(boolean val){
			queryAllNetworks = val;
		}
		
		public void setQueryReceiveTime(long timestamp){
			query_recv_ts = timestamp;
		}
		
		public void setResultReceivedTime(long timestamp){
			result_recv_ts = timestamp;
		}

	}
	
	class QueryResult{
		private int clusterId;				// Id of the cluster head 
		private Vector<Agent> agentList; 	// agent information obtained from the clusterhead
		private int expectedAgents = 1;
		
		QueryResult(int clusterId){
			this.clusterId = clusterId;
			agentList = new Vector<Agent>();
		}
		
		QueryResult(int chId, int numAgents){
			this.clusterId = chId;
			this.expectedAgents = numAgents;
			agentList = new Vector<Agent>();
		}
		
		QueryResult(int clusterId, Agent agent){
			this.clusterId = clusterId;
			agentList = new Vector<Agent>();
			agentList.add(agent);
		}
		
		public boolean receivedAllAgents(){
			if(agentList.size() >= expectedAgents) return true; else return false;
		}
		
		public void addAgent(Agent agent){
			agentList.add(agent);
		}
		
		public void addAgents(Vector<Agent> agents){
			agentList.addAll(agents);
		}
		
		public int getClusterId(){
			return clusterId;
		}
		
		public int size(){
			return agentList.size();
		}
		
		public Vector<Agent> getAgents(){
			return agentList;
		}
		
		public String toString(){
			String res = "[chId: " + clusterId + " numAgents: "+agentList.size() + " Agents{";
			for(int i = 0; i < agentList.size(); i++){
				res += "\n\t" + agentList.get(i).toString();
			}
			res += "\n}]";
			return res;
		}
	}
	
	class QueryResultList{
		private int numResults;						// total number of clusters from which results should be obtained
		private Vector<QueryResult> resultList;		// list of query results
		
		QueryResultList(){
			numResults = 0;
			resultList = new Vector<QueryResult>();
		}
		
		public int getNumTotalResults(){
			return numResults;
		}
		
		public int getExpectedResults(){
			return numResults - resultList.size();
		}
		
		public boolean receivedAllResults(){
			if(getExpectedResults() == 0){
				for(int i = 0; i < resultList.size(); i++){
					if(!resultList.get(i).receivedAllAgents()) return false;
				}
				return true;
			}
			return false;
		}
		
		public Vector<QueryResult> getResults(){
			return resultList;
		}
		
		public Vector<Agent> getAgents(){
			Vector<Agent> agents = new Vector<Agent>();
			for(int i = 0; i < resultList.size(); i++){
				agents.addAll(resultList.get(i).getAgents());
			}
			return agents;
		}
		
		public void setNumTotalResults(int count){
			numResults = count;
		}
		
		public void addResult(QueryResult result){
			for(int i = 0; i < resultList.size(); i++){
				QueryResult res = resultList.get(i);
				if(res.getClusterId() == result.getClusterId()){
					res.addAgents(result.getAgents());
					return;
				}
			}
			resultList.add(result);
		}

		public int getNumAgents(){
			int count  = 0;
			for(int i = 0; i < resultList.size(); i++){
				count += resultList.get(i).size();
			}
			return count;
		}
		
		public int size(){
			return this.resultList.size();
		}
		
		public void addResult(int chId, Agent agent){
			addResult(new QueryResult(chId, agent));
		}
		
		public QueryResult getResult(int chId){
			for(int i = 0; i < resultList.size(); i++){
				QueryResult result = resultList.get(i);
				if(result.getClusterId() == chId){
					return result;
				}
			}
			return null;
		}
		
		public String toString(){
			String res = "QueryResults[numResults: "+ resultList.size() + " expectedResults: " + getExpectedResults() + " Results{";
			for(int i = 0; i < resultList.size(); i++){
				res += "\n\t" + resultList.get(i).toString();
			}
			res += "\n}]";
			return res;
		}
	}
	
	class NearestAgentQuery extends Query{
		private Pos agentLoc;				// Location of agent issuing the query
		private AgillaAgentType agentType;	// Find agent of this type
		private QueryHandler queryHandler;
		private	QueryResultList resultList;
		private boolean waiting = false;	// set to true when the BE starts waiting for results to this query
		private Timer timer;
		
		NearestAgentQuery(QueryHandler queryHandler){
			super();
			qtype = QueryType.QUERYNEARESTNEIGHBOR;
			agentLoc = new Pos();
			agentType = new AgillaAgentType();
			resultList = new QueryResultList();
			this.queryHandler = queryHandler;
			timer = new Timer();
		}
		
		public void startWaiting(){
			waiting = true;
			timer.schedule(new TimerTask(){
				public void run(){
					print("NearestAgentQueryTimer expired!");
					sendReply();
				}
			}, QUERY_TIMEOUT_INTERVAL);
		}
		
		public void stopWaiting(){
			waiting = false;
			timer.cancel();
		}
		
		public Pos getAgentLoc(){
			return agentLoc;
		}
		
		public AgillaAgentType getAgentType(){
			return agentType;
		}
		
		public void setAgentLoc(Pos pos){
			this.agentLoc = pos;
		}
		
		public void setAgentType(AgillaAgentType type){
			this.agentType = type;
		}
		
		public void setNumberTotalResults(int num){
			resultList.setNumTotalResults(num);
		}
		
		public QueryResultList getResults(){
			return resultList;
		}
		
		public int getNumberResults(){
			return resultList.size();
		}
		
		public void addResult(QueryResult result) throws IllegalOperationException{
			// since this is a nearestneighbor query
			// result should have just 1 agent
			if(result.getAgents().size() <= 0)
				throw new IllegalOperationException("NearestAgentQuery.addResult(): Query result contains no agent information!");
			if(result.getAgents().size() > 1)
				throw new IllegalOperationException("NearestAgentQuery.addResult(): Query result contains more than 1 agent!");
			// make sure that the result is of the required type
			if(!this.agentType.isUnspecified()){
				Vector<Agent> agents = result.getAgents();
				for(int i = 0; i < agents.size(); i++){
					if(!agents.get(i).type.equals(this.agentType))
						throw new IllegalOperationException("NearestAgentQuery.addResult(): Error! agent type does not match required agent type");
				}
			}
			resultList.addResult(result);
			if(waiting && resultList.receivedAllResults()) sendReply();
		}
		
		public void addResult(int chId, Agent agent) throws IllegalOperationException{
			addResult(new QueryResult(chId, agent));
		}
		
		public Vector<Agent> getAgents(){
			return resultList.getAgents();
		}
		
		public int getNumberTotalResults(){
			return resultList.getNumTotalResults();
		}
		
		public String toString(){
			String res = super.toString();
			res += " agentLoc: " + this.agentLoc +
					" agentType: " + agentType.toString() +
					" Results: " + resultList.toString();
			return res;
		}
		
		public Agent getNearestAgent() throws OperationFailedException{
			Agent nearestAgent = new Agent();
			double mindist = INFINITY;
			double dist = 0;
			
			Vector<Agent> agents = resultList.getAgents();
			for(int j = 0; j < agents.size(); j++){
				Agent agent = agents.get(j);
				if((dist = eucDist(agentLoc, agent.pos)) < mindist){
					nearestAgent = agent;
					mindist = dist;
				}
			}
			if(mindist == INFINITY)
				throw new OperationFailedException("NearestAgentQuery.getNearestAgent(): Could not find nearest agent!");
			else
				return nearestAgent;
		}
		
		private void sendReply(){
			timer.cancel();
			queryHandler.sendReply(this);
		}
	} // NearestAgentQuery
	
	class IllegalOperationException extends Exception {
        public IllegalOperationException(String message) {
           super(message);
        }
     }
	
	class OperationFailedException extends Exception {
        public OperationFailedException(String message) {
           super(message);
        }
     }
	
	class AllAgentQuery extends Query{
		private AgillaAgentType agentType;	// Find agents of this type
		private QueryResultList resultList;
		private QueryAllAgentsMsgHandler queryHandler;
		private boolean waiting = false;	// set to true when the BE starts waiting for results to this query
		private Timer timer;
		
		AllAgentQuery(QueryAllAgentsMsgHandler queryHandler){
			super();
			qtype = QueryType.QUERYALL;
			agentType = new AgillaAgentType();
			this.queryHandler = queryHandler;
			timer = new Timer();
			resultList = new QueryResultList();
			System.err.println("AllAgentQuery: created new query");
		}
		
		public AgillaAgentType getAgentType(){
			return agentType;
		}
		
		public void setAgentType(AgillaAgentType type){
			this.agentType = type;
		}
		
		public QueryResultList getResults(){
			return resultList;
		}
		
		public int getNumberResults(){
			return resultList.size();
		}
		
		public int getNumAgents(){
			return resultList.getNumAgents();
		}
		
		public Vector<Agent> getAgents(){
			// different clusters may report that they have the same agent
			// since clusterhead information may be stale
			// hence make sure that the most up-to-date agent information is sent
			Vector<Agent> agents = resultList.getAgents();
			Vector<Agent> result = new Vector<Agent>();
			for(int i = 0; i < agents.size(); i++){
				Agent agent = agents.elementAt(i);
				for(int j = 0; j < result.size(); j++){
					if(result.elementAt(j).id == agent.id){
						if(result.elementAt(j).timestamp > agent.timestamp){
							agent = result.elementAt(j);
						}
						result.remove(j);
						break;
					}
				}
				result.add(agent);
			}
			return result;
		}
		
		public void setNumberTotalResults(int num){
			resultList.setNumTotalResults(num);
		}
		
		public void startWaiting(){
			waiting = true;
			timer.schedule(new TimerTask(){
				public void run(){
					print("AllAgentQueryTimer expired!");
					sendReply();
				}
			}, QUERY_TIMEOUT_INTERVAL);
		}
		
		public void stopWaiting(){
			waiting = false;
			timer.cancel();
		}
		
		public void addResult(QueryResult result) /*throws IllegalOperationException */{
			// make sure that the result is of the required type
			/*if(!this.agentType.isUnspecified()){
				Vector<Agent> agents = result.getAgents();
				for(int i = 0; i < agents.size(); i++){
					if(!agents.get(i).type.equals(this.agentType))
						throw new IllegalOperationException("AllAgentQuery.addResult(): Error! agent type does not match required agent type");
				}
			}*/
			resultList.addResult(result);
			/*
			if(waiting && resultList.receivedAllResults()) {
				print("Received all results, sending query!");
				sendReply();
			}*/
		}
		
		public void addResults(int chId, int num_results, Vector<AgillaLocMAgentInfo> results){
			QueryResult result = resultList.getResult(chId);
			if(result == null){
				// this is the first result from the source
				result = new QueryResult(chId, num_results);
				for(int i = 0; i < results.size(); i++){
					AgillaLocMAgentInfo agentInfo = results.get(i);
					result.addAgent(new Agent(agentInfo.getID().getID(), 0, new Pos(agentInfo.getLoc()), this.agentType));
				}
				debug("AllAgentsQuery.addResults: agent vector size = " + results.size());
				resultList.addResult(result);
			} else {
				for(int i = 0; i < results.size(); i++){
					AgillaLocMAgentInfo agentInfo = results.get(i);
					addResult(new QueryResult(chId, new Agent(agentInfo.getID().getID(), 0, new Pos(agentInfo.getLoc()), this.agentType)));
				}
			}
			
			if(waiting && resultList.receivedAllResults()) {
				print("Received all results, sending query!");
				sendReply();
			}
		}
		
		public void addResult(int chId, Agent agent) throws IllegalOperationException{
			addResult(new QueryResult(chId, agent));
		}
		
		public int getNumberTotalResults(){
			return resultList.getNumTotalResults();
		}
		
		public String toString(){
			String res = super.toString();
			res +=  " agentType: " + agentType.toString() +
					" Results: " + resultList.toString();
			return res;
		}
		
		public void sendReply(){
			timer.cancel();
			
			queryHandler.sendReply(this);
		}
	}
	
	class AgentLocQuery extends Query{
		private int agentId;		// ID of agent whos location is to be found
		private Timer timer;
		private QueryAgentLocMsgHandler queryHandler;
		private Directory dir;
		private Pos pos;
		
		AgentLocQuery(QueryAgentLocMsgHandler queryHandler, Directory dir){
			super();
			agentId = -1;
			qtype = QueryType.QUERYAGENT;
			timer = new Timer();
			this.queryHandler = queryHandler;
			this.dir = dir;
			pos = new Pos();
		}

		public int getRequestedAgentId(){
			return agentId;
		}
		
		public Pos getPos(){
			return pos;
		}
		
		public void setRequestedAgentId(int agentId){
			this.agentId = agentId;
		}
		
		public void startWaiting(){
			timer.schedule(new TimerTask(){
				public void run(){
					print("AgentLocQueryTimer expired!");
					// get agent info from directory
					try{
						pos = dir.getAgent(agentId).pos;
						print("Sending agent location information stored at the base station!");
						sendReply();
					} catch(Exception e){
						print("AgentLocQuery:wait thread: "+e);
					}
					deleteQuery();
				}
			}, QUERY_TIMEOUT_INTERVAL);
		}
		
		public void stopWaiting(){
			timer.cancel();
		}
		
		private void deleteQuery(){
			queryHandler.deleteQuery(this);
		}
		
		private void sendReply(){
			queryHandler.sendReply(this);
		}
	}
	

	class QueryList
	{
		// this is indexed by source id and query id
		Vector<Query> queries;
		
		QueryList(){
			queries = new Vector<Query>();
		}
		
		public void add(Query query) throws IllegalOperationException{
			for(int i = 0; i < queries.size(); i++){
				if(queries.get(i).getQueryId() == query.getQueryId() && queries.get(i).getSource() == query.getSource()) 
					throw new IllegalOperationException("QueryList.add(): ERROR! Query with id already exists from same source!");
			}
			queries.add(query);
		}
		
		public Query get(int queryId) throws IllegalAccessException{
			for(int i = 0; i < queries.size(); i++){
				Query query = queries.get(i);
				if( query.getQueryId() == queryId) 
					return query;
			}
			throw new IllegalAccessException("QueryList.getQuery(): ERROR! could not find query " +queryId);
		}
		
		public int size(){
			return queries.size();
		}
		
		public void remove(int queryId)throws IllegalAccessException{
			for(int i = 0; i < queries.size(); i++){
				Query query = queries.get(i);
				if(query.getQueryId() == queryId){ 
					queries.remove(i);
					return;
				}
			}
			throw new IllegalAccessException("QueryList.remove(): ERROR! could not find query " + queryId);
		}
		
		public String toString(){
			String res = "QueryList: ";
			for(int i = 0; i < queries.size(); i++){
				Query query = queries.get(i);
				res += "\n\t" + query.toString();
			}
			return res;
		}
	}


	

	class LocMsgHandler implements MessageListenerJ 
	{
		SNInterface sni;
		
		LocMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaLocMsgJ(), this);
			debug("LocMsgHandler started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			print("Received location message: " + msg);
			AgillaLocMsgJ locMsg = (AgillaLocMsgJ)msg;
			Cluster cl = new Cluster(locMsg.src(), AGENT_INFO_TIMEOUT);
			Pos pos = new Pos(locMsg.loc());
			Agent agent = new Agent(locMsg.id().getID(), locMsg.time(), pos, locMsg.agentType());
			if(locMsg.loc().getx() == 0 && locMsg.loc().gety() == 0 && locMsg.time() == 0)
			{
				// Agent has moved or is dead; delete agent
				try{
					directory.deleteAgent(agent);
				} catch (IllegalAccessException e){
					System.err.println("LocMsgHandler: " + e);
				}
			} 
			else 
			{
				// agent discovered at a node

				directory.addAgent(cl, agent);
			}
			print(directory.toString());
		}
	}
	
	interface QueryHandler{
		void sendReply(Query query);
		void deleteQuery(Query query);
	}

	class QueryNumAgentsMsgHandler implements MessageListenerJ {
		SNInterface sni;
		
		QueryNumAgentsMsgHandler(SNInterface sni) {
			this.sni = sni;
			sni.registerListener(new AgillaQueryNumAgentsMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) {
			dbg("Received NumAgents query message: " + msg);
			AgillaQueryNumAgentsMsgJ queryMsg = (AgillaQueryNumAgentsMsgJ)msg;
			
			// create query reply message
			AgillaQueryReplyNumAgentsMsgJ queryReplyMsg = 
				new AgillaQueryReplyNumAgentsMsgJ(queryMsg.id(), 
						queryMsg.src(), queryMsg.qid(), QueryReplyConstants.VALID, 
						(short)directory.size(queryMsg.agentType()));
			// send query reply
			perr("Sending QueryReplyNumAgentsMsg: " + queryReplyMsg);
			try
			{
				sni.send(queryReplyMsg/*, queryMsg.src()*/);
			}
			catch(Exception e)
			{
				perr("Error! could not send QueryReplyNumAgentsMsg: "+ e);
			}
		}
		
		private void dbg(String msg) { 	debug("QueryNumAgentsMsgHandler: " + msg); }		
		private void perr(String msg) { print("QueryNumAgentsMsgHandler: " + msg); }

	}

	class QueryAgentLocMsgHandler implements QueryHandler, MessageListenerJ 
	{
		SNInterface sni;
		
		QueryAgentLocMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaQueryAgentLocMsgJ(), this);
			dbg("Started!");
		}
		
		private AgillaQueryReplyAgentLocMsgJ genErrorReply(AgillaQueryAgentLocMsgJ queryMsg) {
			return new AgillaQueryReplyAgentLocMsgJ(queryMsg.id(), 
					queryMsg.src(), queryMsg.qid(), QueryReplyConstants.INVALID, 
					new AgillaLocation(0, 0), networkName);	
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received AgentLoc query message: " + msg);
			AgillaQueryAgentLocMsgJ queryMsg = (AgillaQueryAgentLocMsgJ)msg;
						
			MessageJ sendMsg = null;  // this is the message to send at the end of this method
			
			if(!ENABLE_CLUSTERING) {
				// create query reply message
				try {
					Agent agent = directory.getAgent(queryMsg.find_agent_id().getID());
					sendMsg = new AgillaQueryReplyAgentLocMsgJ(queryMsg.id(), 
							queryMsg.src(), queryMsg.qid(), QueryReplyConstants.VALID, 
							new AgillaLocation((int)agent.pos.x, (int)agent.pos.y), networkName);
				} catch (IllegalAccessException e) {						
					print(e.toString());  // could not get the Agent			
					sendMsg = genErrorReply(queryMsg);
				}
			} else {
				// Find which cluster the agent is in.
				// If the agent is in the GW's cluster or the data is till considered fresh, send the result
				// else forward the query to the cluster that has the agent.
				try {
					AgentIndex agindex = directory.getAgentIndex(queryMsg.find_agent_id().getID());
					long curTime = (new Date()).getTime();
					
					if((agindex.ch_id == GW_ID) || ((curTime - agindex.bs_timestamp) <= AGENT_LOC_FRESHNESS_INTERVAL)) {
						// send query reply
						sendMsg = new AgillaQueryReplyAgentLocMsgJ(queryMsg.id(), 
								queryMsg.src(), queryMsg.qid(), QueryReplyConstants.VALID, 
								new AgillaLocation((int)agindex.pos.x, (int)agindex.pos.y), networkName);					
					} else {
						// store query
						AgentLocQuery query = new AgentLocQuery(this, directory);
						query.setAgentId(queryMsg.id().getID());
						query.setSource(queryMsg.src());
						query.setQueryId(queryMsg.qid());
						query.setRequestedAgentId(queryMsg.find_agent_id().getID());
						query.setQueryAllNetworks(queryMsg.queryAllNetworks());
						query.startWaiting();
						queryList.add(query);
						// forward query to clusterhead that reported the agent
						sendMsg = new AgillaQueryAgentLocMsgJ(queryMsg.id(), AgillaConstants.TOS_LOCAL_ADDRESS , 
								agindex.ch_id, queryMsg.qid(), queryMsg.flags(), queryMsg.find_agent_id());
					}
				} catch (IllegalAccessException iae) {
					perr("Could not get the AgentIndex object, replying with an error.\n" + iae);		
				} catch (IllegalOperationException ioe) {
					perr("Could not add query to queryList.\n" + ioe); 
				} 
				/*catch (Exception e){
					System.err.println("Error in handling QueryAgentLocMsg: "+ e);
				}*/
			}
			
			if (sendMsg == null)
				sendMsg = genErrorReply(queryMsg);
			
			// Send the message (this either replies to the agent issuing the query or 
			// forwards the query to the appropriate cluster head)
			dbg("Sending message: " + sendMsg);
			try {
				sni.send(sendMsg/*, queryMsg.src()*/);
			}
			catch(java.io.IOException e) {
				perr("Could not send message: " + e);
			}			
		}
		
		/*
		 *  This method is called only if the query has failed to receive the agent location from the cluster head of 
		 *  the cluster the agent is in. In that case agent location information stored at the base station is sent.
		 * @see agilla.LocationManager.QueryHandler#sendReply(agilla.LocationManager.Query)
		 */
		public void sendReply(Query query){
			AgentLocQuery locQuery = (AgentLocQuery)query;
			AgillaQueryReplyAgentLocMsgJ queryReplyMsg = 
				new AgillaQueryReplyAgentLocMsgJ(new AgillaAgentID(query.getAgentId()), 
					query.getSource(), query.getQueryId(), 
					QueryReplyConstants.VALID | QueryReplyConstants.COARSE, 
					new AgillaLocation((int)locQuery.getPos().x, (int)locQuery.getPos().y), networkName);
				// send query reply
			dbg("Sending QueryReplyAgentLocMsg: " + queryReplyMsg);
			try
			{
				sni.send(queryReplyMsg/*, queryMsg.src()*/);
			}
			catch(Exception e)
			{
				perr("Could not send QueryReplyAgentLocMsg: "+ e);
			}
		}
		
		/**
		 *  Removes the specified query from the query list.
		 */
		public void deleteQuery(Query query){
			try{
				queryList.remove(query.getQueryId());
			} catch (Exception e){
				perr("deleteQuery: " + e);
			}
		}
		
		private void dbg(String msg) { 	debug("QueryAgentLocMsgHandler: " + msg); }
		private void perr(String msg) { print("QueryAgentLocMsgHandler: " + msg); }
	} // QueryAgentLocMsgHandler
	
	class QueryReplyAgentLocMsgHandler implements MessageListenerJ {
		SNInterface sni;
		
		QueryReplyAgentLocMsgHandler(SNInterface sni) {
			this.sni = sni;
			sni.registerListener(new AgillaQueryReplyAgentLocMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) {
			dbg("Received AgentLoc query reply message: " + msg);
			AgillaQueryReplyAgentLocMsgJ replyMsg = (AgillaQueryReplyAgentLocMsgJ)msg;
			// find the corresponding query and send the reply to the querying node
			// then delete the query
			try{
				AgentLocQuery query = (AgentLocQuery)queryList.get(replyMsg.qid());
				assert query.getQueryType() == QueryType.QUERYAGENT;
				query.stopWaiting();
				queryList.remove(replyMsg.qid());
				// send query reply
				AgillaQueryReplyAgentLocMsgJ queryReplyMsg = new AgillaQueryReplyAgentLocMsgJ(replyMsg.id(), 
						query.getSource(), replyMsg.qid(), QueryReplyConstants.VALID, replyMsg.loc(), networkName);
				
				dbg("Sending QueryReplyAgentLocMsg: " + queryReplyMsg);
				try {
					sni.send(queryReplyMsg/*, queryMsg.src()*/);
				}
				catch(Exception e) {
					perr("Could not send QueryReplyAgentLocMsg: "+ e);
				}			
			} catch (Exception e){
				perr("Error in handling QueryReplyAgentLocMsg! "+ e);
			}
		}

		private void dbg(String msg) { 	debug("QueryReplyAgentLocMsgHandler: " + msg); }		
		private void perr(String msg) { print("QueryReplyAgentLocMsgHandler: " + msg); }
	}
	
	class ClusterInfo{
		Cluster cluster;
		double minDist;
		double maxDist;
		
		ClusterInfo(Cluster cluster, double minDist, double maxDist){
			this.cluster = cluster;
			this.minDist = minDist;
			this.maxDist = maxDist;
		}
	}

	class QueryNearestAgentMsgHandler implements QueryHandler, MessageListenerJ 
	{
		SNInterface sni;
		
		QueryNearestAgentMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaQueryNearestAgentMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received NearestAgent query message: " + msg);
			AgillaQueryNearestAgentMsgJ queryMsg = (AgillaQueryNearestAgentMsgJ)msg;
			if(!ENABLE_CLUSTERING)
			{
				try
				{
					Agent agent = new Agent(queryMsg.id().getID(), 0, new Pos(queryMsg.loc()), queryMsg.agentType());
					Agent nearestAgent = directory.findNearestAgent(agent);
					// create query reply message
					sendLocalReply(nearestAgent, queryMsg);
				}
				catch(Exception e)
				{
					perr("Error! could not send QueryReplyNearestAgentMsg: "+ e);
				}
			} else
			{
				AgillaAgentType agentType = queryMsg.agentType();
				if(queryMsg.src() == GW_ID) 
				{
					// received request from agent in GW nodes cluster
					// hence resolve result locally and send result
					Cluster cluster = directory.getCluster(GW_ID);
					if(cluster.getNumAgents(agentType) > 0)
					{
						try
						{
							Agent nearestAgent = cluster.findNearestAgent(queryMsg.id().getID(), agentType, new Pos(queryMsg.loc()));
							try
							{
								// create query reply message
								sendLocalReply(nearestAgent, queryMsg);
							} catch (Exception e)
							{
								perr("Could not send QueryReplyNearestAgentMsg: ");
								return;
							}
							return;
						} catch (Exception e){
							perr("Did not find nearest agent on GW!");
						}
					}
				}

				try{
					// figure out which clusters to send query to
					// check if there are other agents in the system
					
					int totalResults = 0, expectedResults = 0;
					if(directory.size(agentType) > 1){
						// iterate through clusters and decide which clusters to forward the query to
						NearestAgentQuery nearestAgentQuery = new NearestAgentQuery(this);
						nearestAgentQuery.setAgentId(queryMsg.id().getID());
						nearestAgentQuery.setQueryId(queryMsg.qid());
						nearestAgentQuery.setSource(queryMsg.src());
						nearestAgentQuery.setAgentLoc(new Pos(queryMsg.loc()));
						nearestAgentQuery.setAgentType(agentType);
						nearestAgentQuery.setQueryAllNetworks(queryMsg.queryAllNetworks());
						Vector<Cluster> clusters = directory.getClusters();
						// sort clusters according to min-max dist of bounding box from querying agent position
						Vector<ClusterInfo> sortedClusters = new Vector<ClusterInfo>();
						for(int i = 0; i < clusters.size(); i++){
							// find min-max dist from bounding-box
							Cluster cluster = clusters.get(i);
							// do not look at cluster that sent the request
							if(cluster.getId() == queryMsg.src()) continue;
							if(cluster.getNumAgents(agentType) <= 0) continue;
							Rectangle boundingBox = cluster.getBoundingBox();
							Pos agentPos = new Pos(queryMsg.loc());
							double minx, miny, maxx, maxy, minDist, maxDist;
							// check if point is in the box
							if(agentPos.x < boundingBox.p1.x)
								minx = boundingBox.p1.x - agentPos.x;
							else if(agentPos.x > boundingBox.p2.x)
								minx = agentPos.x - boundingBox.p2.x;
							else
								minx = 0;
							if(agentPos.y < boundingBox.p1.y)
								miny = boundingBox.p1.y - agentPos.y;
							else if(agentPos.y > boundingBox.p2.y)
								miny = agentPos.y - boundingBox.p2.y;								
							else
								miny = 0;
							if(agentPos.x < ((boundingBox.p1.x + boundingBox.p2.x)/2))
								maxx = boundingBox.p2.x - agentPos.x;
							else
								maxx = agentPos.x - boundingBox.p1.x;
							if(agentPos.y < ((boundingBox.p1.y+ boundingBox.p2.y)/2))
								maxy = boundingBox.p2.y - agentPos.y;
							else
								maxy = agentPos.y - boundingBox.p1.y;
							minDist = Math.sqrt(minx*minx + miny*miny);
							maxDist = Math.sqrt(maxx*maxx + maxy*maxy);
							ClusterInfo clusterInfo = new ClusterInfo(cluster, minDist, maxDist);
							int j = 0;
							for(; j < sortedClusters.size() 
								&& minDist > sortedClusters.get(j).minDist; j++);
							sortedClusters.insertElementAt(clusterInfo, j);
						}
						if(DEBUG){
							dbg("Sorted Cluster list: ");
							for(int i = 0; i < sortedClusters.size(); i++){
								ClusterInfo clusterInfo = sortedClusters.get(i);
								dbg("\t"+clusterInfo.cluster.getId()+": ["+clusterInfo.minDist+","+clusterInfo.maxDist+"]");
							}
						}
						for(int i = 0; i < sortedClusters.size(); i++){
							// check only clusters that overlap the nearest cluster
							if(i > 0 && sortedClusters.get(i).minDist > sortedClusters.firstElement().maxDist)
								break;
							Cluster cluster = sortedClusters.get(i).cluster;
							dbg("Searching cluster "+cluster.getId());
							if(cluster.getNumAgents(agentType) > 0){
								// this cluster has some agents
								if(cluster.getId() == GW_ID || cluster.allAgentDataFresh(agentType)){
									// agent info is still considered fresh
									// insert the agent info into the temporary result
									// find nearest agent
									try{
										Agent nearestAgent = cluster.findNearestAgent(queryMsg.id().getID(), agentType, new Pos(queryMsg.loc()));
										// insert result into query
										nearestAgentQuery.addResult(cluster.getId(), nearestAgent);
										
										dbg("Cluster "+cluster.getId()+" is GW or has up-to-date agent location information!");
									} catch (Exception e) {
										// do nothing
									}
								} else {
									// this cluster has agents but agent info is not fresh
									// hence forward query to clusterhead
									
									AgillaQueryNearestAgentMsgJ newQueryMsg = 
										new AgillaQueryNearestAgentMsgJ(queryMsg.id(), AgillaConstants.TOS_LOCAL_ADDRESS, 
												cluster.getId(), queryMsg.qid(), queryMsg.flags(), 
												queryMsg.loc(), agentType);
										dbg("Forwarding QueryNearestAgentMsg: "+newQueryMsg);
									try
									{
										sni.send(newQueryMsg);
										expectedResults++;
									} catch (Exception e){
										perr("QueryNearestAgentMsgHandler: Failed to forward query msg to clusterhead "+
												cluster.getId());
									}
								}
								totalResults++;
							}
						}
						if(expectedResults > 0){
							// wait for results
							nearestAgentQuery.startWaiting();
							// save the query
							nearestAgentQuery.setNumberTotalResults(totalResults);
							queryList.add(nearestAgentQuery);
						} else if(nearestAgentQuery.getNumberResults() > 0) {
							// the query has some results which should be sent to the requesting clusterhead
							sendReply(nearestAgentQuery);
						}
					} else {
						dbg("No agents of type "+ agentType + " found in the directory!");
					}
				} catch (Exception e){
					perr("QueryNearestAgentMsgHandler.messageReceived(): " + e);
				}
			}
		}
		
		/**
		 * This is called when no clustering is used, or when this is the cluster head
		 * responding to the query.
		 * 
		 * @param nearestAgent  The nearest agent.
		 * @param queryMsg The query message to respond to.
		 */
		public void sendLocalReply(Agent nearestAgent, AgillaQueryNearestAgentMsgJ queryMsg){
			try
			{
				// create query reply message
				AgillaQueryReplyNearestAgentMsgJ queryReplyMsg = 
					new AgillaQueryReplyNearestAgentMsgJ(queryMsg.id(), AgillaConstants.TOS_LOCAL_ADDRESS,
						queryMsg.src(), queryMsg.qid(), QueryReplyConstants.VALID, 
						new AgillaAgentID(nearestAgent.id), 
						new AgillaLocation((int)nearestAgent.pos.x, (int)nearestAgent.pos.y));
				sni.send(queryReplyMsg/*, queryMsg.src()*/);
				print("Sending QueryReplyNearestAgentMsg: " + queryReplyMsg);
			}
			catch(Exception e)
			{
				print("Error! could not send QueryReplyNearestAgentMsg: "+ e);
			}
		}
		
		/**
		 * Create a AgillaQueryReplyNearestAgentMsgJ.
		 * 
		 * @param query  The NearestAgentQuery to respond to.
		 * @param nearestAgent The nearest agent to include in the response.
		 * @return The new AgillaQueryReplyNearestAgentMsgJ.
		 */
		private AgillaQueryReplyNearestAgentMsgJ createReply(NearestAgentQuery query, Agent nearestAgent, int flags) {
			return new AgillaQueryReplyNearestAgentMsgJ(new AgillaAgentID(query.getAgentId()), 
					AgillaConstants.TOS_LOCAL_ADDRESS, query.getSource(), query.getQueryId(),
					flags,
					new AgillaAgentID(nearestAgent.id),  
					new AgillaLocation((int)nearestAgent.pos.x, (int)nearestAgent.pos.y));
		}
		
		/**
		 * This can be called wither when the timer fires within NearestAgentQuery
		 * or when all of the results are received.
		 */
		public void sendReply(Query query){
			NearestAgentQuery nearestAgentQuery = (NearestAgentQuery)query;
			try {
				//	remove query from list
				nearestAgentQuery.stopWaiting();
				try {
					queryList.remove(query.getQueryId());
				} catch (Exception e){
					perr("Failed to remove query "+query.getQueryId());
				}
				
				AgillaQueryReplyNearestAgentMsgJ queryReplyMsg = null;
				try {
//					Agent nearestAgent = ;
					queryReplyMsg = createReply(nearestAgentQuery, nearestAgentQuery.getNearestAgent(), 
							QueryReplyConstants.VALID);
//					new AgillaQueryReplyNearestAgentMsgJ(new AgillaAgentID(query.getAgentId()), 
//							AgillaConstants.TOS_LOCAL_ADDRESS, query.getSource(), query.getQueryId(),
//							QueryReplyConstants.VALID,
//							new AgillaAgentID(nearestAgent.id),  
//							new AgillaLocation((int)nearestAgent.pos.x, (int)nearestAgent.pos.y));
				} catch (Exception e){
					// no query result received
					// reply based on information stored at base station
					Agent agent = new Agent(query.getAgentId(), 0, nearestAgentQuery.getAgentLoc(), nearestAgentQuery.getAgentType());
					try {
						queryReplyMsg = createReply(nearestAgentQuery, directory.findNearestAgent(agent), 
								QueryReplyConstants.COARSE);
//						Agent nearestAgent = directory.findNearestAgent(agent);
//						queryReplyMsg = new AgillaQueryReplyNearestAgentMsgJ(new AgillaAgentID(query.getAgentId()), 
//								AgillaConstants.TOS_LOCAL_ADDRESS, query.getSource(), query.getQueryId(),
//								QueryReplyConstants.COARSE,
//								new AgillaAgentID(nearestAgent.id),  
//								new AgillaLocation((int)nearestAgent.pos.x, (int)nearestAgent.pos.y));
					} catch (Exception ex){
						// no agent found in the directory
						perr("No agent found in directory. " + ex);
					}
				}
				
				// By default send an INVALID results message to the querier
				if (queryReplyMsg == null)
					queryReplyMsg = new AgillaQueryReplyNearestAgentMsgJ(new AgillaAgentID(query.getAgentId()), 
							AgillaConstants.TOS_LOCAL_ADDRESS, query.getSource(), query.getQueryId(),
							QueryReplyConstants.INVALID,
							new AgillaAgentID(0), new AgillaLocation(0, 0));
				
				// send query reply
				sni.send(queryReplyMsg/*, queryMsg.src()*/);
				print("Sending QueryReplyNearestAgentMsg: " + queryReplyMsg);
			}
			catch(Exception e)
			{
				print("Error! could not send QueryReplyNearestAgentMsg: "+ e);
			}
		}
		
		public void deleteQuery(Query query){
			try{
				queryList.remove(query.getQueryId());
			} catch (Exception e){
				print("QueryNearestAgentMsgHandler.deleteQuery:"+e);
			}
		}
		
		private void dbg(String msg) { 	debug("QueryNearestAgentMsgHandler: " + msg); }
		private void perr(String msg) { print("QueryNearestAgentMsgHandler: " + msg); }
	} // QueryNearestAgentMsgHandler
	
	class QueryReplyNearestAgentMsgHandler implements MessageListenerJ{
		SNInterface sni;
		
		QueryReplyNearestAgentMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaQueryReplyNearestAgentMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received NearestAgent query reply message: " + msg);
			AgillaQueryReplyNearestAgentMsgJ replyMsg = (AgillaQueryReplyNearestAgentMsgJ)msg;
			// find the corresponding query and send the reply to the querying node
			// then delete the query
			try{
				NearestAgentQuery query = (NearestAgentQuery)queryList.get(replyMsg.qid());
				assert query.getQueryType() == QueryType.QUERYNEARESTNEIGHBOR;
				// store the result
				query.addResult(replyMsg.src(), new Agent(replyMsg.nearestAgentId().getID(), 0, 
						new Pos(replyMsg.nearestAgentLoc()), query.getAgentType()));
			} catch (Exception e){
				perr("Error in handling QueryReplyAgentLocMsg! "+ e);
			}
		}
		
		private void dbg(String msg) { 	debug("QueryReplyNearestAgentMsgHandler: " + msg); }
		private void perr(String msg) { print("QueryReplyNearestAgentMsgHandler: " + msg); }
	} // QueryReplyNearestAgentMsgHandler

	class QueryAllAgentsMsgHandler implements QueryHandler, MessageListenerJ 
	{
		SNInterface sni;
		
		QueryAllAgentsMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaQueryAllAgentsMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received AllAgents query message: " + msg);
			AgillaQueryAllAgentsMsgJ queryMsg = (AgillaQueryAllAgentsMsgJ)msg;
			if(!ENABLE_CLUSTERING){
				Vector<Agent> agents = directory.getAllAgents(queryMsg.agentType());
				sendQueryResult(agents, queryMsg.id(), queryMsg.src(), queryMsg.qid());
			} else {
				try{
					dbg("Processing query message ...");
					int totalResults = 0, expectedResults = 0;
					AllAgentQuery query = new AllAgentQuery(this);
					query.setAgentId(queryMsg.id().getID());
					query.setSource(queryMsg.src());
					query.setQueryId(queryMsg.qid());
					AgillaAgentType agentType = queryMsg.agentType();
					query.setAgentType(agentType);
					dbg("agent type is " + agentType.toString());
					query.setQueryAllNetworks((queryMsg.flags()&0x1) == 0? false:true);
					dbg("Created AllAgentQuery: "+query.toString());
					Vector<Cluster> clusters = directory.getClusters();
					dbg("Number of clusters = " + clusters.size());
					for(int i = 0; i < clusters.size(); i++){
						
						Cluster cluster = clusters.get(i);
						dbg("Number of agents of specified agent type = " + cluster.getNumAgents(agentType));
						if(cluster.getNumAgents(agentType) > 0){
							dbg("Processing cluster "+cluster.getId());
							if(cluster.getId() == GW_ID || cluster.allAgentDataFresh(agentType))
							{
								QueryResult queryResult = new QueryResult(cluster.getId());
								queryResult.addAgents(cluster.getAgents(agentType));
								query.addResult(queryResult);
								
							} else {
								// need to query clusterhead for agent locations
								// forward query to clusterhead
								
								AgillaQueryAllAgentsMsgJ newQueryMsg = 
										new AgillaQueryAllAgentsMsgJ(queryMsg.id(), AgillaConstants.TOS_LOCAL_ADDRESS, cluster.getId(), 
												queryMsg.qid(), queryMsg.flags(), agentType);
								dbg("Forwarding QueryAllAgentsMsg: "+newQueryMsg);									
								try
								{
									sni.send(newQueryMsg/*, queryMsg.src()*/);
									expectedResults++;
								}
								catch(Exception e)
								{
									perr("Error! could not forward QueryAllAgentsMsg: "+ e);
								}
							}
							totalResults++;
						}
					}
					if(expectedResults == 0){
						// send query result
						dbg("Expected results = 0");
						if(query.getNumberResults() > 0) this.sendReply(query);
					} else {
						// save query
						dbg("Saving query and waiting for results");
						query.setNumberTotalResults(totalResults);
						query.startWaiting();
						queryList.add(query);
					}
				} catch (Exception e){
					perr("QueryAllAgentsMsgHandler: " +e);
				}
			}			
		}		
		
		public void sendQueryResult(Vector<Agent> agents, AgillaAgentID agentId, int dest, int qid){
			
			int total_agents = agents.size();
			if(total_agents <= 0) return;
			int count = (int)Math.ceil((double)total_agents/(double)AgillaQueryReplyAllAgentsMsgJ.MAX_NUM_AGENTS);
			dbg("Total_agents = "+ total_agents + " count = " + count);
			int num_agents = total_agents;
			int index = 0;
			for(int i = 0; i < count; i++){
				boolean test = (num_agents > 0);
				assert test;
				// create query reply message
				AgillaQueryReplyAllAgentsMsgJ queryReplyMsg = new AgillaQueryReplyAllAgentsMsgJ(agentId, 
						AgillaConstants.TOS_LOCAL_ADDRESS,	dest, qid, QueryReplyConstants.VALID, num_agents);
				// send query reply
				
				int num_elements = num_agents;
				if(num_elements > AgillaQueryReplyAllAgentsMsgJ.MAX_NUM_AGENTS)
					num_elements = AgillaQueryReplyAllAgentsMsgJ.MAX_NUM_AGENTS;
				for(int j = 0; j < num_elements; j++){
					try{
						Agent agent = agents.get(index++);
						queryReplyMsg.addAgentInfo(agent.id, (int)agent.pos.x, (int)agent.pos.y);
					} catch (IllegalAccessException e){
						System.out.println(e);
					}
				}
				try
				{
					sni.send(queryReplyMsg/*, dest*/);
					perr("Sending QueryReplyAllAgentsMsg: " + queryReplyMsg);
				}
				catch(Exception e)
				{
					perr("Could not send QueryReplyAllAgentsMsg: "+ e);
				}
				num_agents -= AgillaQueryReplyAllAgentsMsgJ.MAX_NUM_AGENTS;
			}
			boolean test = (index == total_agents);
			assert test;
		}
		
		public void sendReply(Query query){
			AllAgentQuery allAgentQuery = (AllAgentQuery)query;
			this.sendQueryResult(allAgentQuery.getAgents(), new AgillaAgentID(allAgentQuery.getAgentId()), 
					allAgentQuery.getSource(), allAgentQuery.getQueryId());
			try
			{
				allAgentQuery.stopWaiting();
				// remove query from list
				queryList.remove(allAgentQuery.getQueryId());
			} catch(Exception e) {}
		}
		
		public void deleteQuery(Query query){
			try{
				queryList.remove(query.getQueryId());
			} catch (Exception e){
				perr("deleteQuery: " + e);
			}
		}
		
		private void dbg(String msg) { 	debug("QueryAllAgentsMsgHandler: " + msg); }
		private void perr(String msg) { print("QueryAllAgentsMsgHandler: " + msg); }
	} // QueryAllAgentsMsgHandler
	
	class QueryReplyAllAgentsMsgHandler implements MessageListenerJ{
		SNInterface sni;
		
		QueryReplyAllAgentsMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaQueryReplyAllAgentsMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received AllAgents query reply message: " + msg);
			AgillaQueryReplyAllAgentsMsgJ replyMsg = (AgillaQueryReplyAllAgentsMsgJ)msg;
			// find the corresponding query and send the reply to the querying node
			// then delete the query
			try{
				AllAgentQuery query = (AllAgentQuery)queryList.get(replyMsg.qid());
				assert query.getQueryType() == QueryType.QUERYALL;
				// store the result
				Vector<AgillaLocMAgentInfo> agentInfoList = replyMsg.getAgentInfo();
				query.addResults(replyMsg.src(), replyMsg.num_agents(), agentInfoList);
				dbg(query.toString());
				/*
				for(int i = 0; i < agentInfoList.size(); i++){
					AgillaLocMAgentInfo agentInfo = agentInfoList.get(i);
					query.addResult(replyMsg.src(), new Agent(agentInfo.getID().getID(), 0, new Pos(agentInfo.getLoc()), query.getAgentType()));
				}*/
			} catch (Exception e){
				perr("Error in handling QueryReplyAgentLocMsg! "+ e);
			}
		}

		private void dbg(String msg) { 	debug("QueryReplyAllAgentsMsgHandler: " + msg); }
		private void perr(String msg) { print("QueryReplyAllAgentsMsgHandler: " + msg); }
	} // QueryReplyAllAgentsMsgHandler

	
	class ClusterMsgHandler implements MessageListenerJ 
	{
		SNInterface sni;
		
		ClusterMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaClusterMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			dbg("Received cluster message: " + msg);
			AgillaClusterMsgJ clusterMsg = (AgillaClusterMsgJ)msg;
			Cluster cl = new Cluster(clusterMsg.chId(), new Rectangle(clusterMsg.boundingBox()), AGENT_INFO_TIMEOUT);
			if(cl.bounding_box.isZero())
			{
				// Clusterhead stepped down; remove clusterhead
				try{
					directory.deleteCluster(clusterMsg.chId());
					dbg("Deleting cluster "+clusterMsg.chId());
				} catch (IllegalAccessException e){
					perr(e.toString());
				}
			} 
			else 
			{
				// new cluster
				directory.addCluster(cl);
			}
			
			dbg(directory.getClusterSet());
		}
		
		private void dbg(String msg) { 	debug("ClusterMsgHandler: " + msg); }
		private void perr(String msg) { print("ClusterMsgHandler: " + msg); }
	} // ClusterMsgHandler
	
	class ClusterDebugMsgHandler implements MessageListenerJ 
	{
		SNInterface sni;
		
		ClusterDebugMsgHandler(SNInterface sni) 
		{
			this.sni = sni;
			sni.registerListener(new AgillaClusterDebugMsgJ(), this);
			dbg("Started!");
		}

		public void messageReceived(int dest, MessageJ msg) 
		{
			perr("------------------Received cluster debug message------------------------\n" + msg);
			
		}
		
		private void dbg(String msg) { 	debug("ClusterDebugMsgHandler: " + msg); }
		private void perr(String msg) { print("ClusterDebugMsgHandler: " + msg); }
	} // ClusterDebugMsgHandler

	/*
	 * Location Manager methods
	 */
	
	public double eucDist(Pos src, Pos dst)
	{
		return Math.sqrt(Math.pow((src.x - dst.x) , 2.0) + Math.pow((src.y - dst.y) , 2.0));
	}
	

	public void reset(int addr){
		// clear directory
		if (addr == TOS_BCAST_ADDRESS)
			directory.clear();
		else
			directory.clear(addr);
		/*
		try {
			Thread.sleep(3000);  // pause for 3 seconds to allow motes to reset
		} catch(Exception e) {
			e.printStackTrace();
		}*/
	}
	
	public void print(String printString){
		System.err.println("["+(new Date()).getTime()+"] "+printString);
	}
	
	public void debug(String printString){
		if(DEBUG) print(printString);
	}
	
	public LocationManager(SNInterface sni) 
	{
		this.sni = sni;
		me = new Node();
		me.id = 0;
		me.pos = new Pos();
		kmin = 0;
		kmax = 0;
		t0 = 0;
		max_agent_speed = 0;
		directory = new Directory();
		queryList = new QueryList();
		locMsgHandler = new LocMsgHandler(sni);
		queryNumAgentsMsgHandler = new QueryNumAgentsMsgHandler(sni);
		queryAgentLocMsgHandler = new QueryAgentLocMsgHandler(sni);
		queryNearestAgentMsgHandler = new QueryNearestAgentMsgHandler(sni);
		queryAllAgentsMsgHandler = new QueryAllAgentsMsgHandler(sni);
		queryReplyAgentLocMsgHandler = new QueryReplyAgentLocMsgHandler(sni);
		queryReplyNearestAgentMsgHandler = new QueryReplyNearestAgentMsgHandler(sni);
		queryReplyAllAgentsMsgHandler = new QueryReplyAllAgentsMsgHandler(sni);
		clusterMsgHandler = new ClusterMsgHandler(sni);
		networkName = new AgillaString(agilla.AgillaProperties.networkName());
		clusterDebugMsgHandler = new ClusterDebugMsgHandler(sni);
	}
	
	public LocationManager(SNInterface sni, int id, Pos pos, int kmin, int kmax, double aspeed) 
	{
		this.sni = sni;
		me = new Node();
		me.id = id;
		me.pos = pos;
		this.kmin = kmin;
		this.kmax = kmax;
		t0 = 0;
		max_agent_speed = aspeed;
		directory = new Directory();
		queryList = new QueryList();
		locMsgHandler = new LocMsgHandler(sni);
		queryNumAgentsMsgHandler = new QueryNumAgentsMsgHandler(sni);
		queryAgentLocMsgHandler = new QueryAgentLocMsgHandler(sni);
		queryNearestAgentMsgHandler = new QueryNearestAgentMsgHandler(sni);
		queryAllAgentsMsgHandler = new QueryAllAgentsMsgHandler(sni);
		queryReplyAgentLocMsgHandler = new QueryReplyAgentLocMsgHandler(sni);
		queryReplyNearestAgentMsgHandler = new QueryReplyNearestAgentMsgHandler(sni);
		queryReplyAllAgentsMsgHandler = new QueryReplyAllAgentsMsgHandler(sni);
		networkName = new AgillaString(agilla.AgillaProperties.networkName());
		clusterDebugMsgHandler = new ClusterDebugMsgHandler(sni);
	}

	
}
