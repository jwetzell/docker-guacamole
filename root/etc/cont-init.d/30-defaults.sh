#!/usr/bin/with-contenv sh

cp -rn /app/guacamole /config

# Existing config volumes predate this setting; let env vars set properties
PROPS=/config/guacamole/guacamole.properties
grep -q '^enable-environment-properties' ${PROPS} || printf '\nenable-environment-properties: true\n' >> ${PROPS}
mkdir -p /root/.config/freerdp/known_hosts
