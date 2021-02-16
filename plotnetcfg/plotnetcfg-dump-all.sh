#!/bin/bash


dot=$(command -v dot)
if [[ -z ${dot} ]]; then
    cat <<EOM
'dot' not found, won't be able to render output graph
please install graphviz
dnf -y install graphviz
EOM
fi

oc get network.operator -o yaml


#declare -a nodes
#nodes=($(oc get nodes -o 'jsonpath={.items[*].metadata.name}'))
read -ra nodes < <(oc get nodes -o 'jsonpath={.items[*].metadata.name}')


for node in "${nodes[@]}" ; do



cat <<EOM | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: plotnetcfg-debug-${node//./-}
  labels:
    app: plotnetcfg-debug
spec:
  nodeName: ${node}
  containers:
  - command: ["/bin/bash"]
    args: ["/dump-plotnetcfg.sh"]
    image: quay.io/rbrattai/ocp-test-images:master
    imagePullPolicy: Always
    name: plotnetcfg-debug-${node//./-}
    resources: {}
    securityContext:
      privileged: true
      runAsUser: 0
    stdin: true
    stdinOnce: true
    tty: true
  hostNetwork: true
  hostPID: true
  restartPolicy: Never
  terminationGracePeriodSeconds: 30
  tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
EOM

done


while true; do
    waiting=$(oc get pods -l app=plotnetcfg-debug -o 'jsonpath={.items[?(@.status.phase!="Succeeded")].metadata.name}')
    if [[ -n ${waiting} ]]; then
        echo "waiting for ${waiting}" && sleep 1
    else
        break
    fi
done

for node in "${nodes[@]}" ; do
    oc logs plotnetcfg-debug-"${node//./-}" > plotnetcfg-debug-"${node//./-}".dot
done

if [[ -n ${dot} ]]; then
    for node in "${nodes[@]}" ; do dot -o plotnetcfg-debug-"${node//./-}".pdf -T pdf plotnetcfg-debug-"${node//./-}".dot & done ; wait
    ls -l -- *.pdf

    # display with evince if available
    evince=$(command -v evince)
    if [[ -n ${evince} ]]; then
     for node in "${nodes[@]}" ; do "${evince}" plotnetcfg-debug-"${node//./-}".pdf & done
    fi
fi
