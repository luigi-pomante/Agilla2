/**
 * Logs statistics about the directory service operations.
 *
 * @author Chien-Liang Fok
 */
interface ExpLoggerI
{
	command error_t reset();
	//command result_t incQueryMsg();
	//command result_t incNumUpdates();
	//command result_t incNumReplies();
	command error_t sendQueryLatency(uint32_t latency);
	command error_t sendTrace(uint16_t agentID, uint16_t nodeID, uint16_t action, uint16_t success, AgillaLocation loc);
	command error_t sendTraceQid(uint16_t agentID, uint16_t nodeID, uint16_t action, uint16_t qid, uint16_t success, AgillaLocation loc);
	command error_t sendGetAgentsResultsTrace(AgillaQueryReplyAllAgentsMsg* replyMsg);
	command error_t sendSetCluster(uint16_t newClusterHead);
}
