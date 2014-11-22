# Top-level Makefile for tools/java 
TOS = $(shell ncc -print-tosdir)
SUBDIRS = 

ROOT_RMI = ../../../../../..
#ROOT = $(TOS)/../tools/java
ROOT = $(TOS)/../support/sdk/java
RemoteTupleSpaceServerSide_Stub.class: RemoteTupleSpaceServerSide.class
	rmic -d $(ROOT_RMI) agilla.rmi.remoteTupleSpace.RemoteTupleSpaceServerSide

include $(ROOT)/Makefile.include

