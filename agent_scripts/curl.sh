#!/bin/sh

curl_options=""

if [ -z "$1" ]; then
    echo "Usage: curl.get[\"url\",(header|header-get|body|all)]"
    exit 255
fi

case "$2" in
    # perform HEAD request and only print headers
    "header") curl_options="-I" ;;

    # force GET request and only print headers
    # some services might respond with different or no headers on HEAD requests
    "header-get") curl_options="-I -X GET" ;;

    # only print body
    "body") curl_options="" ;;

    # print headers and body
    "all") curl_options="-i" ;;

    # only print body
    *) curl_options="" ;;
esac

exec curl $curl_options "$1"
