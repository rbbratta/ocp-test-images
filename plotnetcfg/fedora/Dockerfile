FROM fedora:33


RUN dnf install -y plotnetcfg rsync procps-ng && dnf clean all

ADD dump-plotnetcfg.sh /

ENTRYPOINT ["bash", "/dump-plotnetcfg.sh"]
