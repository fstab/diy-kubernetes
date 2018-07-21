#!/bin/bash

set -eu

# Sometimes apt-get update fails immediately after boot, because the repository is locked.
# Try a few times before giving up.

declare -ri sleep_interval_seconds=5
declare -ri max_retries=12

declare -i retry_count=0

while ! ( apt-get update -q && apt-get upgrade -q -y ) ; do
    sleep $sleep_interval_seconds
    (( retry_count += 1 ))
    if [[ $retry_count -ge $max_retries ]] ; then
        exit -1
    fi
done

apt-get install -q -y python
