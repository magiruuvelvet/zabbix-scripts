#!/bin/sh

# print number of iptables rules (excluding sshguard blocked entries)
echo -n $(iptables -S | grep -F -v -- '-A sshguard' | wc -l)
