FROM ubuntu
MAINTAINER Bertrand Lallau <bertrand.lallau@gmail.com>

RUN apt-get update && apt-get install -y apt-cacher-ng && \
    apt-get clean && \
    rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin

VOLUME ["/var/cache/apt-cacher-ng"]

EXPOSE 3142

COPY ./acng.sh /acng.sh

RUN chmod 777 /var/cache/apt-cacher-ng /var/log/apt-cacher-ng
# Comment all Remap other than ubuntu and fedora ones
RUN sed -i -e 's/^\(Remap-[dcsag]\)/#\1/' /etc/apt-cacher-ng/acng.conf

ENTRYPOINT ["/acng.sh"]
CMD ["VerboseLog=1","Debug=4","ForeGround=1","PassThroughPattern=.*"]
