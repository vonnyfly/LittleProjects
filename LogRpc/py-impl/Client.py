#!/usr/bin/env python

import sys
sys.path.append('../gen-py')

from log import LogService
from log.ttypes import *
from log.constants import *

from thrift import Thrift
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol

try:
  # Make socket
  transport = TSocket.TSocket('localhost', 3333)
  # Buffering is critical. Raw sockets are very slow
  transport = TTransport.TBufferedTransport(transport)
  # Wrap in a protocol
  protocol = TBinaryProtocol.TBinaryProtocol(transport)
  # Create a client to use the protocol encoder
  client = LogService.Client(protocol)
  # Connect!
  transport.open()
  client.report("haha")
  transport.close()
except Thrift.TException, tx:
  print "%s" % (tx.message)
