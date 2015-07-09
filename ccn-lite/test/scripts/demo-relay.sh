#!/bin/sh

# demo-relay.sh -- test/demo for ccn-lite: CCNx relaying
USAGE="usage: sh demo-relay.sh SUITE CHANNEL KERNELMODULE\nwhere\n  SUITE= ccnb, ccnx2015, cisco2015, iot2014, ndn2013\n CHANNEL= udp, ux\n KERNELMODULE= true, false"
SET_CCNL_HOME_VAR="set system variable CCNL_HOME to your local CCN-Lite installation (.../ccn-lite) and run 'make clean all' in CCNL_HOME/src"
COMPILE_CCNL="run 'make clean all' in CCNL_HOME/src"

exit_error_msg () {
    echo $1
    echo $USAGE
    exit 1
}

if [ -z "$CCNL_HOME" ]
then
    export CCNL_HOME="../../"
    #echo $SET_CCNL_HOME_VAR
    #exit 1
fi

if [ ! -f "$CCNL_HOME/src/ccn-lite-relay" ]
then
    echo $COMPILE_CCNL
    exit 1
fi

if [ "$#" -lt 3 ]; then
    exit_error_msg "illegal number of parameters"
fi

PORTA=9998
PORTB=9999
UXA=/tmp/ccn-lite-relay-$$-a.sock
UXB=/tmp/ccn-lite-relay-$$-b.sock

SUITE=$1
CON=$2
USEKRNL=$3

# suite setup
if [ $SUITE = "ccnb" ]
then
    DIR="ccnb"
    FWD="/ccnx/0.7.1/doc/technical"
    FNAME="NameEnumerationProtocol.txt"
elif [ $SUITE = "ccnx2015" ]
then
    DIR="ccntlv"
    FWD="ccnx"
#    FNAME="simple"
    FNAME="long"
elif [ $SUITE = "cisco2015" ]
then
    DIR="cistlv"
    FWD="/ccn-lite/20150106/src"
    FNAME="ccnl-ext-debug.h"
elif [ $SUITE = "iot2014" ]
then
    DIR="iottlv"
    FWD="/ccn-lite/20141204/src"
    FNAME="ccnl-ext-debug.h"
elif [ $SUITE = "ndn2013" ]
then
    DIR="ndntlv"
    FWD="ndn"
    FNAME="abc"
else
    exit_error_msg "'$SUITE' is not a valid SUITE"
fi

# face setup
if [ "$CON" = "udp" ]
then
    if [ "$USEKRNL" = true ]
    then
        SOCKETA="u=$PORTA"
    else
        SOCKETA="-u$PORTA"
    fi
    SOCKETB="-u$PORTB"
    FACETOA="newUDPface any 127.0.0.1 $PORTA"
    FACETOB="newUDPface any 127.0.0.1 $PORTB"
    PEEKADDR="-u 127.0.0.1/$PORTA"
elif [ "$CON" = "ux" ]
then
    SOCKETA=
    SOCKETB=
    FACETOA="newUNIXface $UXA"
    FACETOB="newUNIXface $UXB"
    PEEKADDR=
else
    exit_error_msg "'$CON' is not a valid CON"
fi


# topology:

#  ccn-lite-peek --> relay A     -->  relay B
#
#                 127.0.0.1/9998   127.0.0.1/9999  (udp addresses)
#                 /tmp/a.sock      /tmp/b.sock (unix sockets, for ctrl only)

# ----------------------------------------------------------------------

echo -n "killing all ccn-lite-relay instances... "
killall ccn-lite-relay 2> /dev/null

echo "starting relay A, with a link to relay B"

if [ "$USEKRNL" = true ]
then
    rmmod ccn_lite_lnxkernel
    insmod $CCNL_HOME/src/ccn-lite-lnxkernel.ko v=99 s=$SUITE $SOCKETA x=$UXA
else
    $CCNL_HOME/src/ccn-lite-relay -v trace -s $SUITE $SOCKETA -x $UXA 2>/tmp/a.log &
fi

# ----------------------------------------------------------------------
sleep 1
FACEID=`$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXA $FACETOB | $CCNL_HOME/src/util/ccn-lite-ccnb2xml | grep FACEID | sed -e 's/.*\([0-9][0-9]*\).*/\1/'`
echo "faceid at A=$FACEID"
$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXA prefixreg $FWD $FACEID $SUITE | $CCNL_HOME/src/util/ccn-lite-ccnb2xml | grep ACTION

# if testing fragmentation:
# $CCNL_HOME/src/util/ccn-lite-ctrl -x $UXA setfrag $FACEID seqd2015 800 | $CCNL_HOME/src/util/ccn-lite-ccnb2xml | grep ACTION

# ----------------------------------------------------------------------
echo "starting relay B, with content loading ..."
$CCNL_HOME/src/ccn-lite-relay -v trace -s $SUITE $SOCKETB -x $UXB -d "$CCNL_HOME/test/$DIR" 2>/tmp/b.log &
sleep 1
FACEID=`$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXB $FACETOA | $CCNL_HOME/src/util/ccn-lite-ccnb2xml | grep FACEID | sed -e 's/.*\([0-9][0-9]*\).*/\1/'`
echo "faceid at B=$FACEID"

# if testing fragmentation:
# $CCNL_HOME/src/util/ccn-lite-ctrl -x $UXB setfrag $FACEID seqd2015 800 | $CCNL_HOME/src/util/ccn-lite-ccnb2xml | grep ACTION

# ----------------------------------------------------------------------
sleep 1
echo
echo "test case: ask relay A to deliver content that is hosted at relay B"
$CCNL_HOME/src/util/ccn-lite-peek -s$SUITE $PEEKADDR "$FWD/$FNAME" > /tmp/res

RESULT=$?

# shutdown both relays
echo ""
echo "# Config of relay A:"
$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXA debug dump | $CCNL_HOME/src/util/ccn-lite-ccnb2xml
echo ""
echo "# Config of relay B:"
$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXB debug dump | $CCNL_HOME/src/util/ccn-lite-ccnb2xml

$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXA debug halt > /dev/null &
$CCNL_HOME/src/util/ccn-lite-ctrl -x $UXB debug halt > /dev/null &

if [ $RESULT = '0' ]
then
    echo "=== PKTDUMP.start >>>"
    $CCNL_HOME/src/util/ccn-lite-pktdump < /tmp/res
    echo "\n=== PKTDUMP.end <<<"
    # rm /tmp/res
else
    echo "ERROR exitcode $RESULT WHEN FETCHING DATA"
fi

sleep 1
killall ccn-lite-relay 2> /dev/null

if [ "$USEKRNL" = true ]
then
    rmmod ccn_lite_lnxkernel
fi

exit $RESULT

# eof
