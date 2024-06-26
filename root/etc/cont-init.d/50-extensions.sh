#!/usr/bin/with-contenv sh

echo "Cleaning Extensions from previous Guacamole versions"
for e in $(ls -1 ${GUACAMOLE_HOME}/extensions | grep guacamole | grep -v ${GUAC_VER}); do
  rm ${GUACAMOLE_HOME}/extensions/${e}
done

echo "Cleaning Extensions"
for i in auth-duo auth-header auth-json auth-ldap auth-quickconnect auth-sso-cas auth-sso-openid auth-sso-saml auth-totp history-recording-storage vault-ksm; do
  rm -rf ${GUACAMOLE_HOME}/extensions/guacamole-${i}-${GUAC_VER}.jar
done

# enable extensions
for i in $(echo "$EXTENSIONS" | tr "," " "); do
  cp ${GUACAMOLE_HOME}/extensions-available/guacamole-${i}-${GUAC_VER}.jar ${GUACAMOLE_HOME}/extensions
done
