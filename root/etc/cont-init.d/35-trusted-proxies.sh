#!/usr/bin/with-contenv sh

# Trust X-Forwarded-For from the proxies in TRUSTED_PROXIES so Guacamole sees
# real client IPs (history, auth-ban). Accepts IPs and /8, /16, /24, /32 CIDRs.
SERVER_XML=${CATALINA_HOME}/conf/server.xml

# Remove the valve from a previous start so changes and unsetting apply
sed -i '/RemoteIpValve/d' ${SERVER_XML}

[ -z "${TRUSTED_PROXIES}" ] && exit 0

REGEX=""
for p in $(echo "${TRUSTED_PROXIES}" | tr "," " "); do
  if ! echo "${p}" | grep -qE '^[0-9]{1,3}(\.[0-9]{1,3}){3}(/(8|16|24|32))?$'; then
    echo "Ignoring unsupported TRUSTED_PROXIES entry: ${p}"
    continue
  fi
  ip=${p%/*}
  case "${p}" in
    */8)  r=$(echo "${ip}" | cut -d. -f1)'\.\d{1,3}\.\d{1,3}\.\d{1,3}' ;;
    */16) r=$(echo "${ip}" | cut -d. -f1-2 | sed 's/\./\\./g')'\.\d{1,3}\.\d{1,3}' ;;
    */24) r=$(echo "${ip}" | cut -d. -f1-3 | sed 's/\./\\./g')'\.\d{1,3}' ;;
    *)    r=$(echo "${ip}" | sed 's/\./\\./g') ;;
  esac
  REGEX="${REGEX:+${REGEX}|}${r}"
  ACCEPTED="${ACCEPTED:+${ACCEPTED},}${p}"
done

if [ -z "${REGEX}" ]; then
  echo "No valid TRUSTED_PROXIES entries, client IPs will not be forwarded"
  exit 0
fi

echo "Trusting X-Forwarded-For from: ${ACCEPTED}"
# awk reads the regex from ENVIRON so its backslashes are not unescaped
REGEX="${REGEX}" awk '/<\/Host>/ {
  print "        <Valve className=\"org.apache.catalina.valves.RemoteIpValve\" internalProxies=\"" ENVIRON["REGEX"] "\" remoteIpHeader=\"x-forwarded-for\" proxiesHeader=\"x-forwarded-by\" protocolHeader=\"x-forwarded-proto\" />"
} { print }' ${SERVER_XML} > ${SERVER_XML}.tmp && cat ${SERVER_XML}.tmp > ${SERVER_XML} && rm ${SERVER_XML}.tmp
