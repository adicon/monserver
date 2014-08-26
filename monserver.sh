#!/bin/bash
# Simple SHELL script for Linux and UNIX services monitoring with netcat
# -------------------------------------------------------------------------
# Copyright (c) 2014 Andrea Di Dato <http://www.adicon.it/>
# This script is licensed under GNU GPL version 3.0 or above
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------
# Setup HOSTS, SUBJECT, EMAILID, REALERT string below
# Project hosted on GitHub:
# http://github.com/adicon/monserver
# -------------------------------------------------------------------------

# add ip/hostname and service port separated by space and hosts to test separated by commas
HOSTS="google.com 80, github.com 80, smtp.gmail.com 465"

# email/s to report to
SUBJECT="[MONSERVER] Service failed"
EMAILS="myaddress@mydomain.ext, my_address@gmail.com"

# how many consecutive alert must be ignored before to alert again
REALERT=96

# host semaphore dir
lockdir="/tmp/monserver"

# possible NetCat version successful connection string separated by |  
NCOK="open|succeeded"

# verify if called with arguments
if [ $# == 2 ]; then
  HOSTS=$1 $2
fi

OIFS=$IFS
IFS=','
arr=$HOSTS

for Host in $arr
do
    myHost=$(echo $Host | awk -F' ' '{print $1}')
    myPort=$(echo $Host | awk -F' ' '{print $2}')
    nc_out=$(nc -v -z -w 2 $myHost $myPort 2>&1 | egrep -sc $NCOK)
    if [ $nc_out -eq 0 ]; then
        # server failed
        if [ ! -f $lockdir/$myHost/$myPort ]; then
            # first alert
            mkdir -p $lockdir/$myHost
            echo "0" > $lockdir/$myHost/$myPort
        else
            # already alerted at least once
            echo $[`cat $lockdir/$myHost/$myPort` +1] > $lockdir/$myHost/$myPort
        fi
        if [ `cat $lockdir/$myHost/$myPort` -gt $REALERT -o `cat $lockdir/$myHost/$myPort` -eq 0 ]; then
            # it's time to alert
            echo -e "Subject: $SUBJECT - $myHost\n\nHost $myHost is not responding at port $myPort on $(date)" | mail $EMAILS
            echo "1" > $lockdir/$myHost/$myPort
        fi
    else
        # server is alive
        if [ -f $lockdir/$myHost/$myPort ]; then
            rm $lockdir/$myHost/$myPort
        fi
    fi
done

IFS=$OIFS

