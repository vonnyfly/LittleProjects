import sys
import struct
from commands import getoutput

def get_func_addr(elf,sym):
  tmp = getoutput("objdump -d {0} | grep {1}".format(elf,sym))
  if len(tmp) == 0:
    print >>sys.stderr,"{0} not exits in {1}\n".format(sym,elf)
    return
  # need packed 
  print tmp.split('\n')[0].split()[0]

def get_symbol_nosolved(objfile):
  tmp = getoutput("readelf -r test.o").split('\n')[3:-4]
  symbs = []
  for t in tmp:
    if not t.split()[4].startswith('.'):
      symbs.append(t.split()[4])
  return symbs

if __name__ == '__main__':
  tmp = sys.argv[1].split('\\x')[1:]
  packed = ''

  with open("a.o","w+b") as f:
      packed = ''.join([struct.pack('<B',int(t,16)) for t in tmp])
      f.write(packed)
  nosolved = get_symbol_nosolved("test.o")
  for s in nosolved:
    print s
    get_func_addr("test",s)


