var loaded = false;

function closeLike() {
  $('#dialog-wrap').fadeOut('slow');
  return false;
}

function openLike() {

  if (!loaded) {
    loaded = true;

    (function(d, s, id) {
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) return;
      js = d.createElement(s); js.id = id;
      js.src = "//connect.facebook.net/en_US/all.js#xfbml=1";
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));

    var waitForFB;
    waitForFB = function() {
      var $dialog = $('#dialog-wrap');
      var $iframe = $dialog.find('iframe');
      if ($iframe.contents().length != 1) {
        setTimeout(waitForFB, 100);
      } else {
        $dialog.find('#dialog-content').removeClass('loading');
      }
    }

    waitForFB();
  }

  var $window = $(window);
  var $dialog = $('#dialog-wrap');

  var top = Math.round(($window.height() - $dialog.outerHeight()) / 2) + $window.scrollTop();
  if (top < 0) {
    top = 0;
  }

  var left = Math.round(($window.width() - $dialog.outerWidth()) / 2) + $window.scrollLeft();
  if (left < 0) {
    left = 0;
  }

  $dialog.css({ top: top, left: left });

  $dialog.fadeIn('slow');

  return false;
}

$(function() {
  if (window.location.hash === '#like') {
    openLike();
  }
});
