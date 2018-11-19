FROM ubuntu:16.04

MAINTAINER ZeroC, Inc. docker-maintainers@zeroc.com

ENV ICEBOX_VERSION 3.7.1

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv B6391CB2CFBA643D \
    && echo "deb http://download.zeroc.com/Ice/3.7/ubuntu16.04 stable main" >> /etc/apt/sources.list.d/ice.list \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -y \
        zeroc-icebox=${ICEBOX_VERSION}-* \
        libzeroc-icestorm3.7=${ICEBOX_VERSION}-* \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/clock

COPY clock /etc/clock/

ENTRYPOINT ["/usr/bin/icebox", "--Ice.Config=/etc/clock/config.icebox"]
