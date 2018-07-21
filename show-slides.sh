#!/bin/bash

if [[ ! -e ./.patat-v0.7.2.0-linux-x86_64/patat ]] ; then
    curl -OL https://github.com/jaspervdj/patat/releases/download/v0.7.2.0/patat-v0.7.2.0-linux-x86_64.tar.gz
    tar xfz patat-v0.7.2.0-linux-x86_64.tar.gz
    mv patat-v0.7.2.0-linux-x86_64 .patat-v0.7.2.0-linux-x86_64
    rm patat-v0.7.2.0-linux-x86_64.tar.gz
fi

docker run -v $(pwd):/data --rm -ti ubuntu:18.04 /bin/bash -c "cd data ; export LC_ALL=C.UTF-8 ; export LANG=C.UTF-8 ; ./.patat-v0.7.2.0-linux-x86_64/patat -w ./SLIDES.md"
