/* global window, document */
/**
 * Guac-Forge — Environment badge and notice banner
 * ================================================
 * Reads envLabel, envColor and notice from window.guacBrandingConfig
 * (login-config.js, overridden by BRANDING_* env vars in env-config.js).
 *
 *   envLabel  — e.g. "PROD". Shows a coloured stripe across the top of the
 *               page with the label in a tab hanging from it.
 *   envColor  — any CSS colour. Defaults from the label: red for PROD,
 *               amber for STAGING/TEST/UAT/QA, green for anything else.
 *   notice    — text for a dismissible banner. http(s) links become
 *               clickable. Dismissal is remembered per notice text.
 *
 * Both are hidden in the remote desktop view (body.client), see
 * env-notice.css. Text is only ever inserted with textContent.
 */
(function () {
    'use strict';

    var cfg      = window.guacBrandingConfig || {};
    var label    = (typeof cfg.envLabel === 'string' && cfg.envLabel) ? cfg.envLabel : null;
    var color    = (typeof cfg.envColor === 'string' && cfg.envColor) ? cfg.envColor : null;
    var notice   = (typeof cfg.notice   === 'string' && cfg.notice)   ? cfg.notice   : null;

    var DISMISS_KEY = 'guac-forge-notice-dismissed';

    function defaultColor(text) {
        if (/prod/i.test(text)) return '#dc2626';
        if (/stag|test|uat|qa/i.test(text)) return '#d97706';
        return '#16a34a';
    }

    function addBadge() {
        var badge = document.createElement('div');
        badge.className = 'gf-env-badge';
        badge.setAttribute('role', 'note');
        badge.setAttribute('aria-label', 'Environment: ' + label);
        badge.style.setProperty('--gf-env-color', color || defaultColor(label));

        var tab = document.createElement('span');
        tab.className   = 'gf-env-badge-label';
        tab.textContent = label;
        badge.appendChild(tab);

        document.body.appendChild(badge);
    }

    /* Append text to el, turning http(s) URLs into links */
    function appendLinkified(el, text) {
        var parts = text.split(/(https?:\/\/[^\s<>"]+)/);
        for (var i = 0; i < parts.length; i++) {
            if (!parts[i]) continue;
            if (i % 2 === 1) {
                var a = document.createElement('a');
                a.href        = parts[i];
                a.textContent = parts[i];
                a.target      = '_blank';
                a.rel         = 'noopener noreferrer';
                el.appendChild(a);
            } else {
                el.appendChild(document.createTextNode(parts[i]));
            }
        }
    }

    function isDismissed() {
        try {
            return window.localStorage.getItem(DISMISS_KEY) === notice;
        } catch (e) {
            return false;
        }
    }

    function addNotice() {
        if (isDismissed()) return;

        var bar = document.createElement('div');
        bar.className = 'gf-notice';
        bar.setAttribute('role', 'status');

        var text = document.createElement('span');
        text.className = 'gf-notice-text';
        appendLinkified(text, notice);
        bar.appendChild(text);

        var close = document.createElement('button');
        close.type      = 'button';
        close.className = 'gf-notice-close';
        close.setAttribute('aria-label', 'Dismiss notice');
        close.textContent = '×';
        close.addEventListener('click', function () {
            try {
                window.localStorage.setItem(DISMISS_KEY, notice);
            } catch (e) { /* storage unavailable: dismiss for this page only */ }
            bar.parentNode.removeChild(bar);
        });
        bar.appendChild(close);

        document.body.appendChild(bar);
    }

    function start() {
        if (label)  addBadge();
        if (notice) addNotice();
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', start);
    } else {
        start();
    }

}());
