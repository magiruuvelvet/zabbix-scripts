#!/bin/sh

iptables_bin=

case "$1" in
  ipv4)
    iptables_bin=iptables
    ;;

  ipv6)
    iptables_bin=ip6tables
    ;;

  *) exit 1 ;;
esac

# print number of iptables rules (excluding sshguard blocked entries)
echo -n $("$iptables_bin" -S | grep -F -v -- '-A sshguard' | wc -l)
