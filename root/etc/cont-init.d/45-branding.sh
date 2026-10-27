#!/usr/bin/with-contenv sh

# Build the branding extension when "branding" is listed in EXTENSIONS.
# Uses /config/branding if present, otherwise the bundled default.
case ",${EXTENSIONS}," in
  *,branding,*) ;;
  *) exit 0 ;;
esac

SRC=/app/branding
[ -d /config/branding ] && SRC=/config/branding
echo "Building branding extension from ${SRC}"

BUILD=$(mktemp -d)
cp -r ${SRC}/. ${BUILD}
mkdir -p ${BUILD}/js ${BUILD}/translations/env

json() {
  printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\r\n')"
}

bool() {
  [ "$1" = "true" ] && echo true || echo false
}

# The login script waits for the SSO button forever if none is ever rendered,
# so hide it unless an SSO extension is enabled or BRANDING_SHOW_SSO says otherwise.
if [ -n "${BRANDING_SHOW_SSO}" ]; then
  SHOW_SSO=$(bool ${BRANDING_SHOW_SSO})
else
  case ",${EXTENSIONS}," in
    *,auth-sso-*) ;;
    *) SHOW_SSO=false ;;
  esac
fi

{
  echo "Object.assign(window.guacBrandingConfig = window.guacBrandingConfig || {}, {"
  [ -n "${SHOW_SSO}" ] && echo "    showOidcAuth: ${SHOW_SSO},"
  [ -n "${BRANDING_SHOW_LOCAL}" ] && echo "    showLocalAuth: $(bool ${BRANDING_SHOW_LOCAL}),"
  [ -n "${BRANDING_SSO_TEXT}" ] && echo "    oidcButtonText: $(json "${BRANDING_SSO_TEXT}"),"
  [ -n "${BRANDING_TITLE}" ] && echo "    appTitle: $(json "${BRANDING_TITLE}"),"
  [ -n "${BRANDING_SUBTITLE}" ] && echo "    appSubtitle: $(json "${BRANDING_SUBTITLE}"),"
  echo "});"
} > ${BUILD}/js/env-config.js

if [ -n "${BRANDING_TITLE}" ]; then
  echo "{ \"APP\" : { \"NAME\" : $(json "${BRANDING_TITLE}") } }" > ${BUILD}/translations/env/en.json
else
  echo "{}" > ${BUILD}/translations/env/en.json
fi

jar cfM ${GUACAMOLE_HOME}/extensions-available/guacamole-branding-${GUAC_VER}.jar -C ${BUILD} .
rm -rf ${BUILD}
