#!/bin/sh
# checks if the given directory is a mount point or not

# TODO: *BSD support

if [ $# -ne 1 ]; then
    echo "mount point required" >&2
    exit 255
fi

OS_NAME="$(uname)"

if [[ "$OS_NAME" == "Linux" ]]; then
    # util-linux: is mountpoint? 0 == yes, 32 == no
    mountpoint -q "$1"
    [ $? -eq 0 ] && echo 1 || echo 0
else
    echo "unsupported OS" >&2
    exit 255
fi
