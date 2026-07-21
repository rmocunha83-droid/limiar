(function () {
  var consentKey = 'limiar.meta-consent.v1';
  var pixelID = '1567751021802834';

  function cookieValue(name) {
    var prefix = name + '=';
    var item = document.cookie.split(';').map(function (value) {
      return value.trim();
    }).find(function (value) {
      return value.indexOf(prefix) === 0;
    });
    return item ? item.slice(prefix.length) : '';
  }

  function eventID(prefix) {
    var randomPart = window.crypto && window.crypto.randomUUID
      ? window.crypto.randomUUID()
      : Math.random().toString(36).slice(2);
    return prefix + '_' + Date.now() + '_' + randomPart;
  }

  function sendServerEvent(eventName, id) {
    fetch('/api/meta-capi', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      keepalive: true,
      body: JSON.stringify({
        eventName: eventName,
        eventID: id,
        eventTime: Math.floor(Date.now() / 1000),
        eventSourceURL: window.location.href,
        fbp: cookieValue('_fbp'),
        fbc: cookieValue('_fbc')
      })
    }).catch(function () {});
  }

  function trackEvent(eventName, prefix) {
    var id = eventID(prefix);
    window.fbq('track', eventName, {}, { eventID: id });
    sendServerEvent(eventName, id);
  }

  function trackCustomEvent(eventName, prefix, customData) {
    var id = eventID(prefix);
    window.fbq('trackCustom', eventName, customData, { eventID: id });
    sendServerEvent(eventName, id);
  }

  function isMostlyVisible(element) {
    var rect = element.getBoundingClientRect();
    var viewportWidth = window.innerWidth || document.documentElement.clientWidth;
    var viewportHeight = window.innerHeight || document.documentElement.clientHeight;
    var visibleWidth = Math.max(0, Math.min(rect.right, viewportWidth) - Math.max(rect.left, 0));
    var visibleHeight = Math.max(0, Math.min(rect.bottom, viewportHeight) - Math.max(rect.top, 0));
    var totalArea = rect.width * rect.height;

    return totalArea > 0 && (visibleWidth * visibleHeight) / totalArea >= 0.5;
  }

  function trackVideoEngagement() {
    var trackedThresholds = {};
    var thresholds = [25, 50, 70];

    document.querySelectorAll('[data-meta-video-id]').forEach(function (video) {
      if (video.dataset.metaVideoTrackingReady === 'true') return;
      video.dataset.metaVideoTrackingReady = 'true';

      video.addEventListener('timeupdate', function () {
        if (!Number.isFinite(video.duration) || video.duration <= 0 || !isMostlyVisible(video)) return;

        var watchedPercent = (video.currentTime / video.duration) * 100;
        thresholds.forEach(function (threshold) {
          if (trackedThresholds[threshold] || watchedPercent < threshold) return;

          trackedThresholds[threshold] = true;
          trackCustomEvent('VideoWatched' + threshold, 'video_watched_' + threshold, {
            content_name: video.dataset.metaVideoName || 'Demonstracao do app Limiar',
            content_type: 'video',
            video_id: video.dataset.metaVideoId,
            video_percent: threshold
          });
        });
      });
    });
  }

  function startMetaTracking() {
    if (window.fbq) return;
    !function(f,b,e,v,n,t,s) {
      if(f.fbq)return;n=f.fbq=function(){n.callMethod?
      n.callMethod.apply(n,arguments):n.queue.push(arguments)};
      if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
      n.queue=[];t=b.createElement(e);t.async=!0;t.src=v;
      s=b.getElementsByTagName(e)[0];s.parentNode.insertBefore(t,s)
    }(window,document,'script','https://connect.facebook.net/en_US/fbevents.js');

    window.fbq('init', pixelID);
    trackEvent('PageView', 'page_view');

    var isHome = /(^|\/)index\.html$/.test(window.location.pathname)
      || window.location.pathname === '/';
    if (isHome) {
      trackEvent('ViewContent', 'view_content');
      document.querySelectorAll('a[href^="https://apps.apple.com/br/app/limiar/"]').forEach(function (link) {
        link.addEventListener('click', function () {
          trackEvent('Lead', 'app_store_click');
          trackCustomEvent('AppStoreDownloadClick', 'app_store_download_click', {
            content_name: 'Limiar App Store download button',
            content_type: 'app'
          });
        });
      });
      trackVideoEngagement();
    }
  }

  function dismissBanner() {
    var banner = document.querySelector('.privacy-consent');
    if (banner) banner.remove();
  }

  function saveConsent(value) {
    localStorage.setItem(consentKey, value);
    dismissBanner();
    if (value === 'accepted') startMetaTracking();
  }

  function showBanner() {
    var banner = document.createElement('section');
    banner.className = 'privacy-consent';
    banner.setAttribute('role', 'dialog');
    banner.setAttribute('aria-label', 'Preferências de privacidade');
    banner.innerHTML = '<div><strong>Sua privacidade importa</strong><p>Com sua permissão, analisamos de forma segura como o site é utilizado. Isso nos ajuda a entender o que podemos melhorar.</p></div>'
      + '<div class="privacy-consent-actions"><button type="button" data-consent="declined">Agora não</button>'
      + '<button type="button" class="primary" data-consent="accepted">Continuar</button></div>';
    banner.querySelectorAll('[data-consent]').forEach(function (button) {
      button.addEventListener('click', function () {
        saveConsent(button.getAttribute('data-consent'));
      });
    });
    document.body.appendChild(banner);
  }

  document.addEventListener('DOMContentLoaded', function () {
    var consent = localStorage.getItem(consentKey);
    if (consent === 'accepted') {
      startMetaTracking();
    } else if (consent !== 'declined') {
      showBanner();
    }
  });
})();
