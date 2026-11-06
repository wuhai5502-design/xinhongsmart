/* Cookie / analytics consent — xinhongsmart.com
 *
 * The site runs Google Analytics 4 (G-459FM7B610) with no other trackers.
 * Consent Mode v2 is set to "denied" in the page <head> before gtag config;
 * this file either grants it or asks first.
 *
 * Policy (2026-11-06): visitors in the EEA/UK get a banner and decide.
 * Everyone else is granted without a banner, because ePrivacy/GDPR does not
 * apply to them and the banner would only add friction. Detection uses the
 * browser time zone — good enough for a best-effort signal, and it errs
 * towards asking when it is unsure.
 *
 * To change the policy: set MODE to 'always' (ask everyone) or 'never'
 * (grant everyone, no banner). Nothing else needs editing.
 */
(function () {
  var MODE = 'auto';                     // 'auto' | 'always' | 'never'
  var KEY = 'xhs-consent';               // 'granted' | 'denied'
  var EEA_TZ = /^(Europe\/|Atlantic\/(Reykjavik|Canary|Madeira|Faroe)|Asia\/(Nicosia|Istanbul)|Africa\/(Ceuta|Melilla))/;

  function grant() {
    if (typeof gtag !== 'function') return;
    gtag('consent', 'update', {
      ad_storage: 'granted', ad_user_data: 'granted',
      ad_personalization: 'granted', analytics_storage: 'granted'
    });
  }

  function stored() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }
  function store(v) {
    try { localStorage.setItem(KEY, v); } catch (e) {}
  }

  var saved = stored();
  if (saved === 'granted') { grant(); return; }
  if (saved === 'denied') { return; }
  if (MODE === 'never') { grant(); return; }

  var tz = '';
  try { tz = Intl.DateTimeFormat().resolvedOptions().timeZone || ''; } catch (e) {}
  var mustAsk = MODE === 'always' || EEA_TZ.test(tz);
  if (!mustAsk) { grant(); return; }

  function build() {
    if (document.getElementById('xhs-consent-bar')) return;
    var bar = document.createElement('div');
    bar.id = 'xhs-consent-bar';
    bar.setAttribute('role', 'dialog');
    bar.setAttribute('aria-label', 'Analytics consent');
    bar.innerHTML =
      '<p>We use Google Analytics to see which pages help buyers. ' +
      'You can accept or decline — the site works either way. ' +
      '<a href="/privacy/">Privacy policy</a></p>' +
      '<div class="xhs-consent-actions">' +
      '<button type="button" data-choice="denied">Decline</button>' +
      '<button type="button" data-choice="granted">Accept</button>' +
      '</div>';
    bar.addEventListener('click', function (e) {
      var b = e.target.closest('button[data-choice]');
      if (!b) return;
      var v = b.getAttribute('data-choice');
      store(v);
      if (v === 'granted') grant();
      bar.remove();
      document.body.classList.remove('consent-open');
    });
    document.body.classList.add('consent-open');
    document.body.appendChild(bar);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', build);
  } else {
    build();
  }
})();
