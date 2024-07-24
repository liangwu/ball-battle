#!/bin/bash

PROJECT_PATH=$(pwd)
SKYNET_PATH="$PROJECT_PATH/dp/skynet"

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

