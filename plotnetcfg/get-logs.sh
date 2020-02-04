#!/bin/bash


for node in $(oc get nodes -o 'jsonpath={.items[*].metadata.name}') ; do
    oc logs plotnetcfg-debug-${node//./-} > plotnetcfg-debug-${node//./-}.dot
done
