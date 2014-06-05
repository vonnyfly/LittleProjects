#!/bin/bash
#export DISPLAY=:0

RENDER_SERVER_NAME=RenderServerMain
LISTEN_PORT=9999
pid_of_RenderServer=`pidof $RENDER_SERVER_NAME`

if [ ! -z "$pid_of_RenderServer" ]
then
    echo "Start failed! Please stop the $RENDER_SERVER_NAME first...."
    exit 1
fi

PORT_STATUS=`netstat -ntl|grep -w "$LISTEN_PORT" | awk '{print $6}'`

if [ ! -z $PORT_STATUS ]
then
    echo "Start failed! Please check the port $LISTEN_PORT status..."
    exit 2
fi

# product
BIN_PROGRAM_HOME=$PWD
LOG_HOME=$PWD


WORKER_NUM=20
THREAD_NUM=12

BIN_PROGRAM=$BIN_PROGRAM_HOME/pa_render_server.run

if [ -n "$2" ]
then
  LOGFILE_NAME=$LOG_HOME/$2
else
  LOGFILE_NAME=$LOG_HOME/log.txt
fi
echo "log file $LOGFILE_NAME"

if [ "$1"x = "cg1.4"x ]
then
    echo "worker number:$WORKER_NUM thread number:$THREAD_NUM"
    $BIN_PROGRAM -- -worker_num $WORKER_NUM -thread $THREAD_NUM > ${LOGFILE_NAME} 2>&1 &
elif [ "$1"x = "g2.2"x ]
then
    HW_NUM=3
    echo "worker $WORKER_NUM thread $THREAD_NUM hw $HW_NUM"
    $BIN_PROGRAM -- -enable_hw_encoder -worker_num $WORKER_NUM -thread $THREAD_NUM -hw_num $HW_NUM > ${LOGFILE_NAME} 2>&1 &
else
    echo "Please add the parameter cg1.4 or g2.2"
    exit 3
fi

check_server_status()
{
    SLEEP_NUM=5
    echo "Wait $SLEEP_NUM seconds to check the server status"
    sleep $SLEEP_NUM

    PORT_STATUS=`netstat -ntl|grep -w "$LISTEN_PORT" | awk '{print $6}'`
    if [ ! -z $PORT_STATUS ]
    then
        echo "Starting the $BIN_PROGRAM OK!"
        exit 0
    fi
}

echo "Starting the $BIN_PROGRAM..."

check_server_status
check_server_status

echo "Start failed! Please check the server status..."
