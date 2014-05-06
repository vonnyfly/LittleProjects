#!/bin/bash
set -o nounset          # Treat unset variables as an error

export LC_ALL="C"

concurrents=(1 2 4 6 8 10 12) # len() = 7
interval=60
iterator=1
# used by pybench.py
hours=0s # hours * len(concurrents) = Real Time

hw_enable=1 # if not support hw, please set hw_enable = 0
cpu_enable=0 # only test cpu encode, please set cpu_enable = 1

kill_all() {
  for k in $@;do
    if [ `ps aux | grep $k | grep $(whoami) | grep -v grep | wc -l` -gt 0 ]; then
      ps aux | grep $k | grep -v grep | grep $(whoami) | awk '{print $2}' | xargs kill -SIGINT
      sleep 5
      if [ `ps aux | grep $k | grep $(whoami) | grep -v grep | wc -l` -gt 0 ]; then
        ps aux | grep $k | grep -v grep | grep $(whoami) | awk '{print $2}' | xargs kill -9
      fi
    fi
  done
}

anaysize_results() {
  extra=""
  for concur in ${concurrents[@]};do
    if [ $cpu_enable -eq 1 ] ;then
      extra=" -c cpu-log/render.log.$concur "
    fi
    if [ $hw_enable -eq 1 ] ;then
      extra="$extra -g hw-log/render.log.$concur "
    fi
    python process_log.py  $extra -o cpu-log/out.log.$concur
  done
}

kill_all LogServer.py

[ -d cpu-log ] && rm -rf cpu-log/* || mkdir cpu-log
[ -d hw-log ] && rm -rf hw-log/* || mkdir hw-log

bash ./stop.sh
##################################################################
# cpu encode
#################################################################
if [ $cpu_enable -eq 1 ] ;then
  bash ./start.sh cg1.4
  for concur in ${concurrents[@]};do
    echo "=======================concurrent = $concur ==================="
    python LogServer.py -o cpu-log/render.log.$concur &
    ./RenderBench -model_dir `pwd`/model -message_dir ./message -concurrent $concur -iterator $iterator
    # python pybench.py -N $iterator  -t $hours -n $concur  -d `pwd`/model -s ./message -e "./RenderClientNewMain"
    sleep $interval
    kill_all LogServer.py
  done
  bash ./stop.sh
fi

##################################################################
# enable hw
#################################################################
if [ $hw_enable -eq 1 ] ;then
  for concur in ${concurrents[@]};do
    bash ./start.sh g2.2 ${concur}.log
    echo "=======================concurrent = $concur ==================="
    python LogServer.py -o hw-log/render.log.$concur &
    ./RenderBench -model_dir `pwd`/model -message_dir ./message -concurrent $concur -iterator $iterator
    # python pybench.py -N $iterator  -t $hours -n $concur  -d `pwd`/model -s ./message -e "./RenderClientNewMain"
    sleep $interval
    kill_all LogServer.py
    bash ./stop.sh
  done
fi

echo "[+] process results"
anaysize_results
