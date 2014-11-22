interface MessageBufferI {
	/**
	 * Returns a pointer to a free message buffer.
	 * If no free buffer exists, return NULL.
	 * 
	 */
	command message_t* getMsg();
	
	/**
	 * Signalled when a message buffer becomes free.
	 */
	command error_t freeMsg(message_t* msg);
	
}
