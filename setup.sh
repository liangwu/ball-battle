#!/bin/bash

PROJECT_PATH=$(pwd)
DP_PATH="$PROJECT_PATH/dp"
SKYNET_PATH="$PROJECT_PATH/dp/skynet"

if [ ! -e $DP_PATH ];then
	git submodule update --init --recursive || echo "failed to git submodule update" || exit 1
fi


if [[ -e "$SKYNET_PATH" ]];then
	cd "$SKYNET_PATH" || exit
	echo "Intering directory $(pwd)"
	if [[ ! -e "skynet" ]];then
		echo "compile skynet: make linux -j4"
		make linux -j4 || echo "failed to compile skynet."
	fi
	echo "Leaving directory $(pwd)"
	cd "$PROJECT_PATH" || exit
fi

