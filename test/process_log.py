#--*-- coding:utf-8 --*--
from collections import defaultdict
from optparse import OptionParser
import sys

def split_to_list(fname):
    with open(fname,'r') as f:
        data = f.read()
    lines = [line.strip() for line in data.split("\n") if len(line.strip()) != 0 ]
    dic = defaultdict(int)
    count = defaultdict(int)
    label = ''
    labels = []
    time = 0
    for line in lines:
        itemList = line.split()
        if len(itemList) == 5:
            label = itemList[1]
            time = int(itemList[4])
            dic[label] += time
            count[label] += 1
            labels.append(label) if not label in labels else None

    countList = count.values()
    for i,v in enumerate(countList):
        if(v != countList[0]):
            print "[-] data is bad...\n"
            print count
    for label in labels:
        dic[label] = dic[label] / count[label]
        #print "count[%s]:%d "%(label,count[label])
    if 'extra' in dic:
        dic['extra'] = dic['extra'] - dic['total']
    return dic,labels



def main():
    '''recive cpu and hw log file and parse the result to output
    '''
    parser = OptionParser("usage: %prog [options]")
    parser.add_option("-c", "--cpu_log", type="string",action='store')
    parser.add_option("-g", "--hw_log", type="string",action='store')
    parser.add_option("-o", "--out", type="string",action='store')
    (options, args) = parser.parse_args()

    if not options.cpu_log and not options.hw_log:
      parser.print_help()
      sys.exit(1)

    header='period \t'
    if options.cpu_log:
      cpu,labels= split_to_list(options.cpu_log)
      header += 'cpu_encode \t'
    if options.hw_log:
      hw,labels= split_to_list(options.hw_log)
      header += 'hw_encode '

    out_str = header + '\n'
    for label in labels:
      if options.cpu_log and options.hw_log:
        out_str += "%s\t %d \t %d\n"%(label,cpu[label],hw[label])
      elif options.cpu_log:
        out_str += "%s\t %d \n"%(label,cpu[label])
      elif options.hw_log:
        out_str += "%s\t %d \n"%(label,hw[label])
    if options.out:
      with open(options.out,'w') as f:
        f.write(out_str)
    else:
      print out_str
if __name__ == '__main__':
    main()
