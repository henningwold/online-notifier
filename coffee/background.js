// Generated by CoffeeScript 1.3.3
(function() {
  var $, iteration, ls, mainLoop, updateNews, updateOffice;

  $ = jQuery;

  ls = localStorage;

  iteration = 0;

  mainLoop = function() {
    var loopTimeout;
    if (DEBUG) {
      console.log("\n#" + iteration);
    }
    if (ls.useInfoscreen !== 'true') {
      if (iteration % UPDATE_OFFICE_INTERVAL === 0) {
        updateOffice();
      }
      if (iteration % UPDATE_NEWS_INTERVAL === 0 && navigator.onLine) {
        updateNews();
      }
    }
    if (10000 < iteration) {
      iteration = 0;
    } else {
      iteration++;
    }
    if (DEBUG || !navigator.onLine || ls.currentStatus === 'error') {
      loopTimeout = BACKGROUND_LOOP_QUICK;
    } else {
      loopTimeout = BACKGROUND_LOOP;
    }
    return setTimeout((function() {
      return mainLoop();
    }), loopTimeout);
  };

  updateOffice = function() {
    if (DEBUG) {
      console.log('updateOffice');
    }
    return Office.get(function(status, title, message) {
      if (ls.currentStatus !== status || ls.currentStatusMessage !== message) {
        chrome.browserAction.setIcon({
          path: 'img/icon-' + status + '.png'
        });
        ls.currentStatus = status;
        return Office.getTodaysEvents(function(meetingPlan) {
          var today;
          meetingPlan = $.trim(meetingPlan);
          today = '### Nå\n' + title + ": " + message + "\n\n### Resten av dagen\n" + meetingPlan;
          chrome.browserAction.setTitle({
            title: today
          });
          return ls.currentStatusMessage = message;
        });
      }
    });
  };

  updateNews = function() {
    if (DEBUG) {
      console.log('updateNews');
    }
    return fetchFeed(function() {
      var response;
      response = ls.lastResponseData;
      if (response !== null) {
        return unreadCount(response);
      } else {
        return console.log('ERROR: response was null');
      }
    });
  };

  $(function() {
    $.ajaxSetup({
      timeout: 6000
    });
    if (DEBUG) {
      ls.clear();
    }
    ls.removeItem('currentStatus');
    ls.removeItem('currentStatusMessage');
    if (ls.everConnected === void 0) {
      if (ls.first_bus === void 0) {
        ls.showBus = 'true';
        ls.first_bus = 16011333;
        ls.first_bus_name = 'Gløshaugen Nord';
        ls.first_bus_direction = 'til byen';
        ls.first_bus_active_lines = JSON.stringify([5, 22]);
        ls.first_bus_inactive_lines = JSON.stringify([169]);
        ls.second_bus = 16010333;
        ls.second_bus_name = 'Gløshaugen Nord';
        ls.second_bus_direction = 'fra byen';
        ls.second_bus_active_lines = JSON.stringify([5, 22]);
        ls.second_bus_inactive_lines = JSON.stringify([169]);
      }
      if (ls.showOffice === void 0) {
        ls.showOffice = 'true';
      }
      if (ls.showCantina === void 0) {
        ls.showCantina = 'true';
      }
      if (ls.showNotifications === void 0) {
        ls.showNotifications = 'true';
      }
      if (ls.openChatter === void 0) {
        ls.openChatter = 'false';
      }
      if (ls.useInfoscreen === void 0) {
        ls.useInfoscreen = 'false';
      }
      if (!DEBUG) {
        chrome.tabs.create({
          url: chrome.extension.getURL("options.html"),
          selected: true
        });
      }
    }
    if (ls.useInfoscreen === 'true') {
      chrome.tabs.create({
        url: chrome.extension.getURL("infoscreen.html"),
        selected: true
      });
    }
    if (ls.openChatter === 'true') {
      chrome.tabs.create({
        url: 'http://webchat.freenode.net/?channels=online',
        selected: false
      });
    }
    ls.everConnected = ls.wasConnected = 'false';
    setInterval((function() {
      return document.location.reload();
    }), 86400000);
    return mainLoop();
  });

}).call(this);
