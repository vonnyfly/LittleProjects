#!/usr/bin/env python

import sys
sys.path.append("../gen-py")

from log import LogService
from log.ttypes import *

from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from thrift.server import TServer

import socket

class LogServiceHandler:
    def __init__(self):
        self.log = {}
    def report(self,str):
        print "str = " +str

handler = LogServiceHandler()
processor = LogService.Processor(handler)
transport = TSocket.TServerSocket("localhost",3333)
tfactory = TTransport.TBufferedTransportFactory()
pfactory = TBinaryProtocol.TBinaryProtocolFactory()

server = TServer.TSimpleServer(processor,transport,tfactory,pfactory)
print "starting python server ..."
server.serve()
print "done!"

