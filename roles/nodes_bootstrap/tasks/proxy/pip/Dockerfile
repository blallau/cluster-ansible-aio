FROM python:2
MAINTAINER Bertrand Lallau <bertrand.lallau@gmail.com>

RUN pip install devpi-server
RUN pip install devpi-web

VOLUME /var/lib/devpi

EXPOSE 3141

ADD run.sh /

CMD ["/run.sh"]
