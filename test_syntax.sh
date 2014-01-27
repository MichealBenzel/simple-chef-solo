#!/bin/bash
# Cookbook test script
# Checks ruby syntax

# Use either the current directory, or you can pass a directory in. This can
# either be a specific cookbook, or the directory containing all cookbooks.
if [[ -z $1 ]]; then
    DIR=.
else
    DIR="$1"
fi

TMPFILE="out.$$"

# Green/Red messages
NORMAL=$(tput sgr0)
GREEN="$(tput bold)$(tput setaf 2)"
RED="$(tput bold)$(tput setaf 1)"
YELLOW="$(tput bold)$(tput setaf 3)"
OK="${GREEN}OK$NORMAL"
ERROR="${RED}ERROR$NORMAL"
WARN="${YELLOW}WARNING$NORMAL"

# Test for erubis first
VALIDATE_TEMPLATES=1
if ! which erubis 2>&1 >/dev/null; then
    echo "$WARN Erubis not found, template validation disabled (install chef?)"
    VALIDATE_TEMPLATES=

fi


STATUS=0
find $DIR -name '*.rb' | while IFS= read -r FILE; do
    ruby -c $FILE > /dev/null 2> $TMPFILE
    if [[ $? == 0 ]]; then
        echo "$OK $FILE"
    else
        echo "$ERROR $FILE"
        STATUS=1
        sed 's/^/    /' $TMPFILE
    fi
done
if [[ -n $VALIDATE_TEMPLATES ]]; then
    find $DIR -name '*.erb' | while IFS= read -r FILE; do
        erubis -x $FILE | ruby -c > /dev/null 2> $TMPFILE
        if [[ $? == 0 ]]; then
            echo "$OK $FILE"
        else
            echo "$ERROR $FILE"
            STATUS=1
            sed 's/^/    /' $TMPFILE
        fi
    done
fi
rm -f $TMPFILE
exit $STATUS
