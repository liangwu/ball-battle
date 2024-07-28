#!/bin/bash

PROJECT_PATH=$(pwd)
SKYNET_PATH="$PROJECT_PATH/dp/skynet"
SKYNET_EXEC="$PROJECT_PATH/dp/skynet/skynet"


if [ ! -e "$SKYNET_PATH" ];then
	echo "the dir does not exit, $SKYNET_PATH"
	exit
fi
if [ ! -x "$SKYNET_EXEC" ];then
	echo "the dir does not exit, $SKYNET_EXEC"
	exit
fi
$SKYNET_EXEC etc/skynet.conf.node1
