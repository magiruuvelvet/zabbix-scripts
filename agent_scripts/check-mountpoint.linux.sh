#!/bin/sh
# checks if the given directory is a mount point or not

if [ $# -ne 1 ]; then
    echo "mount point required" >&2
    exit 255
fi

# util-linux: is mountpoint? 0 == yes, 32 == no
mountpoint -q "$1"
[ $? -eq 0 ] && echo 1 || echo 0
