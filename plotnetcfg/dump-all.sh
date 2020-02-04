#!/bin/bash



for node in $(oc get nodes -o jsonpath={.items[*].metadata.name}) ; do



cat <<EOM | oc create -f -
apiVersion: v1
kind: Pod
metadata:
  name: plotnetcfg-debug-${node//./-}
spec:
  nodeName: ${node}
  containers:
  - command: ["/bin/bash"]
    args: ["/dump-plotnetcfg.sh"]
    image: rbbratta/plotnetcfg-debug:fedora31
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
