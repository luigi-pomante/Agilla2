module ExpLoggerM
{
	provides {
	interface StdControl;
	interface ExpLoggerI;
	}
	uses {
	interface SendMsg as SendResults;
	interface SendMsg as SendLatency;
	interface SendMsg as SendTrace;
	interface SendMsg as SendGetAgentsResultsTrace;
	//interface ReceiveMsg as ReceiveQuery;
	interface MessageBufferI;
	interface Time;
	}
}
implementation {

	//uint16_t _numQueries, _numUpdates, _numReplies;

	command result_t StdControl.init() {
	call ExpLoggerI.reset();
	return SUCCESS;
	}

	command result_t StdControl.start() {
	return SUCCESS;
	}

	command result_t StdControl.stop() {
	return SUCCESS;
	}

	command result_t ExpLoggerI.reset() {
	/*_numQueries = 0;
	_numUpdates = 0;
	_numReplies = 0;*/
	return SUCCESS;
	}

/*	command result_t ExpLoggerI.incQueryMsg() {
	_numQueries++;
	return SUCCESS;
	}

	command result_t ExpLoggerI.incNumUpdates() {
	_numUpdates++;
	return SUCCESS;
	}
	
	command result_t ExpLoggerI.incNumReplies() {
	_numReplies++;
	return SUCCESS;
	}
*/

	command result_t ExpLoggerI.sendQueryLatency(uint32_t latency) {
	TOS_MsgPtr msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		struct AgillaExpLatencyMsg *lMsg = (struct AgillaExpLatencyMsg *)msg->data;
		lMsg->latency = latency;
		if (!call SendLatency.send(TOS_UART_ADDR, sizeof(AgillaExpLatencyMsg), msg))
		call MessageBufferI.freeMsg(msg);
	}
	return SUCCESS;
	}

	command result_t ExpLoggerI.sendTrace(uint16_t agentID, uint16_t nodeID,
	uint16_t action, uint16_t success, AgillaLocation loc)
	{	 
	return call ExpLoggerI.sendTraceQid(agentID, nodeID, action, 0, success, loc);
	}

	command result_t ExpLoggerI.sendTraceQid(uint16_t agentID, uint16_t nodeID,
	uint16_t action, uint16_t qid, uint16_t success, AgillaLocation loc)
	{
	TOS_MsgPtr msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		struct AgillaTraceMsg *traceMsg = (struct AgillaTraceMsg *)msg->data;
		traceMsg->timestamp = call Time.get();
		traceMsg->agentID = agentID;
		traceMsg->nodeID = nodeID;
		traceMsg->action = action;
		traceMsg->qid = qid;
		traceMsg->success = success;
		traceMsg->loc = loc;
		if (!call SendTrace.send(TOS_UART_ADDR, sizeof(AgillaTraceMsg), msg))
		call MessageBufferI.freeMsg(msg);
	}
	return SUCCESS;
	}	
	
	
	/**
	 * This is a special trace for recording operation GetAgents.
	 */
	command result_t ExpLoggerI.sendGetAgentsResultsTrace(AgillaQueryReplyAllAgentsMsg* replyMsg)
	{
	TOS_MsgPtr msg = call MessageBufferI.getMsg();	
	if (msg != NULL)
	{
		uint16_t i;
		struct AgillaTraceGetAgentsMsg *traceMsg = (struct AgillaTraceGetAgentsMsg *)msg->data;
		traceMsg->timestamp = call Time.get();
		traceMsg->agentID = replyMsg->agent_id.id;
		traceMsg->nodeID = TOS_LOCAL_ADDRESS;
		traceMsg->qid = replyMsg->qid;
		traceMsg->num_agents = replyMsg->num_agents;
		for (i = 0; i < MAX_AGENT_NUM; i++) {
		traceMsg->agent_id[i] = replyMsg->agent_info[i].agent_id;
		traceMsg->loc[i] = replyMsg->agent_info[i].loc;
		}
		if (!call SendGetAgentsResultsTrace.send(TOS_UART_ADDR, sizeof(AgillaTraceGetAgentsMsg), msg))
		call MessageBufferI.freeMsg(msg);
	}
	return SUCCESS;
	}	
	

	command result_t ExpLoggerI.sendSetCluster(uint16_t newClusterHead)
	{
	TOS_MsgPtr msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		struct AgillaTraceMsg *traceMsg = (struct AgillaTraceMsg *)msg->data;
		traceMsg->timestamp = call Time.get();
		traceMsg->agentID = 0;
		traceMsg->nodeID = TOS_LOCAL_ADDRESS;
		traceMsg->action = SET_CLUSTER_HEAD;
		traceMsg->success = newClusterHead;
		traceMsg->loc.x = 0;
		traceMsg->loc.y = 0;
		if (!call SendTrace.send(TOS_UART_ADDR, sizeof(AgillaTraceMsg), msg))
		call MessageBufferI.freeMsg(msg);
	}
	return SUCCESS;
	}

	/**
	 * This task is executed when a query is received.
	 */
/*	task void sendResults() {
	TOS_MsgPtr msg = call MessageBufferI.getMsg();
	if (msg != NULL)
	{
		struct AgillaExpResultsMsg *rMsg = (struct AgillaExpResultsMsg *)msg->data;
		rMsg->numQueries = _numQueries;
		rMsg->numUpdates = _numUpdates;
		rMsg->numReplies = _numReplies;
		if (!call SendResults.send(TOS_UART_ADDR, sizeof(AgillaExpResultsMsg), msg))
		call MessageBufferI.freeMsg(msg);
	}
	}
*/

/*
	event TOS_MsgPtr ReceiveQuery.receive(TOS_MsgPtr m)
	{
	#if DEBUG_EXP_LOGGER
		dbg(DBG_USR1, "ExpLoggerM: Sending Results.\n");
	#endif
	post sendResults();
	return m;
	}
*/

	event result_t SendLatency.sendDone(TOS_MsgPtr m, result_t success)
	{
	call MessageBufferI.freeMsg(m);
	return SUCCESS;
	}

	event result_t SendResults.sendDone(TOS_MsgPtr m, result_t success)
	{
	call MessageBufferI.freeMsg(m);
	return SUCCESS;
	}

	event result_t SendTrace.sendDone(TOS_MsgPtr m, result_t success)
	{
	call MessageBufferI.freeMsg(m);
	return SUCCESS;
	}

	event result_t SendGetAgentsResultsTrace.sendDone(TOS_MsgPtr m, result_t success)
	{
	call MessageBufferI.freeMsg(m);
	return SUCCESS;
	}	
}
