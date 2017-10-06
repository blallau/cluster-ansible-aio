FROM ubuntu
MAINTAINER Bertrand Lallau <bertrand.lallau@gmail.com>

RUN apt-get update && apt-get install -y apt-cacher-ng

VOLUME ["/var/cache/apt-cacher-ng"]

EXPOSE 3142

COPY ./acng.sh /acng.sh
COPY ./backends_kolla-ubuntu /etc/apt-cacher-ng/backends_kolla-ubuntu
COPY ./backends_kolla-centos /etc/apt-cacher-ng/backends_kolla-centos

RUN chmod 777 /var/cache/apt-cacher-ng /var/log/apt-cacher-ng
RUN sed -i -e '/Remap-gentoo: / a Remap-kollaubuntu: file:backends_kolla-ubuntu # Kolla' /etc/apt-cacher-ng/acng.conf
#RUN sed -i -e '/Remap-gentoo: / a Remap-kollacentos: file:backends_kolla-centos # Kolla' /etc/apt-cacher-ng/acng.conf

ENTRYPOINT ["/acng.sh"]
CMD ["VerboseLog=1","Debug=4","ForeGround=1","PassThroughPattern=.*"]
