#!/usr/bin/env python

import sys
import os
sys.path.append("./gen-py")

from log import LogService
from log.ttypes import *

from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from thrift.server import TServer

import socket
from optparse import OptionParser

class LogServiceHandler:
    def __init__(self,opts):
        self.log = {}
        self.opts = opts
    def report(self,str):
        if self.opts.output_file:
            with open(self.opts.output_file,'a') as f:
                f.write(str)
        else:
            print str

def main():
    parser = OptionParser(usage='%prog [options]', description='receive log')
    parser.add_option('-o', '--output_file',type='string', action='store',
                  help='redirect output to file')
    (opts, args) = parser.parse_args()

    handler = LogServiceHandler(opts)
    processor = LogService.Processor(handler)
    transport = TSocket.TServerSocket("localhost",3333)
    tfactory = TTransport.TBufferedTransportFactory()
    pfactory = TBinaryProtocol.TBinaryProtocolFactory()

    try:
        server = TServer.TSimpleServer(processor,transport,tfactory,pfactory)
        print "starting python server ..."
        server.serve()
        print "done!"
    except KeyboardInterrupt:
        print >>sys.stderr,"[-] Ctrl-C is pressed! stop...!\n"
if __name__ == '__main__':
    main()
