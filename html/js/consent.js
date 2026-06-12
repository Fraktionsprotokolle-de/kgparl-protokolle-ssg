/**
 * consent.js — DSGVO-konformes Cookie-Consent-Banner mit Matomo-Integration
 *
 * Speichert die Einwilligung in localStorage (kein Cookie nötig für die Einwilligung selbst).
 * Matomo wird NUR geladen wenn der Nutzer aktiv zustimmt.
 * Ohne Zustimmung: kein Tracking, keine Cookies, kein Matomo-Script.
 *
 * Nutzer kann Einstellung jederzeit über den Link "Cookie-Einstellungen" im Footer ändern.
 */

(function () {
  var CONSENT_KEY = 'matomo_consent';
  var MATOMO_URL = '//statistics.fraktionsprotokolle.de/';
  var SITE_ID = '1';

  function getConsent() {
    try { return localStorage.getItem(CONSENT_KEY); } catch (e) { return null; }
  }

  function setConsent(value) {
    try { localStorage.setItem(CONSENT_KEY, value); } catch (e) {}
  }

  /** Load and initialize Matomo tracking */
  function loadMatomo() {
    if (window._paq && window._matomoLoaded) return;
    var _paq = window._paq = window._paq || [];
    _paq.push(['trackPageView']);
    _paq.push(['enableLinkTracking']);
    (function () {
      _paq.push(['setTrackerUrl', MATOMO_URL + 'matomo.php']);
      _paq.push(['setSiteId', SITE_ID]);
      var d = document, g = d.createElement('script'), s = d.getElementsByTagName('script')[0];
      g.async = true; g.src = MATOMO_URL + 'matomo.js'; s.parentNode.insertBefore(g, s);
    })();
    window._matomoLoaded = true;
  }

  /** Create and show the consent banner */
  function showBanner() {
    if (document.getElementById('consent-banner')) return;

    var banner = document.createElement('div');
    banner.id = 'consent-banner';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Cookie-Einstellungen');
    banner.innerHTML =
      '<div class="consent-inner">' +
        '<div class="consent-text">' +
          '<strong>Statistik-Cookies</strong>' +
          '<p>Wir nutzen Matomo zur anonymen Auswertung der Seitennutzung. ' +
          'Es werden keine personenbezogenen Daten an Dritte weitergegeben. ' +
          '<a href="https://kgparl.de/datenschutz/">Mehr erfahren</a></p>' +
        '</div>' +
        '<div class="consent-actions">' +
          '<button id="consent-accept" class="consent-btn consent-btn-accept">Akzeptieren</button>' +
          '<button id="consent-reject" class="consent-btn consent-btn-reject">Ablehnen</button>' +
        '</div>' +
      '</div>';

    document.body.appendChild(banner);

    document.getElementById('consent-accept').addEventListener('click', function () {
      setConsent('granted');
      closeBanner();
      loadMatomo();
    });
    document.getElementById('consent-reject').addEventListener('click', function () {
      setConsent('denied');
      closeBanner();
    });
  }

  function closeBanner() {
    var el = document.getElementById('consent-banner');
    if (el) el.remove();
  }

  /** Re-open banner to change settings (called from footer link) */
  window.openConsentSettings = function () {
    // Clear previous choice so banner appears fresh
    try { localStorage.removeItem(CONSENT_KEY); } catch (e) {}
    showBanner();
  };

  // --- Init ---
  var consent = getConsent();
  if (consent === 'granted') {
    loadMatomo();
  } else if (consent === null) {
    // No choice yet — show banner after DOM is ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', showBanner);
    } else {
      showBanner();
    }
  }
  // consent === 'denied' → do nothing
})();
