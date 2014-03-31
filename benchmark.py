import os
from multiprocessing import Process,Queue,RLock
from collections import deque
from threading import Timer
import time

class ProcessPool:
    def __init__(self,max_runnning_processes=20,check_interval=1):
        self.max_runnning_processes_ = max_runnning_processes
        self.check_interval_ = check_interval
        self.running_ = []
        self.pending_ = deque()
        self.is_closed_ = False
        self.check_interval_ = check_interval
        self.running_lock_ = RLock()
        self.pending_lock_ = RLock()
        Timer(self.check_interval_,self.check_running_).start()

    def add_task_async(self,func, args=(), kwargs={},callback=None):
        if self.is_closed_:
            print("[-] pool is closed\n")
            return

        with self.pending_lock_:
            self.pending_.append({
                "func":func,
                "args":args,
                "kwargs":kwargs,
                "callback":callback
            })
        self.start_()

    def join(self):
        try:
            with self.running_lock_:
                for i in self.running_:
                    i["process"].join()
        except KeyboardInterrupt:
            pass

        if self.num_pending > 0:
            print("still has {0} pending\n".format(self.num_pending))

    def close(self):
        self.is_closed_ = True

    @property
    def num_running(self):
        with self.running_lock_:
            return len(self.running_)

    @property
    def is_full(self):
        return self.num_running >= self.max_runnning_processes_

    @property
    def num_pending(self):
        with self.pending_lock_:
            return len(self.pending_)

    def start_(self):
        def wrapper_(func,queue):
            def inner_(*args,**kwargs):
                result = func(*args,**kwargs)
                queue.put(result)
            return inner_


        if self.num_pending > 0 and not self.is_full:
            next = {}
            with self.pending_lock_:
                next = self.pending_.popleft()
            q = Queue()
            p = Process(target=wrapper_(next["func"],q),
                            args=next["args"],
                            kwargs=next["kwargs"])
            with self.running_lock_:
                self.running_.append({
                    'process':p,
                    'queue':q,
                    'callback':next["callback"]})
            print("[+] start process\n")
            p.start()

        print("""\
        [+] running:{0}
        [+] pending:{1}\n""".format(self.num_running,self.num_pending))

    def check_running_(self):
        print "check..."
        with self.running_lock_:
            deadList = [ i for i in self.running_ if not i["process"].is_alive() ]
            for i in deadList:
                if i["callback"]:
                    result = i["queue"].get()
                    i["callback"](result)
                self.running_.remove(i)
                self.start_()
            if not self.is_closed_:
                Timer(self.check_interval_,self.check_running_).start()

def worker_func2(*msg):
    time.sleep(10)
    return msg

def callback(*msg):
    print msg

def worker_func(a='abc', b='def', c='ghi'):
    time.sleep(10)
    print a,b,c

def main():
    pool = ProcessPool()
    pool.add_task_async(worker_func,kwargs={ 'a': 123, 'b': 456, 'c': 789 })
    for i in range(30):
        pool.add_task_async(worker_func2,args=(i,),callback=callback)
    pool.close()
    pool.add_task_async(worker_func2,args=("a","b"))
    pool.join()
    print("exit")

if __name__ == "__main__":
    main()
