/**
 * Modern Guacamole Branding — Login Configuration
 * ================================================
 * Edit these values to customise the login page.
 *
 * In Guac-Forge, copy this folder to /config/branding, edit it, and
 * restart the container; the extension is rebuilt on startup. BRANDING_*
 * environment variables (js/env-config.js) take precedence over these.
 */
window.guacBrandingConfig = {

    /* ------------------------------------------------------------------
     * Authentication method visibility
     * ------------------------------------------------------------------
     *
     * showLocalAuth  — show the username / password form.
     *                  Set false for OIDC-only deployments.
     *
     * showOidcAuth   — show the SSO / OIDC redirect button.
     *                  Requires guacamole-auth-openid-*.jar to be
     *                  installed; set false to hide the button even
     *                  when the extension is present.
     * ------------------------------------------------------------------ */
    showLocalAuth: true,
    showOidcAuth:  true,

    /* ------------------------------------------------------------------
     * OIDC button label
     * Set to null to keep the default text supplied by the openid
     * extension (typically "Login with OpenID Connect").
     * ------------------------------------------------------------------ */
    oidcButtonText: "Sign in with SSO",

    /* ------------------------------------------------------------------
     * Branding text shown below the logo
     * Set either value to null to hide it.
     * ------------------------------------------------------------------ */
    appTitle:    "Guacamole - Remote Access",
    appSubtitle: null,

    /* ------------------------------------------------------------------
     * Environment badge (Guac-Forge, see env-notice.js)
     * envLabel  — e.g. "PROD"; null hides the badge.
     * envColor  — any CSS colour; null picks one from the label
     *             (PROD red, STAGING/TEST/UAT/QA amber, otherwise green).
     * ------------------------------------------------------------------ */
    envLabel: null,
    envColor: null,

    /* ------------------------------------------------------------------
     * Notice banner (Guac-Forge, see env-notice.js)
     * Dismissible message on every page except remote sessions; links
     * become clickable. null hides it.
     * ------------------------------------------------------------------ */
    notice: null,

};
