#!/bin/bash

ovs_vswitchd_pid=$(pgrep ovs-vswitchd)
if [[ -r /proc/"${ovs_vswitchd_pid}"/root/var/run/openvswitch/db.sock ]] ; then
    plotnetcfg -D /proc/"${ovs_vswitchd_pid}"/root/var/run/openvswitch/db.sock
else
    plotnetcfg
fi
