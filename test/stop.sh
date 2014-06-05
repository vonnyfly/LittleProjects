#!/bin/bash
#export DISPLAY=":0"

RENDER_SERVER_NAME=RenderServerMain
pid_of_RenderServer=`pidof $RENDER_SERVER_NAME`

if [ ! -z $pid_of_RenderServer ]
then
    echo "Stop the $RENDER_SERVER_NAME PID $pid_of_RenderServer...."
    kill -TERM $pid_of_RenderServer
else
    echo "The $RENDER_SERVER_NAME is not running"
    exit 1
fi



SLEEP_NUM=3
sleep $SLEEP_NUM

WORKER_NAME=worker
worker_count=`pidof $WORKER_NAME | wc -w`
pid_of_worker=`pidof $WORKER_NAME`

if [ $worker_count -gt 0 ]
then
    echo "Stop the $WORKER_NAME $pid_of_worker...."
    kill -TERM $pid_of_worker
fi
echo "Waiting $SLEEP_NUM seconds to check worker status"

sleep $SLEEP_NUM
worker_count=`pidof $WORKER_NAME | wc -w`
pid_of_worker=`pidof $WORKER_NAME`
if [ $worker_count -gt 0 ]
then
    echo "Stop the worker $pid_of_worker failed...."
    exit 2
fi

echo "Stop the server OK..."
