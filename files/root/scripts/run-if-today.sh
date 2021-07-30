#!/bin/bash

# Example of CRONs using this script:
# 26 8 * * * /root/scripts/run-if-today.sh 1 Wed && /usr/local/sbin/update_and_reboot --quiet
# 26 8 * * * /root/scripts/run-if-today.sh 1 Wed 2 && /usr/bin/wall 'This system will be updated and rebooted in 48 hours.'
# 26 8 * * * /root/scripts/run-if-today.sh 1 Wed 1 && /usr/bin/wall 'This system will be updated and rebooted in 24 hours.'
# 26 7 * * * /root/scripts/run-if-today.sh 1 Wed && /usr/bin/wall 'This system will be updated and rebooted in 1 hour.'

# print a help message if we dont get 2 or 3 args
if [[ "$#" -ne "2" ]] && [[ "$#" -ne "3" ]]; then
    PROGNAME=$(echo $0 | sed 's/.*\///')
    echo "Usage:"
    echo "  $PROGNAME week_num day_of_week [offset]"
    echo ""
    echo "This program is useful to run a cronjob on things like the"
    echo "3rd Wednesday of the month.  It returns true if and only if"
    echo "today matches the week_num and the day_of_week."
    echo ""
    echo "You can optionally provide an offset to pretend today is N"
    echo "days in the future (or past for negative offsets)."
    echo ""
    echo "Additionally, you can set the week_num field to 'any' to just"
    echo "run a job on a certain day of the week."
    echo ""
    echo "Examples:"
    echo "  Run 'foo' on the 1st Monday                  --> $PROGNAME 1 Mon && foo"
    echo "  Run 'bar' on the 3rd Wednesday               --> $PROGNAME 3 Wed && bar"
    echo "  Run 'baz' if two days ago was the 2rd Friday --> $PROGNAME 2 Fri -2 && baz"
    echo "  Run 'quux' if tomorrow is the 4rd Thursday   --> $PROGNAME 4 Thu 1 && quux"
    echo "  Run 'corge' on every Sunday                  --> $PROGNAME any Sun && corge"
    echo ""
    exit 1
fi

OFFSET=0
if [[ "$3" != "" ]]; then
    OFFSET=$3
    if ! echo "$OFFSET" | grep -Eq '^-?[0-9]+$'; then
        echo "invalid offset '$OFFSET'"
        exit 1
    fi
fi

DAY_OF_MONTH=$(date +%e --date="$OFFSET day")
DAY_OF_WEEK=$(date +%a --date="$OFFSET day")

WANTED_WEEK=$1
WANTED_DAY=$2

# bail if it isnt the correct day of the week
[[ "$WANTED_DAY" != "$DAY_OF_WEEK" ]] && exit 1
# exit 0 early since we passed the DOW check and week is 'any'
[[ "$WANTED_WEEK" == "any" ]] && exit 0

# calculate the range the date should be in
MIN_DAY=$(( $WANTED_WEEK * 7 - 6 ))
MAX_DAY=$(( $WANTED_WEEK * 7 ))

# bail if were outside of that
[[ "$DAY_OF_MONTH" -lt "$MIN_DAY" ]] && exit 1
[[ "$DAY_OF_MONTH" -gt "$MAX_DAY" ]] && exit 1

# made it through
exit 0
