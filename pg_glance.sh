#!/bin/bash

# Program: pg_glance.sh (the program name is inspired by the HP glance utility)
# Purpose: show useful linux and Postgresql performance-related information for multiple Postgres hosts, safely
# Author: James Briggs, USA
# Date: 2019 02 03
# Notes:
#
# - linux uptime command shows the run queue size. >1.0 on a database host indicates missing indexes. Contact me for consulting.
# - Postgresql 9.5+ supports UPSERT/IGNORE statements, which help improve performance and reduce ROLLBACKs
#
# Usage:
#
# - Show active queries:    ./pg_glance.sh | grep " active "
# - Show ROLLBACKS:         ./pg_glance.sh | grep ROLLBACKS:
# - Show memory settings:   ./pg_glance.sh | grep shared_buffers
# - Show slow log settings: ./pg_glance.sh | grep slow
# - Show uptimes:           ./pg_glance.sh | grep uptime
# - Show versions:          ./pg_glance.sh | grep "compiled by"
# - To repeat a command:    watch -n 15 -d "./pg_glance.sh | ..." (On Mac OS X, install watch first with 'brew install watch'.)
# - Show summary:           watch -n 15 "./pg_glance.sh | grep ':: '"

###
### start of user-defined settings
###

# postgres server hosts to query (space-separated)
hosts=""

# ignore pg_stat_activity rows containing these case-sensitive strings (pipe-separated)
ignores="BEGIN|COMMIT|pg_stat_activity|ROLLBACK|SHOW"

# remote linux user to run commands as (default user: postgres)
ssh_remote_user="postgres"

# Postgres psql command with arguments
psql_cmd="sudo -u $ssh_remote_user psql -t -q"

###
### end of user-defined settings
###

# the following commands are quick operations with no effect on the server. (Comment out as you wish.)

for h in $hosts; do
   ssh $h "\
      echo -n '$h:: uptime: ';            uptime; \
      echo -n '$h:: version: ';           $psql_cmd -c 'SELECT version()'; \
      echo -n '$h:: shared_buffers: ';    $psql_cmd -c 'SHOW shared_buffers'; \
      echo -n '$h:: slow log setting: ';  $psql_cmd -c 'SHOW log_min_duration_statement'; \
      echo -n '$h:: ROLLBACKS: ';         $psql_cmd -c 'SELECT query FROM pg_stat_activity' | grep -c ROLLBACK; \
                                          $psql_cmd -c 'SELECT * FROM pg_stat_activity' | egrep -v -e '$ignores'; \
      echo '$h:: '"
done
# | sort

exit

