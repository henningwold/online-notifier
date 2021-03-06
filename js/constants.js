var DEBUG = 0;

// AJAX setup
var AJAX_SETUP = {
	timeout: 9000,
	cache: false,
}

// Loops & intervals
var BACKGROUND_LOOP = 30000; // 30s
var BACKGROUND_LOOP_OFFLINE = 3000; // 3s, respond quickly when we get back online
var PAGE_LOOP = 10000; // 10s

// Update stuff at every X intervals
var UPDATE_OFFICE_INTERVAL = 1; // recommended: 1
var UPDATE_SERVANT_INTERVAL = 20; // recommended: 20
var UPDATE_MEETINGS_INTERVAL = 20; // recommended: 20
var UPDATE_COFFEE_INTERVAL = 1; // recommended: 1
var UPDATE_HOURS_INTERVAL = 60; // recommended: 60
var UPDATE_CANTINAS_INTERVAL = 60; // recommended: 60
var UPDATE_BUS_INTERVAL = 2; // recommended: 1
var UPDATE_NEWS_INTERVAL = 20; // recommended: 20

// OS detection
var OPERATING_SYSTEM = "Unknown";
if (navigator.appVersion.indexOf("Win")!==-1) OPERATING_SYSTEM="Windows";
else if (navigator.appVersion.indexOf("Linux")!==-1) OPERATING_SYSTEM="Linux";
else if (navigator.appVersion.indexOf("X11")!==-1) OPERATING_SYSTEM="UNIX";
else if (navigator.appVersion.indexOf("Mac")!==-1) {
	OPERATING_SYSTEM = "Old Mac";
	if (navigator.appVersion.indexOf("10_7")!==-1||navigator.appVersion.indexOf("10_8")!==-1) {
		OPERATING_SYSTEM = "Mac";
	}
}
else {
	console.log("ERROR: Potentially unsupported operating system");
}

// Browser detection
var BROWSER = "Unknown";
if (typeof chrome != "undefined")
	BROWSER = "Chrome";
else if (typeof opera != "undefined")
	BROWSER = "Opera";
else {
	console.log("ERROR: Potentially unsupported browser");
}

// Production detection
if (BROWSER == "Chrome") {
	if (typeof chrome.i18n != "undefined") {
		if (chrome.i18n.getMessage('@@extension_id') === "hfgffimlnajpbenfpaofmmffcdmgkllf") {
			DEBUG = 0;
		}
	}
}
else if (BROWSER == "Opera") {
	// TODO: Implement this
}
