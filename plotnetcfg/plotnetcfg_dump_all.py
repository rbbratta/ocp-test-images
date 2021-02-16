#!/usr/bin/env python3
import logging
import os
import time
from subprocess import run, Popen


def which(program: str) -> str:
    paths = (os.path.join(path, program) for path in os.environ.get('PATH', '').split(os.pathsep))
    matches = (os.path.realpath(p) for p in paths if os.path.exists(
        p) and os.access(p, os.X_OK))
    return next(matches, '')


APP = "plotnetcfg-debug"

POD_MANIFEST = """
apiVersion: v1
kind: Pod
metadata:
  name: {pod_name}
  labels:
    app: {app}
spec:
  nodeName: {node}
  containers:
  - command: ["/bin/bash"]
    args: ["/dump-plotnetcfg.sh"]
    image: quay.io/rbrattai/ocp-test-images:master
    imagePullPolicy: Always
    name: {pod_name}
    resources: {{}}
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
"""


def main():
    app = APP
    graph_format = "pdf"
    logging.basicConfig(level=logging.DEBUG)
    dot = which("dot")
    if not dot:
        logging.warning("'dot' command not present, won't be able to render graph\nplease:\n dnf -y install graphviz")

    run(["oc", "get", "network.operator", "-o", "yaml"], check=True)
    nodes = run(["oc", "get", "nodes", "-o", "jsonpath={.items[*].metadata.name}"], check=True, capture_output=True,
                text=True).stdout.split()
    names = [(node, f'{app}-{node.replace(".", "-")}') for node in nodes]
    for node, pod_name in names:
        run(["oc", "create", "-f", "-"], input=POD_MANIFEST.format(node=node, pod_name=pod_name, app=app), text=True)

    waiting = "start"
    while waiting:
        waiting = run(["oc", "get", "pods", "-l", f"app={app}", "-o",
                       'jsonpath={.items[?(@.status.phase!="Succeeded")].metadata.name}'],
                      capture_output=True, text=True).stdout.strip()
        if waiting:
            print("waiting for ", waiting)
            time.sleep(1)

    for node, pod_name in names:
        with open(f"{pod_name}.dot", "w") as f:
            run(["oc", "logs", pod_name], stdout=f)

    if dot:
        procs = [Popen([dot, "-o", f"{pod_name}.{graph_format}", "-T", graph_format,
                        f"{pod_name}.dot"]) for node, pod_name in names]
        for proc in procs:
            proc.wait()

        evince = which("evince")
        if evince:
            for node, pod_name in names:
                Popen([evince, f"{pod_name}.{graph_format}"])


if __name__ == "__main__":
    main()
