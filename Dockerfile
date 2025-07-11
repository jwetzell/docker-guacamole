FROM jwetzell/guacamole:base

WORKDIR ${GUACAMOLE_HOME}

# Link FreeRDP to where guac expects it to be
RUN ln -s /usr/local/lib/freerdp /usr/lib/x86_64-linux-gnu/freerdp || exit 0

# Install guacamole-server

RUN curl -SLO "https://archive.apache.org/dist/guacamole/${GUAC_VER}/source/guacamole-server-${GUAC_VER}.tar.gz" \
 && tar -xzf guacamole-server-${GUAC_VER}.tar.gz \
 && cd guacamole-server-${GUAC_VER} \
 && export LDFLAGS="-lrt" \
 && ./configure --enable-allow-freerdp-snapshots \
 && make -j$(getconf _NPROCESSORS_ONLN) \
 && make install \
 && cd .. \
 && rm -rf guacamole-server-${GUAC_VER}.tar.gz guacamole-server-${GUAC_VER} \
 && ldconfig

# Create directory for extensions
RUN mkdir ${GUACAMOLE_HOME}/extensions-available

# Install guacamole-client and postgres auth adapter
RUN set -xe \
  && rm -rf ${CATALINA_HOME}/webapps/ROOT \
  && curl -SLo ${CATALINA_HOME}/webapps/ROOT.war "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-${GUAC_VER}.war" \
  && curl -SLo ${GUACAMOLE_HOME}/lib/postgresql-42.1.4.jar "https://jdbc.postgresql.org/download/postgresql-42.2.24.jar" \
  && curl -SLO "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-auth-jdbc-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-jdbc-${GUAC_VER}.tar.gz \
  && cp guacamole-auth-jdbc-${GUAC_VER}/postgresql/guacamole-auth-jdbc-postgresql-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions/ \
  && cp -R guacamole-auth-jdbc-${GUAC_VER}/postgresql/schema ${GUACAMOLE_HOME}/ \
  && rm -rf guacamole-auth-jdbc-${GUAC_VER} guacamole-auth-jdbc-${GUAC_VER}.tar.gz

# add auth-sso to available extensions folder structur differs from other extensions
RUN set -xe \
  && echo "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-auth-sso-${GUAC_VER}.tar.gz" \
  && curl -SLO "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-auth-sso-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-auth-sso-${GUAC_VER}.tar.gz \
  && cp guacamole-auth-sso-${GUAC_VER}/cas/guacamole-auth-sso-cas-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-sso-${GUAC_VER}/openid/guacamole-auth-sso-openid-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && cp guacamole-auth-sso-${GUAC_VER}/saml/guacamole-auth-sso-saml-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && rm -rf guacamole-auth-sso-${GUAC_VER} guacamole-auth-sso-${GUAC_VER}.tar.gz

# add vault to available extensions, folder structur differs from other extensions
RUN set -xe \
  && echo "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-vault-${GUAC_VER}.tar.gz" \
  && curl -SLO "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-vault-${GUAC_VER}.tar.gz" \
  && tar -xzf guacamole-vault-${GUAC_VER}.tar.gz \
  && cp guacamole-vault-${GUAC_VER}/ksm/guacamole-vault-ksm-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
  && rm -rf guacamole-vault-${GUAC_VER} guacamole-vault-${GUAC_VER}.tar.gz

# Add optional extensions
RUN set -xe \
  && for i in auth-ban auth-duo auth-header auth-json auth-ldap auth-quickconnect auth-totp auth-restrict history-recording-storage; do \
    echo "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && curl -SLO "https://archive.apache.org/dist/guacamole/${GUAC_VER}/binary/guacamole-${i}-${GUAC_VER}.tar.gz" \
    && tar -xzf guacamole-${i}-${GUAC_VER}.tar.gz \
    && cp guacamole-${i}-${GUAC_VER}/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions-available/ \
    && rm -rf guacamole-${i}-${GUAC_VER} guacamole-${i}-${GUAC_VER}.tar.gz \
  ;done

ENV PATH="/usr/local/pgsql/bin:$PATH"
ENV GUACAMOLE_HOME=/config/guacamole

WORKDIR /config

COPY root /

EXPOSE 8080

ENTRYPOINT [ "/init" ]

