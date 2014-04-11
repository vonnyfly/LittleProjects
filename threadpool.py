from Queue import *
from threading import Thread,Event
from multiprocessing import Value, Lock
import os
import sys
from optparse import OptionParser
import glob
import time
import subprocess
import signal


verbose=False

class Counter(object):
    """ atomic counter,learn form http://python.dzone.com/articles/shared-counter-python%E2%80%99s """
    def __init__(self, initval=0):
        self.val = Value('i', initval)
        self.lock = Lock()

    def increment(self):
        with self.lock:
            self.val.value += 1

    def value(self):
        with self.lock:
            return self.val.value

class Worker(Thread):
    """Thread executing tasks from a given tasks queue"""
    def __init__(self, pool):
        Thread.__init__(self)
        self.pool = pool
        self.tasks = pool.tasks
        if verbose:
            self.results = pool.results
            self.errors_results = pool.errors_results
        else:
            self.num_dones = pool.num_dones
            self.num_errors = pool.num_errors
        self.event = pool.event
        self.start()

    def run(self):
        def preexec_function():
            ''' Ignore the SIGINT signal by setting the handler to the
            standard signal handler SIG_IGN.
            '''
            signal.signal(signal.SIGINT, signal.SIG_IGN)
        while not self.event.isSet():
            try:
                (id,executor,atm,amx) = self.tasks.get(True,0.05)
                cmd = '{0} -demux_file {1} -model_file {2}'.format(executor, amx, atm)
                p = subprocess.Popen(cmd,preexec_fn = preexec_function,
                                     shell=True,
                                     stdin=subprocess.PIPE,
                                     stdout=subprocess.PIPE,
                                     stderr=subprocess.PIPE)
                output,err = p.communicate()
                if verbose:
                    if len(err) != 0:
                        self.errors_results.put((id,err))
                    else:
                        self.results.put((id,output,err))
                else:
                    if len(err) != 0:
                        self.num_errors.increment()
                    else:
                        self.num_dones.increment()
                self.tasks.task_done()
                print >>sys.stderr,"[+] done id={0}\n".format(id)
            except Empty,KeyboardInterrupt:
                continue

class ThreadPool:
    """Pool of threads consuming tasks from a queue"""
    def __init__(self, num_threads,event):
        self.is_closed = False
        self.tasks = Queue(num_threads)
        if verbose:
            # only verbose
            self.results = Queue(0)
            self.errors_results = Queue(0)
        else:
            # verbose=false
            self.num_dones = Counter(0)
            self.num_errors= Counter(0)
        self.event = event
        self.threads = [Worker(self) for _ in range(num_threads)]

    def close(self):
        self.is_closed = True
    def add_task(self, argc):
        """Add a task to the queue"""
        while not self.event.isSet():
            try:
                self.tasks.put(argc,timeout=1)
                print >>sys.stderr,"[+] add {0}".format(argc)
                break
            except Full:
                continue

    def join(self):
        """ wait threads exit """
        [t.join() for t in self.threads]

    def wait_completion(self):
        """Wait for completion of all the tasks in the queue"""
        self.tasks.join()

    def get_results(self):
        if verbose:
            ret = []
            while True:
                try:
                    result = self.results.get(block=False)
                except Empty:
                    break
                else:
                    self.results.task_done()
                    ret.append(result)
            return ret
        else:
            return self.num_dones.value()
    def get_errors(self):
        if verbose:
            ret = []
            while True:
                try:
                    result = self.errors_results.get(block=False)
                except Empty:
                    break
                else:
                    self.errors_results.task_done()
                    ret.append(result)
            return ret
        else:
            return self.num_errors.value()

def get_files(dir_,ext):
    '''
    '''
    return glob.glob(os.path.join(dir_,ext))


def run_all(pool,event,options):
    amx_lists = get_files(options.amx_path,"*.amx");
    atm_lists = get_files(options.atm_path,"*.atm");
    id = 0
    while not event.isSet():
        for atm in atm_lists:
            if event.isSet():break
            for amx in amx_lists:
                if event.isSet():break
                pool.add_task((id,options.executor,atm,amx))
                id = id + 1


if __name__ == '__main__':
    parser = OptionParser("usage: %prog [options]")
    parser.add_option("-t", "--thread_num", type="int", default=2,
            dest="thread_num", help="Thread numbers.")
    parser.add_option("-d", "--model_path", type="string",
                     default="/home/fengli/code/model", dest="atm_path",
                      help="where our model is.")
    parser.add_option("-s", "--msg_path", type="string",
                      default="/home/fengli/code/message", dest="amx_path",
                      help="where our msg is.")
    parser.add_option("-e", "--executor_path", type="string",
                            default="../RenderClientNewMain", dest="executor",
                            help="Executor path.")
    parser.add_option("-v", "--verbose", action="store_true",default=False,
                      dest="verbose", help="print debug info")
    (options, args) = parser.parse_args()
    print >>sys.stderr,"thread num:{0}\n"\
            "model path:{1}\n"\
            "msg path:{2}\n"\
            "executor:{3}\n"\
            "verbose:{4}\n".format(options.thread_num,options.atm_path,
                                    options.amx_path,options.executor,options.verbose)
    verbose=options.verbose
    event = Event()
    event.clear()
    pool = ThreadPool(options.thread_num,event)
    start_time = time.time()
    producer = Thread(target=run_all,args=(pool,event,options))
    producer.start()
    try:
        while not event.is_set():
            event.wait(1)
    except KeyboardInterrupt:
            print >>sys.stderr,"[-] Ctrl-C is pressed! stop...!\n"
            event.set()
    producer.join()
    pool.join()
    elapsed_time = time.time() - start_time

    results = pool.get_results()
    errors = pool.get_errors()
    num_dones = 0
    num_errors = 0
    if verbose:
        num_dones = len(results)
        num_errors = len(errors)
        for ret in results:
            print >>sys.stderr,"ret: {0} ".format(ret)
        for ret in errors:
            print >>sys.stderr,"err: {0} ".format(ret)
    else:
        num_dones = results
        num_errors = errors

    print >>sys.stderr,"failed: {5} ,request: {0} ,total_sec: {1:.1f} ,"\
            "threads: {2} ,throught: {3:.1f} r/s,latency: {4:.1f} s/req".format(
                num_dones,elapsed_time,options.thread_num,
                num_dones/elapsed_time,
                elapsed_time/num_dones if num_dones > 0 else 0,num_errors)
