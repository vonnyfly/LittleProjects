#include <thrift/transport/TSocket.h>
#include <thrift/transport/TBufferTransports.h>
#include <thrift/protocol/TBinaryProtocol.h>

#include "../gen-cpp/LogService.h"
#include "report.h"

using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

void report(const std::string &str) {
  boost::shared_ptr<TSocket> socket(new TSocket("localhost", 3333));
  boost::shared_ptr<TTransport> transport(new TBufferedTransport(socket));
  boost::shared_ptr<TProtocol> protocol(new TBinaryProtocol(transport));
  try{
    LogServiceClient client(protocol);
    transport->open();
    client.report(str);
    transport->close();
  }catch(TTransportException e)
  {
  }
}
