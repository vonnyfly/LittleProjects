#!/bin/bash
set -o nounset          # Treat unset variables as an error

export LC_ALL="C"

concurrents=(1 2 4 6 8 10 12) # len() = 7
hours=0s # hours * len(concurrents) = Real Time
interval=60

hw_enable=0 # if not support hw, please set hw_enable = 0

bash ./start.sh cg1.4
for concur in ${concurrents[@]};do
  echo "=======================concurrent = $concur ==================="
  python pybench.py -N 1  -t $hours -n $concur  -d `pwd`/model -s ./message -e "./RenderClientNewMain" -l  LogServer.py -o cpu-log/render.log
  sleep $interval
done
bash ./stop.sh

##################################################################
# enable hw
#################################################################
if [ $hw_enable -eq 1 ] ;then
  bash ./start.sh g2.2
  for concur in ${concurrents[@]};do
    echo "=======================concurrent = $concur ==================="
    python pybench.py -N 1  -t $hours -n $concur  -d `pwd`/model -s ./message -e "./RenderClientNewMain" -l  LogServer.py -o hw-log/render.log
    sleep $interval
  done
  bash ./stop.sh
fi

echo "[+] process results"
for concur in ${concurrents[@]};do
  if [ $hw_enable -eq 1 ] ;then
    python process_log.py -c cpu-log/render.log.$concur -g hw-log/render.log.$concur -o cpu-log/out.log.$concur
  else
    python process_log.py -c cpu-log/render.log.$concur -o cpu-log/out.log.$concur
  fi
done
