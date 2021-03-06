// Generated by CoffeeScript 1.4.0
(function() {
  var $, log, ls, setNotification,
    __slice = [].slice;

  $ = jQuery;

  ls = localStorage;

  setNotification = function() {
    var creator, description, feedKey, feedName, image, link, links, maxlength, title;
    try {
      title = ls.notificationTitle;
      link = ls.notificationLink;
      description = ls.notificationDescription;
      creator = ls.notificationCreator;
      image = ls.notificationImage;
      feedKey = ls.notificationFeedKey;
      feedName = ls.notificationFeedName;
      maxlength = 90;
      if (maxlength < description.length) {
        description = description.substring(0, maxlength) + '...';
      }
      $('#notification').click(function() {
        if (!DEBUG) {
          _gaq.push(['_trackEvent', 'notification', 'clickNotification', link]);
        }
        Browser.openTab(link);
        return window.close;
      });
      $('#notification').html('\
      <div class="item">\
        <div class="title">' + title + '</div>\
        <img src="' + image + '" />\
        <div class="textwrapper">\
          <div class="emphasized">- Av ' + creator + '</div>\
          <div class="description">' + description + '</div>\
        </div>\
      </div>\
      </a>');
      if (Affiliation.org[feedKey].getImage !== void 0) {
        Affiliation.org[feedKey].getImage(link, function(link, image) {
          return $('img').prop('src', image);
        });
      }
      if (Affiliation.org[feedKey].getImages !== void 0) {
        links = [];
        links.push(link);
        return Affiliation.org[feedKey].getImages(links, function(links, images) {
          return $('img').attr('src', images[0]);
        });
      }
    } catch (e) {
      return log('ERROR in desktop notification', e);
    }
  };

  log = function() {
    var object, _ref;
    object = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    if (!DEBUG) {
      return (_ref = Browser.getBackgroundProcess().console).log.apply(_ref, object);
    }
  };

  $(function() {
    $.ajaxSetup(AJAX_SETUP);
    setNotification();
    return setTimeout((function() {
      return window.close();
    }), 5500);
  });

}).call(this);
