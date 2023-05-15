$(document).on('turbolinks:load', function() {
  var matomoExternalScript = document.createElement('script');
  matomoExternalScript.src = 'https://matomo.land-lieben.de/index.php?module=CoreAdminHome&action=optOutJS&divId=matomo-opt-out&language=auto&showIntro=1';
  document.head.appendChild(matomoExternalScript);
});
