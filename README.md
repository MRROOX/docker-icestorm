# IceStorm en Docker Container

Este demo muestra como utilizar [IceStorm][1] dentro de un Contendor Docker y como ejecutar el ejemplo Clock.

Se define un sistema de directorios en donde trabajaremos.

DOCKERICESTORM/
    /DockerIceStormClock
    /IceStormConfig



Lo primero es clonar el ejemplo desde el repositorio oficial de zeroc-ice.
```
git clone https://github.com/zeroc-ice/ice-demos.git
```
Ahora devemos buscar el directorio ice-demos/python/IceStorm/clock ésta carpeta contiene el ejemplo clock.

Copiamos la carpeta Clock dentro de nuestro directorio de trabajo.

Ahora dentro del direcotio de trabajo y luego dentro del directorio Clock vamos a modificar el archivo config.icebox  de la siguiente forma.
```
#
# Enable Ice.Admin object
# The IceStorm service has its own endpoints (see config.service).
#
Ice.Admin.Endpoints=tcp -h localhost -p 9996
Ice.Admin.InstanceName=icebox

#
# The IceStorm service. The service is configured using a separate
# configuration file (see config.service).
#
IceBox.Service.IceStorm=IceStormService,37:createIceStorm --Ice.Config=/etc/clock/config.service

#
# Warn about connection exceptions
#
#Ice.Warn.Connections=1

#
# Network Tracing
#
# 0 = no network tracing
# 1 = trace connection establishment and closure
# 2 = like 1, but more detailed
# 3 = like 2, but also trace data transfer
#
#Ice.Trace.Network=1

#
# Protocol Tracing
#
# 0 = no protocol tracing
# 1 = trace protocol messages
#
#Ice.Trace.Protocol=1
```
# Tambien debemos modificar el archivo config.service de la siguiente forma.

```
#
# The IceStorm service instance name.
#
IceStorm.InstanceName=DemoIceStorm
#
# This property defines the endpoints on which the IceStorm
# TopicManager listens.
#

IceStorm.TopicManager.Endpoints=default -h localhost -p 10000

#
# This property defines the endpoints on which the topic
# publisher objects listen. If you want to federate
# IceStorm instances this must run on a fixed port (or use
# IceGrid).
#
IceStorm.Publish.Endpoints=tcp -h localhost -p 10001:udp -h localhost -p 10001

#
# TopicManager Tracing
#
# 0 = no tracing
# 1 = trace topic creation, subscription, unsubscription
# 2 = like 1, but with more detailed subscription information
#
IceStorm.Trace.TopicManager=2

#
# Topic Tracing
#
# 0 = no tracing
# 1 = trace unsubscription diagnostics
#
IceStorm.Trace.Topic=1

#
# Subscriber Tracing
#
# 0 = no tracing
# 1 = subscriber diagnostics (subscription, unsubscription, event
#     propagation failures)
#
IceStorm.Trace.Subscriber=1

#
# Amount of time in milliseconds between flushes for batch mode
# transfer. The minimum allowable value is 100ms.
#
IceStorm.Flush.Timeout=2000

#
# Network Tracing
#
# 0 = no network tracing
# 1 = trace connection establishment and closure
# 2 = like 1, but more detailed
# 3 = like 2, but also trace data transfer
#
#Ice.Trace.Network=1

#
# This property defines the home directory of the LMDB
# database environment for the IceStorm service.
#
IceStorm.LMDB.Path=/etc/clock/db

#
# IceMX configuration.
#
#Ice.Admin.Endpoints=tcp -h localhost -p 10004
Ice.Admin.InstanceName=icestorm
IceMX.Metrics.Debug.GroupBy=id
IceMX.Metrics.ByParent.GroupBy=parent
```

# Ahora crearemos el archivo Dockerfile



Para construir la imagen vamos a utilizar el Dockerfile oficial de IceStorm [Dockerfile][2].

```
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

VOLUME ["/data"]

ENTRYPOINT ["/usr/bin/icebox", "--IceBox.Service.IceStorm=IceStormService,37:createIceStorm \
                                                          --Ice.Config=/etc/icestorm.conf \
                                                          --Freeze.DbEnv.IceStorm.DbHome=/data"]
```

# Ahora modificaremos el Dockerfile bajo nuestros requerimientos.

```
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

EXPOSE 10000 10001 9996

COPY clock /etc/clock

ENTRYPOINT ["/usr/bin/icebox", "--Ice.Config=/etc/clock/config.icebox "]
```

# Ahora vamos a construir la imagen

```
docker build --tag dockerice:first .
```
# Para desplegar la imagen ejecutamos el siguiente comando.

```
docker run -d --net=host --name dockerice dockerice:first

```
# Configurar publicher.py

Debemos modificar el archivo config.pub y modificar la ip <ip_ice_storm> del servicio de IceStorm.

```
#
# This property is used by the clients to connect to IceStorm.
#
TopicManager.Proxy=DemoIceStorm/TopicManager:default -h <ip_ice_storm> -p 10000

#
# Network Tracing
#
# 0 = no network tracing
# 1 = trace connection establishment and closure
# 2 = like 1, but more detailed
# 3 = like 2, but also trace data transfer
#
#Ice.Trace.Network=1

#
# IceMX configuration.
#
#Ice.Admin.Endpoints=tcp -h localhost -p 10003
Ice.Admin.InstanceName=publisher
IceMX.Metrics.Debug.GroupBy=id
IceMX.Metrics.ByParent.GroupBy=parent
```
# Configurar subcriber.py

Debemos modificar el archivo config.sub y modificar la ip <ip_ice_storm> del servicio de IceStorm.

```
#
# This property is used to configure the endpoints of the clock
# subscriber adapter. These endpoints are where the client receives
# topic messages from IceStorm.
#
Clock.Subscriber.Endpoints=tcp:udp

#
# Only listen on the localhost interface by default.
#
Ice.Default.Host=localhost

#
# This property is used by the clients to connect to IceStorm.
#
TopicManager.Proxy=DemoIceStorm/TopicManager:default -h <ip_ice_storm> -p 10000

#
# Network Tracing
#
# 0 = no network tracing
# 1 = trace connection establishment and closure
# 2 = like 1, but more detailed
# 3 = like 2, but also trace data transfer
#
#Ice.Trace.Network=1

#
# IceMX configuration.
#
#Ice.Admin.Endpoints=tcp -h localhost -p 10002
Ice.Admin.InstanceName=subscriber
IceMX.Metrics.Debug.GroupBy=id
IceMX.Metrics.ByParent.GroupBy=parent
```


[1]: https://doc.zeroc.com/display/Ice37/IceStorm
[2]: https://github.com/zeroc-ice/ice-dockerfiles/blob/master/3.7/icestorm/Dockerfile
