#!/bin/bash
set -o nounset          # Treat unset variables as an error

# eg.${GLABAL_PREFIX}/render_server_cpu.log.2
DATE=`date '+%Y-%m-%d'`
GLABAL_PREFIX=/var/www/fengli/performance/${DATE}
GLABAL_LOG_PREFIX=${GLABAL_PREFIX}/logs
OUTPUT_PREFIX=${GLABAL_PREFIX}/images


LOG_CPU_SERVER_PREFIX=${GLABAL_LOG_PREFIX}/render_server_cpu.log
# eg./tmp/render_server_gpu.log.4
LOG_GPU_SERVER_PREFIX=${GLABAL_LOG_PREFIX}/render_server_gpu.log
# eg./tmp/sar.file.1,${GLABAL_PREFIX}/sar.file.2
SAR_FILE_PREFIX=${GLABAL_LOG_PREFIX}/sar.file
# eg./tmp/report.dat.8
PLOT_DAT_PREFIX=${GLABAL_LOG_PREFIX}/report.dat
VERSION_PATH=${GLABAL_LOG_PREFIX}/version

Iterations=1
# workers num
worker_num=4
concurrents=(4)

SERVER="../pa_render_server.run"
SERVER_CMD="${SERVER} -- -worker_num $worker_num -thread $worker_num -port 3333"
SERVER_HW_CMD="${SERVER_CMD} -enable_hw_encoder"
CLIENT="../RenderClientNewMain"
CLIENT_CMD="${CLIENT} -port 3333"

export LC_ALL="C"

function start_timer(){
  start=$(date "+%s")
}

function report_timer()
{
  now=$(date "+%s")
  time=$((now-start))
  minute=$((time/60))
  second=$((time-minute*60))
  echo -ne "\ntotal: "
  if [ $minute -eq 0 ]
  then
    echo $second s
  else
    echo -n $minute min
    echo $second s
  fi
}

function record_version()
{
  ${SERVER} -- --version >${VERSION_PATH}
  echo "${SERVER_CMD}" >>${VERSION_PATH}
  echo "${SERVER_HW_CMD}" >>${VERSION_PATH}
}

function force_kill() {
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
function start_monitor_cpu_util(){
  sar -o "${SAR_FILE_PREFIX}.$1" 10  >/dev/null 2>&1 &
}

function stop_monitor(){
  kill_keys=(sar)
  force_kill ${kill_keys[@]}
}

function report_cpu_util(){
  load=`sar -f $1 | awk '{if($3=="CPU"){split($0,lables," ")};if($1=="Average:"){split($0,values," ")}}END{printf("%s:%s,%s:%s,%s:%s,%s:%s",lables[4],values[3],lables[6],values[5],lables[7],values[6],lables[9],values[8])}'`
}


function clean_env() {
  rm -rf ${GLABAL_PREFIX} ${GLABAL_LOG_PREFIX} ${OUTPUT_PREFIX} 
  mkdir -p ${GLABAL_PREFIX} ${GLABAL_LOG_PREFIX}  ${OUTPUT_PREFIX}
  cp ./benchmark.php ${GLABAL_PREFIX}

#  for n in "${concurrents[@]}";do
#    cpu_output="${LOG_CPU_SERVER_PREFIX}.$n"
#    gpu_output="${LOG_GPU_SERVER_PREFIX}.$n"
#    sar_file="${SAR_FILE_PREFIX}.$n"
#    report_file="${PLOT_DAT_PREFIX}.$n"
#    rm -f $cpu_output $gpu_output $sar_file $report_file
#  done
  kill_keys=(./RenderServerMain ./worker sar)
  force_kill ${kill_keys[@]}
}

function start_render_server(){
  echo -e "\t[report] cpu encode" 1>>$1
  #sync
  ${SERVER_CMD} 1>>$1 2>/dev/null &
  sleep 10
}

function start_render_server_with_hw(){
  echo -e "\t[report] gpu_hw encode" 1>>$1
  #sync
  ${SERVER_HW_CMD} 1>>$1 2>/dev/null &
  sleep 10
}

function stop_render_server(){
  kill_keys=(./RenderServerMain ./worker)
  force_kill ${kill_keys[@]}
}

# $1: concurrent
function check_clients_and_wait(){
   while [ `ps aux | grep ${CLIENT} | grep $(whoami) | grep -v grep | wc -l` \
     -ge  $1 ]
   do
     echo "check..."
     sleep 1
   done
}

# wait all clients exit
function wait_clients_exit(){
  while [ `ps aux | grep ${CLIENT} | grep $(whoami) | grep -v grep | wc -l` -gt 0 ]
  do
    echo "check..."
    sleep 2
  done
}

# argv[1]: concurrent num
# argv[2]: iterations of each concurrent
function start_client_and_wait(){
  local concurrent=$1
  local iteration=$2
  for((i=0;i<$iteration;i++)); do
    echo "---------concurrent=${concurrent}--------"
    for msg in `ls ../../message/*.amx`;do
      echo $msg
      for atm in `ls ../../model/*.atm`;do
        mdl="$(pwd)/$atm"
        echo $mdl
        for((j=0;j<$concurrent;j++)); do
          ${CLIENT_CMD} -demux_file $msg -model_file $mdl 1>/dev/null &
          check_clients_and_wait $concurrent
        done
      done # end model
    done # end msg
  done
  wait_clients_exit
}

function analyze_data(){
  grep -E "report" $1 >${GLABAL_LOG_PREFIX}/1111.txt
  grep -E "report" $2 >${GLABAL_LOG_PREFIX}/2222.txt
  # analyze the data
  python dodata.py ${GLABAL_LOG_PREFIX}/1111.txt ${GLABAL_LOG_PREFIX}/2222.txt "${PLOT_DAT_PREFIX}.$3"
}

function draw_png(){
  ## gnuplot
  report_cpu_util "${SAR_FILE_PREFIX}.$1"
  output_img="${OUTPUT_PREFIX}/benchmark_n${1}_`date '+%Y-%m-%d-%H%M%S'`.png"
  now_datetime=`date '+%Y-%m-%d %H:%M:%S'`
  echo "set terminal png
  set output '$output_img'
  set title \"Benchmark: CPU and HW encode(time:$now_datetime)\n Concurrent:$1\n $load\"
  set style fill solid 0.4 border
  set grid y
  set xlabel 'encode period'
  set ylabel 'response time(ms)'
  set key top center

  set yrange [0:*]
  GAPSIZE=1
  set style histogram cluster gap 1
  STARTCOL=2                 #Start plotting data in this column (2 for your example)
  ENDCOL=3                   #Last column of data to plot (10 for your example)
  NCOL=ENDCOL-STARTCOL+1     #Number of columns we're plotting
  BOXWIDTH=1./(GAPSIZE+NCOL) #Width of each box.
  plot for [COL=STARTCOL:ENDCOL] '${PLOT_DAT_PREFIX}.$1' u COL:xtic(1) w histogram title columnheader(COL), \
        for [COL=STARTCOL:ENDCOL] '${PLOT_DAT_PREFIX}.$1' u (column(0)-1+BOXWIDTH*(COL-STARTCOL+GAPSIZE/2+1)-0.5):COL:COL notitle w labels
  ">${GLABAL_LOG_PREFIX}/plotme

  ## plotting
  gnuplot ${GLABAL_LOG_PREFIX}/plotme
}

trap handler_exit INT

function handler_exit(){
  echo "CTRL + C is pressed"

  kill_keys=(./RenderServerMain ./worker sar)
  force_kill ${kill_keys[@]}

  for n in "${concurrents[@]}";do
    cpu_output="${LOG_CPU_SERVER_PREFIX}.$n"
    gpu_output="${LOG_GPU_SERVER_PREFIX}.$n"
    if [ -e $cpu_output ] && [ -e $gpu_output ] ;then
      analyze_data $cpu_output $gpu_output $n
      draw_png $n
    else
      echo "except..."
    fi
  done
  #rm -rf ${GLABAL_LOG_PREFIX}/sar.file.*
  exit
}

# handler_exit
# exit


clean_env
# log verions in log/version
record_version

#while true ; do
mock=1
while [ $mock -gt 0 ] ; do
  for n in "${concurrents[@]}";do
    cpu_output="${LOG_CPU_SERVER_PREFIX}.$n"
    gpu_output="${LOG_GPU_SERVER_PREFIX}.$n"
    start_monitor_cpu_util $n
    # encode with cpu
    # 1. start server
    # 2. start timer
    # 3. start clients
    start_render_server $cpu_output
    #start_timer
    start_client_and_wait $n $Iterations
    #report_timer 
    stop_render_server

    # encode with gpu hw
    # like up
    start_render_server_with_hw $gpu_output
    start_client_and_wait $n $Iterations
    stop_render_server

    stop_monitor
  done
  let mock=mock-1
done

handler_exit

