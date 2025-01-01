#!/bin/bash

until ./clangd_17.0.3/bin/clangd-index-server \
      /cromite.idx /home/lg/working_dir/chromium/src \
      --server-address="0.0.0.0:50051" \
      --limit-results=99999999999
do
   echo "Restarting index-server. Exited with code $?." >&2
   sleep 1
done

