FROM ubuntu:trusty

ENV OPENDKIM_ENABLED=true

RUN apt-get update && apt-get install -y \
    supervisor \
    postfix-pgsql \
    sasl2-bin \
    libsasl2-modules \
    libpam-pgsql \
    opendkim \
    opendkim-tools \
    dovecot-pgsql \
    dovecot-imapd \
    dovecot-pop3d

ADD ./assets /assets
RUN chmod +x /assets/*.sh && \
    bash /assets/install.sh

CMD ["sleep", "infinity"]
#CMD /opt/install.sh;/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
