FROM library/tomcat:9-jre11-openjdk-bullseye

ENV ARCH=amd64 \
    GUAC_VER=1.5.1 \
    GUACAMOLE_HOME=/app/guacamole \
    PG_MAJOR=9.6 \
    PGDATA=/config/postgres \
    POSTGRES_USER=guacamole \
    POSTGRES_DB=guacamole_db

# Add Postgres Repository
RUN apt-get update && apt-get install -y curl ca-certificates gnupg
RUN curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg > /dev/null
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" >> /etc/apt/sources.list.d/pgdg.list

# Install dependencies
RUN apt-get update \
 && apt-get install -y \
    libcairo2-dev libjpeg62-turbo-dev libpng-dev libavformat-dev libwebsockets-dev\
    libossp-uuid-dev libavcodec-dev libavutil-dev \
    libswscale-dev freerdp2-dev libfreerdp-client2-2 libpango1.0-dev \
    libssh2-1-dev libtelnet-dev libvncserver-dev \
    libpulse-dev libssl-dev libvorbis-dev libwebp-dev libwebsockets-dev \
    ghostscript build-essential postgresql-${PG_MAJOR} \
  && rm -rf /var/lib/apt/lists/*


# Apply the s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${ARCH}.tar.gz /tmp
RUN tar -xzf /tmp/s6-overlay-${ARCH}.tar.gz -C / \
 && tar -xzf /tmp/s6-overlay-${ARCH}.tar.gz -C /usr ./bin \
 && rm -rf /tmp/s6-overlay-${ARCH}.tar.gz

RUN mkdir -p ${GUACAMOLE_HOME} \
    ${GUACAMOLE_HOME}/lib \
    ${GUACAMOLE_HOME}/extensions

WORKDIR ${GUACAMOLE_HOME}

# Link FreeRDP to where guac expects it to be
RUN [ "$ARCH" = "armhf" ] && ln -s /usr/local/lib/freerdp /usr/lib/arm-linux-gnueabihf/freerdp || exit 0
RUN [ "$ARCH" = "amd64" ] && ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

RUN echo $PATH

# Install guacamole-server
RUN curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
 && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
 && cd guacamole-server-${GUAC_VER} \
 && ./configure --enable-allow-freerdp-snapshots \
 && make -j$(getconf _NPROCESSORS_ONLN) \
 && make install \
 && cd .. \
 && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
 && ldconfig

# Create directory for extensions
RUN mkdir ${GUACAMOLE_HOME}/extensions-available

# Install guacamole-client and postgres auth adapter
RUN set -x \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.1.4.jar "https://jdbc.postgresql.org/download/postgresql-42.2.24.jar" \
  && curl -SLO "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && cp guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-jdbc-${GUAC_VER}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-jdbc-${GUAC_VER}/sqlserver/guacamole-auth-jdbc-sqlserver-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# add auth-sso to available extensions folder structur differs from other extensions
RUN set -xe \
  && echo "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-auth-sso-${GUAC_VER}.tar.gz" \
  && curl -SLO "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-auth-sso-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-sso-${GUAC_VER}.tar.gz \
  && cp guacamole-auth-sso-${GUAC_VER}/cas/guacamole-auth-sso-cas-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-sso-${GUAC_VER}/openid/guacamole-auth-sso-openid-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-sso-${GUAC_VER}/saml/guacamole-auth-sso-saml-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && rm -rf guacamole-auth-sso-${GUAC_VER} guacamole-auth-sso-${GUAC_VER}.tar.gz

# add vault to available extensions folder structur differs from other extensions
RUN set -xe \
  && echo "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-vault-${GUAC_VER}.tar.gz" \
  && curl -SLO "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-vault-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-vault-${GUAC_VER}.tar.gz \
  && cp guacamole-vault-${GUAC_VER}/ksm/guacamole-vault-ksm-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && rm -rf guacamole-vault-${GUAC_VER} guacamole-vault-${GUAC_VER}.tar.gz

# Add optional extensions
RUN set -xe \
  && for i in auth-duo auth-header auth-json auth-ldap auth-quickconnect auth-totp history-recording-storage; do \
    echo "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "https://dlcdn.apache.org/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_VER}/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

ENV PATH=/usr/lib/postgresql/${PG_MAJOR}/bin:$PATH
ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

EXPOSE 8080

ENTRYPOINT [ "/init" ]
