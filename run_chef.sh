#!/bin/bash
##############################################################################
# Copyright (c) 2013-2014, OmniTI Computer Consulting, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name OmniTI Computer Consulting, Inc. nor the names
#       of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##############################################################################
# Simple chef solo wrapper
#
# - Runs chef once, pulling from git first
# - Uses the hostname environment variable to determine the role
# - Any extra arguments after -- are passed directly to chef-solo
#
# Setup Notes:
#   You need to have ssh configured for root to access the git repo. For
#   example:
#
#   Put the private key in /root/.ssh/id_rsa_chef
#   Edit /root/.ssh/config and add the following:
#
#       Host github.com
#       IdentityFile ~/.ssh/id_rsa_chef

LOCKFILE=/tmp/run_chef.lock
LOGFILE=/var/log/chef/solo.log

lock() {
    if ( set -o noclobber; echo "$$" > $LOCKFILE ) 2>/dev/null; then
        trap "rm -f $LOCKFILE; exit $?" INT TERM EXIT
        [[ -n $VERBOSE ]] && echo "Aquired lock"
        return 0
    fi
    local PID=`cat $LOCKFILE`
    local RUNNING=""
    [[ -d /proc/$PID ]] && RUNNING=" (Running)"
    echo "Failed to acquire lock. Held by $PID$RUNNING"
    return 1
}

unlock() {
    [[ -n $VERBOSE ]] && echo "Releasing lock"
    rm -f $LOCKFILE
    trap - INT TERM EXIT
}

random_delay() {
    local DELAY=$((RANDOM % 120))
    echo "Sleeping for $DELAY seconds"
    sleep $DELAY
}

log() {
    [[ -n $VERBOSE ]] && echo "$0: $@"
    echo "$0: $@" >> $LOGFILE
}

rotate_logs() {
    # Keep enough logs for a little over a day
    for ((i=50; $i>0; i--)); do
        [[ -f $LOGFILE.$i ]] && mv $LOGFILE.$i $LOGFILE.$((i+1))
    done
    [[ -f $LOGFILE ]] && mv $LOGFILE $LOGFILE.1
}

make_logdir() {
    # Make sure the log directory exists
    LOGDIR=$(dirname $LOGFILE)
    [[ -d $LOGDIR ]] || mkdir -p $LOGDIR
}

# Command line options - anything after '--' is passed directly to chef-solo
RANDOM_DELAY=
while getopts "j" opt; do
    case $opt in
        j)
            RANDOM_DELAY=1
            ;;
    esac
done
shift $(($OPTIND-1))


make_logdir
rotate_logs
[[ -n $RANDOM_DELAY ]] && random_delay
lock || exit 1
cd /var/chef
git pull 2>&1 | tee $LOGFILE
chef-solo -o "role[node-$HOSTNAME]" -N $HOSTNAME -l info -L $LOGFILE "$@"
unlock
