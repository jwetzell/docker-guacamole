/* global window, document, MutationObserver */
/**
 * Modern Guacamole Branding — Login DOM enhancer
 * ================================================
 * Runs after AngularJS renders the login form and:
 *
 *   1. Applies showLocalAuth / showOidcAuth visibility rules
 *   2. Moves .sso-providers from its default position:absolute
 *      bottom-left corner INTO the login card (.login-dialog)
 *   3. Inserts an "or" divider when both auth methods are visible
 *   4. Relabels SSO provider links if configured
 *
 * Configuration lives in login-config.js (loaded first via manifest).
 *
 * Actual DOM written by Guacamole 1.5+ (see also modern-login.css):
 *
 *   div.login-ui
 *   └─ div.login-dialog-middle
 *      └─ div.login-dialog.notification
 *         └─ form.login-form
 *            ├─ div.logo
 *            ├─ div.version
 *            │  ├─ div.app-name        <- APP.NAME translation
 *            │  └─ div.version-number  <- was green absolute badge
 *            ├─ div.login-fields
 *            └─ div.buttons
 *               └─ input.login[type=submit]
 *
 *   div.sso-providers   <- injected by guacamole-auth-sso, originally
 *   └─ ul.sso-provider-list   position:abs bottom-left; we move it in
 *      └─ li > a
 */
(function () {
    'use strict';

    /* -----------------------------------------------------------------------
     * Read configuration (set in login-config.js)
     * ----------------------------------------------------------------------- */
    var cfg           = window.guacBrandingConfig || {};
    var showLocalAuth = cfg.showLocalAuth !== false;   // default true
    var showOidcAuth  = cfg.showOidcAuth  !== false;   // default true
    var oidcLabel     = (typeof cfg.oidcButtonText === 'string' && cfg.oidcButtonText)
                        ? cfg.oidcButtonText : null;

    var appTitle    = (typeof cfg.appTitle    === 'string' && cfg.appTitle)    ? cfg.appTitle    : null;
    var appSubtitle = (typeof cfg.appSubtitle === 'string' && cfg.appSubtitle) ? cfg.appSubtitle : null;

    /* State flag — prevent double-application */
    var applied = false;

    /* -----------------------------------------------------------------------
     * Core branding function
     * ----------------------------------------------------------------------- */
    function applyBranding() {

        /* Wait until .login-dialog is in the DOM */
        var card = document.querySelector('.login-ui .login-dialog');
        if (!card) return false;

        /* Wait until AngularJS has compiled the version block.
         * NOTE: .login-fields may contain no inputs when local auth is
         * disabled, so we only require .version to be present. */
        var hasContent = card.querySelector('.version');
        if (!hasContent) return false;

        /* Find the .sso-providers div (may not be present yet) */
        var ssoDiv = document.querySelector('.sso-providers');

        /* If OIDC is wanted but the SSO div is not in the DOM yet, keep
         * waiting so we can move it in. */
        if (showOidcAuth && !ssoDiv) return false;

        /* Run only once per page lifecycle */
        if (applied) return true;
        applied = true;

        /* -------------------------------------------------------------------
         * 0. Override title text and browser tab title
         * .app-name is rendered by AngularJS from APP.NAME translation;
         * we overwrite its textContent after the compile completes.
         * ------------------------------------------------------------------- */
        if (appTitle) {
            var appNameEl = card.querySelector('.version .app-name');
            if (appNameEl) {
                appNameEl.textContent = appTitle;
            }
            document.title = appTitle;
        }

        if (appSubtitle) {
            var versionDiv = card.querySelector('.version');
            if (versionDiv && !card.querySelector('.guac-brand-subtitle')) {
                var subEl       = document.createElement('div');
                subEl.className = 'guac-brand-subtitle';
                subEl.textContent = appSubtitle;
                /* Insert after .version-number if present, else append */
                var verNum = versionDiv.querySelector('.version-number');
                if (verNum && verNum.nextSibling) {
                    versionDiv.insertBefore(subEl, verNum.nextSibling);
                } else {
                    versionDiv.appendChild(subEl);
                }
            }
        }

        /* -------------------------------------------------------------------
         * 1. Apply local-auth visibility
         * ------------------------------------------------------------------- */
        var loginFields = card.querySelector('.login-fields');
        var buttonsDiv  = card.querySelector('.buttons');

        if (!showLocalAuth) {
            if (loginFields) loginFields.style.display = 'none';
            if (buttonsDiv)  buttonsDiv.style.display  = 'none';
        }

        /* -------------------------------------------------------------------
         * 2. Move .sso-providers inside the card and style it
         * ------------------------------------------------------------------- */
        if (ssoDiv) {

            if (!showOidcAuth) {
                /* Hide entirely */
                ssoDiv.style.display = 'none';
            } else {
                /* Only move if not already inside the card */
                if (!card.contains(ssoDiv)) {

                    var form = card.querySelector('.login-form');
                    if (form) {
                        /* Insert at the end of the form */
                        form.appendChild(ssoDiv);
                    } else {
                        card.appendChild(ssoDiv);
                    }
                }

                /* Reset position:absolute from the SSO extension's CSS.
                 * The class-level override in modern-login.css handles
                 * this once the element is inside .login-dialog, but we
                 * also set inline style as a belt-and-braces measure. */
                ssoDiv.style.position = 'static';
                ssoDiv.style.bottom   = 'auto';
                ssoDiv.style.left     = 'auto';
                ssoDiv.style.padding  = '0';

                /* Relabel provider links if configured */
                var links = ssoDiv.querySelectorAll('.sso-provider-list li a, .sso-provider-list li button');
                if (oidcLabel && links.length === 1) {
                    /* Only auto-relabel when there is exactly one provider,
                     * to avoid overwriting distinct provider names. */
                    links[0].textContent = oidcLabel;
                }

                /* -----------------------------------------------------------
                 * 3. "or" divider — only when both auth sections are visible
                 * ----------------------------------------------------------- */
                if (showLocalAuth) {
                    var existingDivider = card.querySelector('.guac-auth-divider');
                    if (!existingDivider) {
                        var divider      = document.createElement('div');
                        divider.className = 'guac-auth-divider';
                        var span         = document.createElement('span');
                        span.textContent = 'or';
                        divider.appendChild(span);

                        /* Insert before .sso-providers inside the form */
                        ssoDiv.parentNode.insertBefore(divider, ssoDiv);
                    }
                }
            }
        }

        return true;
    }

    /* -----------------------------------------------------------------------
     * Bootstrap: run immediately or wait for DOM via MutationObserver
     * ----------------------------------------------------------------------- */
    var observer = new MutationObserver(function () {
        if (applyBranding()) {
            observer.disconnect();
        }
    });

    function start() {
        if (!applyBranding()) {
            observer.observe(document.body, {
                childList: true,
                subtree:   true
            });
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }

}());
