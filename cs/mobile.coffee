# Notify Coffeescript that jQuery is here
$ = jQuery
ls = localStorage
iteration = 0

newsLimit = 4 # The best amount of news for Mobile, IMO

window.IS_MOBILE = 1 # An easy hack saving a lot of work, ajaxer.js checks this to determine URL path and HTTP method

mainLoop = ->
  if DEBUG then console.log "\n#" + iteration

  updateOffice() if iteration % UPDATE_OFFICE_INTERVAL is 0 and ls.showOffice is 'true'
  updateServant() if iteration % UPDATE_SERVANT_INTERVAL is 0 and ls.showOffice is 'true'
  updateMeetings() if iteration % UPDATE_MEETINGS_INTERVAL is 0 and ls.showOffice is 'true'
  updateCoffee() if iteration % UPDATE_COFFEE_INTERVAL is 0 and ls.showOffice is 'true'
  updateCantinas() if iteration % UPDATE_CANTINAS_INTERVAL is 0 and ls.showCantina is 'true'
  updateHours() if iteration % UPDATE_HOURS_INTERVAL is 0 and ls.showCantina is 'true'
  updateBus() if iteration % UPDATE_BUS_INTERVAL is 0 and ls.showBus is 'true'
  updateNews() if iteration % UPDATE_NEWS_INTERVAL is 0
  
  # No reason to count to infinity
  if 10000 < iteration then iteration = 0 else iteration++
  
  setTimeout ( ->
    mainLoop()
  ), PAGE_LOOP

updateOffice = ->
  if DEBUG then console.log 'updateOffice'
  Office.get (status, title, message) ->
    if ls.currentStatus isnt status or ls.currentStatusMessage isnt message
      $('#office #status').html title
      $('#office #status').attr 'class', status
      $('#office #subtext').html message
      ls.currentStatus = status
      ls.currentStatusMessage = message

updateServant = ->
  if DEBUG then console.log 'updateServant'
  Servant.get (servant) ->
    $('#todays #schedule #servant').html '- '+servant

updateMeetings = ->
  if DEBUG then console.log 'updateMeetings'
  Meetings.get (meetings) ->
    meetings = meetings.replace /\n/g, '<br />'
    $('#todays #schedule #meetings').html meetings

updateCoffee = ->
  if DEBUG then console.log 'updateCoffee'
  Coffee.get true, (pots, age) ->
    $('#todays #coffee #pots').html '- '+pots
    $('#todays #coffee #age').html age

updateCantinas = ->
  if DEBUG then console.log 'updateCantinas'
  Cantina.get ls.left_cantina, (menu) ->
    $('#cantinas #left .title').html ls.left_cantina
    $('#cantinas #left #dinnerbox').html listDinners(menu)
    clickDinnerLink '#cantinas #left #dinnerbox li'
  Cantina.get ls.right_cantina, (menu) ->
    $('#cantinas #right .title').html ls.right_cantina
    $('#cantinas #right #dinnerbox').html listDinners(menu)
    clickDinnerLink '#cantinas #right #dinnerbox li'

listDinners = (menu) ->
  dinnerlist = ''
  # If menu is just a message, not a menu: (yes, a bit hackish, but reduces complexity in the cantina script)
  if typeof menu is 'string'
    ls.noDinnerInfo = 'true'
    dinnerlist += '<li>' + menu + '</li>'
  else
    ls.noDinnerInfo = 'false'
    for dinner in menu
      if dinner.price != null
        if not isNaN dinner.price
          dinner.price = dinner.price + ',-'
        else
          dinner.price = dinner.price + ' -'
        dinnerlist += '<li id="' + dinner.index + '">' + dinner.price + ' ' + dinner.text + '</li>'
      else
        dinnerlist += '<li class="message" id="' + dinner.index + '">"' + dinner.text + '"</li>'
  return dinnerlist

clickDinnerLink = (cssSelector) ->
  $(cssSelector).click ->
    Browser.openTab Cantina.url
    window.close()

updateHours = ->
  if DEBUG then console.log 'updateHours'
  Hours.get ls.left_cantina, (hours) ->
    $('#cantinas #left .hours').html hours
  Hours.get ls.right_cantina, (hours) ->
    $('#cantinas #right .hours').html hours

updateBus = ->
  if DEBUG then console.log 'updateBus'
  if !navigator.onLine
    $('#bus #firstBus .name').html ls.firstBusName
    $('#bus #secondBus .name').html ls.secondBusName
    $('#bus #firstBus .first .line').html '<div class="error">Frakoblet fra api.visuweb.no</div>'
    $('#bus #secondBus .first .line').html '<div class="error">Frakoblet fra api.visuweb.no</div>'
  else
    createBusDataRequest('firstBus', '#firstBus')
    createBusDataRequest('secondBus', '#secondBus')

createBusDataRequest = (bus, cssIdentificator) ->
  activeLines = ls[bus+'ActiveLines'] # array of lines stringified with JSON (hopefully)
  activeLines = JSON.parse activeLines
  # Get bus data, if activeLines is an empty array we'll get all lines, no problemo :D
  Bus.get ls[bus], activeLines, (lines) ->
    insertBusInfo lines, ls[bus+'Name'], cssIdentificator

insertBusInfo = (lines, stopName, cssIdentificator) ->
  busStop = '#bus '+cssIdentificator
  spans = ['first', 'second', 'third']

  $(busStop+' .name').html stopName

  # Reset spans
  for i of spans
    $(busStop+' .'+spans[i]+' .line').html ''
    $(busStop+' .'+spans[i]+' .time').html ''
  
  if typeof lines is 'string'
    # Lines is an error message
    $(busStop+' .first .line').html '<div class="error">'+lines+'</div>'
  else
    # No lines to display, busstop is sleeping
    if lines['departures'].length is 0
      $(busStop+' .first .line').html '<div class="error">....zzzZZZzzz....</div>'
    else
      # Display line for line with according times
      for i of spans
        # Add the current line
        $(busStop+' .'+spans[i]+' .line').append lines['destination'][i]
        $(busStop+' .'+spans[i]+' .time').append lines['departures'][i]

# This function is an edited, combined version of the similar functions from
# both background.coffee (fetches news) and popup.coffee (displays news)
updateNews = ->
  if DEBUG then console.log 'updateNews'
  # Get affiliation object
  affiliationKey1 = ls['affiliationKey1']
  affiliation = Affiliation.org[affiliationKey1]
  if affiliation is undefined
    if DEBUG then console.log 'ERROR: chosen affiliation', affiliationKey1, 'is not known'
  else
    # Get more news than needed to check for old news that have been updated
    getNewsAmount = 10
    News.get affiliation, getNewsAmount, (items) ->
      if typeof items is 'string'
        # Error message, log it maybe
        if DEBUG then console.log 'ERROR:', items
        name = Affiliation.org[affiliationKey1].name
        $('#news').html '<div class="post"><div class="title">Nyheter</div><div class="item">Frakoblet fra '+name+'</div></div>'
      else
        ls.feedItems = JSON.stringify items
        News.refreshNewsIdList items
        displayItems items

displayItems = (items) ->
  # Empty the newsbox
  $('#news').html ''
  # Get feedname
  feedKey = items[0].feedKey

  # Get list of last viewed items and check for news that are just
  # updated rather than being actual news
  newsList = JSON.parse ls.newsList
  viewedList = JSON.parse ls.viewedNewsList
  updatedList = findUpdatedPosts newsList, viewedList

  # Build list of last viewed for the next time the user views the news
  viewedList = []

  # Add feed items to popup
  $.each items, (index, item) ->
    
    if index < newsLimit
      viewedList.push item.link
      
      htmlItem = '<div class="post"><div class="title">'
      if index < ls.unreadCount
        if item.link in updatedList.indexOf
          htmlItem += '<span class="unread">UPDATED <b>::</b> </span>'
        else
          htmlItem += '<span class="unread">NEW <b>::</b> </span>'

      # EXPLANATION NEEDED:
      # .item[data] contains the link
      # .item[name] contains the alternative link, if one exists, otherwise null
      date = altLink = ''
      if item.date isnt null
        date = ' den ' + item.date
      if item.altLink isnt null
        altLink = ' name="' + item.altLink + '"'
      htmlItem += item.title + '
        </div>
          <div class="item" data="' + item.link + '"' + altLink + '>
            <img src="' + item.image + '" width="107" />
            <div class="textwrapper">
              <div class="emphasized">- Skrevet av ' + item.creator + date + '</div>
              ' + item.description + '
            </div>
          </div>
        </div>'
      $('#news').append htmlItem
  
  # Store list of last viewed items
  ls.viewedNewsList = JSON.stringify viewedList

  # All items are now considered read
  Browser.setBadgeText ''
  ls.unreadCount = 0

  # Make news items open extension website while closing popup
  $('.item').click ->
    # The link is embedded as the ID of the element, we don't want to use
    # <a> anchors because it creates an ugly box marking the focus element.
    # Note that altLinks are embedded in the name-property of the element,
    # - if preferred by the organization, we should use that instead.
    altLink = $(this).attr 'name'
    useAltLink = Affiliation.org[ls.affiliationKey1].useAltLink
    if altLink isnt undefined and useAltLink is true
      Browser.openTab $(this).attr 'name'
    else
      Browser.openTab $(this).attr 'data'
    window.close()

  # If organization prefers alternative links, use them
  if Affiliation.org[feedKey].useAltLink
    altLink = $('.item[data="'+link+'"]').attr 'name'
    if altLink isnt 'null'
      $('.item[data="'+link+'"]').attr 'data', altLink

  # If the organization has it's own getImage function, use it
  if Affiliation.org[feedKey].getImage isnt undefined
    for index, link of viewedList
      Affiliation.org[feedKey].getImage link, (link, image) ->
        # It's important to get the link from the callback, not the above code
        # in order to have the right link at the right time, async ftw.
        $('.item[data="'+link+'"] img').attr 'src', image

  # If the organization has it's own getImages function, use it
  if Affiliation.org[feedKey].getImages isnt undefined
    Affiliation.org[feedKey].getImages viewedList, (links, images) ->
      for index of links
        $('.item[data="'+links[index]+'"] img').attr 'src', images[index]

# Checks the most recent list of news against the most recently viewed list of news
findUpdatedPosts = (newsList, viewedList) ->
  updatedList = []
  # Compare lists, keep your mind straight here:
  # Updated news are:
  # - saved in the newsList before the first identical item in the viewedList
  # - saved in the viewedList after the first identical item in the newsList
  for i of newsList
    break if newsList[i] is viewedList[0]
    for j of viewedList
      continue if j is 0
      if newsList[i] is viewedList[j]
        updatedList.push newsList[i]
  return updatedList

busLoading = (cssIdentificator) ->
  if DEBUG then console.log 'busLoading:', cssIdentificator
  cssSelector = '#' + cssIdentificator
  loading = if cssIdentificator is 'first_bus' then 'loading_left' else 'loading_right'
  $(cssSelector + ' .name').html '<img class="'+loading+'" src="mimg/loading.gif" />'
  spans = ['first', 'second', 'third', 'fourth']
  for span in spans
    $(cssSelector + ' .' + span + ' .line').html ''
    $(cssSelector + ' .' + span + ' .time').html ''

# Document ready, go!
$ ->
  # Setting the timeout for all AJAX and JSON requests
  $.ajaxSetup AJAX_SETUP
  
  # Clear previous thoughts
  if DEBUG then ls.clear()
  ls.removeItem 'currentStatus'
  ls.removeItem 'currentStatusMessage'
  
  # Set default choices if undefined, in the same order as on the options page

  if ls.showAffiliation1 is undefined
    ls.showAffiliation1 = 'true'
  if ls.affiliationKey1 is undefined
    ls.affiliationKey1 = 'online'
  if ls.affiliationPalette is undefined
    ls.affiliationPalette = 'online'

  # Lists of links (IDs) for news items
  if ls.newsList is undefined
    ls.newsList = JSON.stringify []
  if ls.viewedNewsList is undefined
    ls.viewedNewsList = JSON.stringify []

  if ls.showBus is undefined
    ls.showBus = 'true'

  # If any of these properties are undefined we'll reset all of them
  firstBusProps = [
    ls.firstBus,
    ls.firstBusName,
    ls.firstBusDirection,
    ls.firstBusActiveLines,
    ls.firstBusInactiveLines,
  ]
  secondBusProps = [
    ls.secondBus,
    ls.secondBusName,
    ls.secondBusDirection,
    ls.secondBusActiveLines,
    ls.secondBusInactiveLines,
  ]
  firstBusOk = true
  secondBusOk = true
  firstBusOk = false for prop in firstBusProps when prop is undefined
  secondBusOk = false for prop in secondBusProps when prop is undefined
  if !firstBusOk
    ls.firstBus = 16011333
    ls.firstBusName = 'Gløshaugen Nord'
    ls.firstBusDirection = 'til byen'
    ls.firstBusActiveLines = JSON.stringify [5, 22]
    ls.firstBusInactiveLines = JSON.stringify [169]
  if !secondBusOk
    ls.secondBus = 16010333
    ls.secondBusName = 'Gløshaugen Nord'
    ls.secondBusDirection = 'fra byen'
    ls.secondBusActiveLines = JSON.stringify [5, 22]
    ls.secondBusInactiveLines = JSON.stringify [169]
  
  if ls.showOffice is undefined
    ls.showOffice = 'true'
  
  if ls.showCantina is undefined
    ls.showCantina = 'true'
  if ls.left_cantina is undefined
    ls.left_cantina = 'hangaren'
  if ls.right_cantina is undefined
    ls.right_cantina = 'realfag'
  
  # Set default vars for main loop
  ls.everConnected = ls.wasConnected = 'false'

  # ABOVE FROM BACKGROUND.COFFEE

  # Show loading gifs
  busLoading 'first_bus'
  busLoading 'second_bus'

  # Adding the background image, from localstorage or from file
  if ls.background_image isnt undefined
    # Base64-encoded image made with http://webcodertools.com/imagetobase64converter/Create
    $('body').attr 'style', 'background-attachment:fixed;background-image:' + ls.background_image
  else
    # No background image, fetching for the first time
    $('head').append '<script src="mimg/background_image.js"></script>'
    $('body').attr 'style', 'background-attachment:fixed;background-image:' + BACKGROUND_IMAGE
    ls.background_image = BACKGROUND_IMAGE
  
  # Show the standard palette or special palette the user has chosen
  palette = ls.affiliationPalette
  if DEBUG then console.log 'Applying chosen palette', palette
  $('#palette').attr 'href', Palettes.get palette

  # Enter main loop, keeping everything up-to-date
  mainLoop()
