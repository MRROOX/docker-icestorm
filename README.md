# IceStorm en Docker Container

Este demo se muestra como utilizar [IceStorm][1] dentro de un Contendor Docker y como ejecutar el ejemplo Clock.

Se define un sistema de directorios en donde trabajaremos.
```
DOCKERICESTORM/
    /DockerIceStormClock
    /IceStormConfig
```
En el directorio DockerIceStormClock guardaremos el ejemplo de clock.
En el directorio IceStormConfig guardaremos los archivos de configuración del servicio IceStorm.

En el directorio DockerIceStormClock se debe copiar el ejemplo de clock, que encontraremos en el directorio  ice-demos/python/IceStorm/clock

Se debe clonar el ejemplo desde el repositorio oficial de zeroc-ice.
```
git clone https://github.com/zeroc-ice/ice-demos.git
```

Dentro del ejemplo clock se encuentran 2 archivos que serviran para configurar el servicio de IceStorm dentro del contendor de Docker.

Los archivos son config.icebox y config.service.

Estos dos archivos los copiaremos al directorio de trabajo IceStormConfig.


# Tambien debemos modificar el archivo config.icebox de la siguiente forma.

Las siguientes linea :

```
Ice.Admin.Endpoints=tcp -h localhost -p 9996

IceBox.Service.IceStorm=IceStormService,37:createIceStorm --Ice.Config=config.service
```

Debemos cambiarla por:
```
Ice.Admin.Endpoints=tcp -h <nombre_del_contenedor> -p 9996

IceBox.Service.IceStorm=IceStormService,37:createIceStorm --Ice.Config=/etc/IceStormConfig/config.service
```

El archivo de configuración config.icebox queda de la siguiente forma:

```
#
# Enable Ice.Admin object
# The IceStorm service has its own endpoints (see config.service).
#
Ice.Admin.Endpoints=tcp -h <nombre_del_contenedor> -p 9996
Ice.Admin.InstanceName=icebox

#
# The IceStorm service. The service is configured using a separate
# configuration file (see config.service).
#
IceBox.Service.IceStorm=IceStormService,37:createIceStorm --Ice.Config=/etc/IceStormConfig/config.service

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

Las siguientes linea :

```
IceStorm.TopicManager.Endpoints=default -h localhost -p 10000

IceStorm.Publish.Endpoints=tcp -h localhost -p 10001:udp -h localhost -p 10001

IceStorm.LMDB.Path=db

```

Debemos cambiarla por:
```
IceStorm.TopicManager.Endpoints=default -h <nombre_del_contenedor> -p 10000

IceStorm.Publish.Endpoints=tcp -h <nombre_del_contenedor> -p 10001:udp -h <nombre_del_contenedor> -p 10001

IceStorm.LMDB.Path=db
```
El archivo de configuración config.service queda de la siguiente forma:

```
#
# The IceStorm service instance name.
#
IceStorm.InstanceName=DemoIceStorm
#
# This property defines the endpoints on which the IceStorm
# TopicManager listens.
#

IceStorm.TopicManager.Endpoints=default -h <nombre_del_contenedor> -p 10000

#
# This property defines the endpoints on which the topic
# publisher objects listen. If you want to federate
# IceStorm instances this must run on a fixed port (or use
# IceGrid).
#
IceStorm.Publish.Endpoints=tcp -h <nombre_del_contenedor> -p 10001:udp -h <nombre_del_contenedor> -p 10001

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
IceStorm.LMDB.Path=/etc/DockerIceStormClock/db

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


# VOLUME ["/data" ]

# ENTRYPOINT ["/usr/bin/icebox", "--IceBox.Service.IceStorm=IceStormService,37:createIceStorm \
#                                                           --Ice.Config=/etc/icestorm.conf \
#                                                           --Freeze.DbEnv.IceStorm.DbHome=/data"]

#IceStorm new Config.

EXPOSE 10000 10001 9996

RUN mkdir -p /etc/IceStormConfig

CMD [ "/bin/bash" ]
```

# Ahora vamos a construir la Imagen Docker 

```
docker build --tag dockerice:first .
```
# Para desplegar la imagen ejecutamos el siguiente comando.

Es importante destacar que al usar "$(pwd)" montaremos un volumen desde donde estemos parados en el directorio.

Tambien expondremos los puertos 10000 y 10001.

Además utilizaremos la imagen que hemos creado "dockerice:first".

```
docker run -ti -p 10000:10000 -p 10001:10001 --name dockerice -v "$(pwd)"/IceStormConfig:/etc/IceStormConfig -v"$(pwd)"/DockerIceStormClock:/data dockerice:first

```

# Ingresar dentro del contenedor en ejecucion 

```
docker exec -it dockerice bash

```
Dentro del contendor debemos ontener el nombre del contenedor.

```
root@1ee59c2b3d3d:/# cat /etc/hosts
127.0.0.1       localhost
::1     localhost ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
172.17.0.2      1ee59c2b3d3d

```

El nombre del contenedor es 1ee59c2b3d3d

Debemos salir del contenedor escribiendo exit.

Este nombre lo utilizaremos para configurar el <nombre_del_contenedor> los archivos config.icebox y config.service 

Luego que modifiquemos los archivos debemos parar y luego iniciar el contenedor.


```
docker stop dockerice

docker start dockerice

```
# Iniciando el servicio de IceStorm dentro del Contenedor Docker.

Para iniciar el servicio de icestorm, debemos ingresar nuevamente a nuestro contenedor

```
docker exec -it dockerice bash
```

Y ahora iniciaremos el servicio con el siguiente comando:

```
icebox --Ice.Config=/etc/IceStormConfig/config.icebox &
```

O el siguiente comando para dejarlo en segundo plano.
```
icebox --Ice.Config=/etc/IceStormConfig/config.icebox
```




# Configurar publicher.py

Debemos modificar el archivo config.pub y modificar la ip <ip_DOCKERHUB_ice_storm> del servicio de IceStorm.

Esta <ip_DOCKERHUB_ice_storm> es la ip del docker hub o del servidor o pc en donde se encuentre ejecutando el contenedor.

```
#
# This property is used by the clients to connect to IceStorm.
#
TopicManager.Proxy=DemoIceStorm/TopicManager:default -h <ip_DOCKERHUB_ice_storm> -p 10000

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

Debemos modificar el archivo config.sub y modificar la ip <ip_DOCKERHUB_ice_storm> del servicio de IceStorm.

Esta <ip_DOCKERHUB_ice_storm> es la ip del docker hub o del servidor o pc en donde se encuentre ejecutando el contenedor.

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
TopicManager.Proxy=DemoIceStorm/TopicManager:default -h <ip_DOCKERHUB_ice_storm> -p 10000

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
