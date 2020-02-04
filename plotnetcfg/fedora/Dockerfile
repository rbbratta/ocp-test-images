FROM fedora:31


RUN dnf install -y plotnetcfg rsync procps-ng && dnf clean all

ADD dump-plotnetcfg.sh /

ENTRYPOINT ["bash", "/dump-plotnetcfg.sh"]
