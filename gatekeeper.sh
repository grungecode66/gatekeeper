#!/bin/bash
###########################################################
# gatekeeper.sh
# enhanced version of the original ape gatekeeper script
# cleans as it moves :-)
# cc 2015-10-23
###########################################################

SRC_PATH="/home/cromaca/dropoff"
DEST_PATH="/home/cromaca/hold"
LOG_PATH="/home/cromaca/log"
NOW="$(date +"%m-%d-%Y_%s")"
if [ "$(ls -A $SRC_PATH)" ]; then
	mv -v $SRC_PATH/* $DEST_PATH/ > $LOG_PATH/gatekeeper_$NOW.log
	find $SRC_PATH/ -maxdepth 1 -iname ".*" -type f -delete
fi

