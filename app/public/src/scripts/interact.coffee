#!
# * Draggabilly PACKAGED v1.1.1
# * Make that shiz draggable
# * http://draggabilly.desandro.com
# * MIT license
#

(->

  indexOfListener = (listeners, listener) ->
    i = listeners.length
    return i  if listeners[i].listener is listener  while i--
    -1
  alias = (name) ->
    aliasClosure = ->
      this[name].apply this, arguments

  class EventEmitter
    constructor: () ->
    getListeners: (evt) ->
      events = @_getEvents()
      response = undefined
      key = undefined
      if typeof evt is "object"
        response = {}
        for key of events
          response[key] = events[key]  if events.hasOwnProperty(key) and evt.test(key)
      else
        response = events[evt] or (events[evt] = [])
      response

    flattenListeners: (listeners) ->
      flatListeners = []
      i = 0
      while i < listeners.length
        flatListeners.push listeners[i].listener
        i += 1
      flatListeners

    getListenersAsObject: (evt) ->
      listeners = @getListeners(evt)
      response = undefined
      if listeners instanceof Array
        response = {}
        response[evt] = listeners
      response or listeners

    addListener: (evt, listener) ->
      listeners = @getListenersAsObject(evt)
      listenerIsWrapped = typeof listener is "object"
      key = undefined
      for key of listeners
        if listeners.hasOwnProperty(key) and indexOfListener(listeners[key], listener) is -1
          listeners[key].push (if listenerIsWrapped then listener else
            listener: listener
            once: false
          )
      this

    on: alias("addListener")

    addOnceListener: (evt, listener) ->
      @addListener evt,
        listener: listener
        once: true


    once: alias("addOnceListener")

    defineEvent: (evt) ->
      @getListeners evt
      this

    defineEvents: (evts) ->
      i = 0
      while i < evts.length
        @defineEvent evts[i]
        i += 1
      this

    removeListener: (evt, listener) ->
      listeners = @getListenersAsObject(evt)
      index = undefined
      key = undefined
      for key of listeners
        if listeners.hasOwnProperty(key)
          index = indexOfListener(listeners[key], listener)
          listeners[key].splice index, 1  if index isnt -1
      this

    off: alias("removeListener")

    addListeners: (evt, listeners) ->
      @manipulateListeners false, evt, listeners

    removeListeners: (evt, listeners) ->
      @manipulateListeners true, evt, listeners

    manipulateListeners: (remove, evt, listeners) ->
      single = if remove then @removeListener else @addListener
      multiple = if remove then @removeListeners else @addListeners
      if typeof evt is "object" and (evt not instanceof RegExp)
        for i of evt
          if evt.hasOwnProperty(i) and (value = evt[i])
            if typeof value is "function"
              single.call this, i, value
            else
              multiple.call this, i, value
      else
        i = listeners.length
        single.call this, evt, listeners[i]  while i--
      this

    removeEvent: (evt) ->
      type = typeof evt
      events = @_getEvents()
      if type is "string"
        delete events[evt]
      else if type is "object"
        for key of events
          delete events[key]  if events.hasOwnProperty(key) and evt.test(key)
      else
        delete @_events
      this

    emitEvent: (evt, args) ->
      listeners = @getListenersAsObject(evt)
      for key of listeners
        if listeners.hasOwnProperty(key)
          i = listeners[key].length
          while i--
            listener = listeners[key][i]
            response = listener.listener.apply(this, args or [])
            @removeListener evt, listener.listener  if response is @_getOnceReturnValue() or listener.once is true
      this

    trigger: alias("emitEvent")

    emit: (evt) ->
      args = Array::slice.call(arguments, 1)
      @emitEvent evt, args

    setOnceReturnValue: (value) ->
      @_onceReturnValue = value
      this

    _getOnceReturnValue: ->
      if @hasOwnProperty("_onceReturnValue")
        @_onceReturnValue
      else
        true

    _getEvents: ->
      @_events or (@_events = {})

  if typeof define is "function" and define.amd
    define "eventEmitter/EventEmitter", [], ->
      EventEmitter

  else if typeof module is "object" and module.exports
    module.exports = EventEmitter
  else
    @EventEmitter = EventEmitter
  return
).call this

#!
# * eventie v1.0.3
# * event binding helper
# *   eventie.bind( elem, 'click', myFn )
# *   eventie.unbind( elem, 'click', myFn )
#

((window) ->
  docElem = document.documentElement
  bind = ->

  if docElem.addEventListener
    bind = (obj, type, fn) ->
      obj.addEventListener type, fn, false
      return
  else if docElem.attachEvent
    bind = (obj, type, fn) ->
      obj[type + fn] = (if fn.handleEvent then ->
        event = window.event

        # add event.target
        event.target = event.target or event.srcElement
        fn.handleEvent.call fn, event
        return
       else ->
        event = window.event

        # add event.target
        event.target = event.target or event.srcElement
        fn.call obj, event
        return
      )
      obj.attachEvent "on" + type, obj[type + fn]
      return
  unbind = ->

  if docElem.removeEventListener
    unbind = (obj, type, fn) ->
      obj.removeEventListener type, fn, false
      return
  else if docElem.detachEvent
    unbind = (obj, type, fn) ->
      obj.detachEvent "on" + type, obj[type + fn]
      try
        delete obj[type + fn]
      catch err
        # can't delete window object properties
        obj[type + fn] = 'undefined'
      return
  eventie =
    bind: bind
    unbind: unbind


  # transport
  if typeof define is "function" and define.amd

    # AMD
    define "eventie/eventie", eventie
  else

    # browser global
    window.eventie = eventie
  return
) this

#!
# * getStyleProperty by kangax
# * http://perfectionkills.com/feature-testing-css-properties/
#

((window) ->
  getStyleProperty = (propName) ->
    return  unless propName

    # test standard property first
    return propName  if typeof docElemStyle[propName] is "string"

    # capitalize
    propName = propName.charAt(0).toUpperCase() + propName.slice(1)

    # test vendor specific properties
    prefixed = undefined
    i = 0
    len = prefixes.length

    while i < len
      prefixed = prefixes[i] + propName
      return prefixed  if typeof docElemStyle[prefixed] is "string"
      i++
    return
  prefixes = "Webkit Moz ms Ms O".split(" ")
  docElemStyle = document.documentElement.style

  # transport
  if typeof define is "function" and define.amd

    # AMD
    define "get-style-property/get-style-property", [], ->
      getStyleProperty

  else

    # browser global
    window.getStyleProperty = getStyleProperty
  return
) window

###*
getSize v1.1.4
measure size of elements
###

((window, undefined_) ->

  # -------------------------- helpers -------------------------- //

  # get a number from a string, not a percentage
  getStyleSize = (value) ->
    num = parseFloat(value)

    # not a percent like '100%', and a number
    isValid = value.indexOf("%") is -1 and not isNaN(num)
    isValid and num

  # -------------------------- measurements -------------------------- //
  getZeroSize = ->
    size =
      width: 0
      height: 0
      innerWidth: 0
      innerHeight: 0
      outerWidth: 0
      outerHeight: 0

    i = 0
    len = measurements.length

    while i < len
      measurement = measurements[i]
      size[measurement] = 0
      i++
    size
  defineGetSize = (getStyleProperty) ->

    # -------------------------- box sizing -------------------------- //

    ###*
    WebKit measures the outer-width on style.width on border-box elems
    IE & Firefox measures the inner-width
    ###

    # -------------------------- getSize -------------------------- //
    getSize = (elem) ->

      # use querySeletor if elem is string
      elem = document.querySelector(elem)  if typeof elem is "string"

      # do not proceed on non-objects
      return  if not elem or typeof elem isnt "object" or not elem.nodeType
      style = getStyle(elem)

      # if hidden, everything is 0
      return getZeroSize()  if style.display is "none"
      size = {}
      size.width = elem.offsetWidth
      size.height = elem.offsetHeight
      isBorderBox = size.isBorderBox = !!(boxSizingProp and style[boxSizingProp] and style[boxSizingProp] is "border-box")

      # get all measurements
      i = 0
      len = measurements.length

      while i < len
        measurement = measurements[i]
        value = style[measurement]
        num = parseFloat(value)

        # any 'auto', 'medium' value will be 0
        size[measurement] = (if not isNaN(num) then num else 0)
        i++
      paddingWidth = size.paddingLeft + size.paddingRight
      paddingHeight = size.paddingTop + size.paddingBottom
      marginWidth = size.marginLeft + size.marginRight
      marginHeight = size.marginTop + size.marginBottom
      borderWidth = size.borderLeftWidth + size.borderRightWidth
      borderHeight = size.borderTopWidth + size.borderBottomWidth
      isBorderBoxSizeOuter = isBorderBox and isBoxSizeOuter

      # overwrite width and height if we can get it from style
      styleWidth = getStyleSize(style.width)

      # add padding and border unless it's already including it
      size.width = styleWidth + ((if isBorderBoxSizeOuter then 0 else paddingWidth + borderWidth))  if styleWidth isnt false
      styleHeight = getStyleSize(style.height)

      # add padding and border unless it's already including it
      size.height = styleHeight + ((if isBorderBoxSizeOuter then 0 else paddingHeight + borderHeight))  if styleHeight isnt false
      size.innerWidth = size.width - (paddingWidth + borderWidth)
      size.innerHeight = size.height - (paddingHeight + borderHeight)
      size.outerWidth = size.width + marginWidth
      size.outerHeight = size.height + marginHeight
      size
    boxSizingProp = getStyleProperty("boxSizing")
    isBoxSizeOuter = undefined
    (->
      return  unless boxSizingProp
      div = document.createElement("div")
      div.style.width = "200px"
      div.style.padding = "1px 2px 3px 4px"
      div.style.borderStyle = "solid"
      div.style.borderWidth = "1px 2px 3px 4px"
      div.style[boxSizingProp] = "border-box"
      body = document.body or document.documentElement
      body.appendChild div
      style = getStyle(div)
      isBoxSizeOuter = getStyleSize(style.width) is 200
      body.removeChild div
      return
    )()
    getSize
  defView = document.defaultView
  getStyle = (if defView and defView.getComputedStyle then (elem) ->
    defView.getComputedStyle elem, null
   else (elem) ->
    elem.currentStyle
  )
  measurements = [
    "paddingLeft"
    "paddingRight"
    "paddingTop"
    "paddingBottom"
    "marginLeft"
    "marginRight"
    "marginTop"
    "marginBottom"
    "borderLeftWidth"
    "borderRightWidth"
    "borderTopWidth"
    "borderBottomWidth"
  ]

  # transport
  if typeof define is "function" and define.amd

    # AMD
    define "get-size/get-size", ["get-style-property/get-style-property"], defineGetSize
  else

    # browser global
    window.getSize = defineGetSize(window.getStyleProperty)
  return
) window

#!
# * Draggabilly v1.1.1
# * Make that shiz draggable
# * http://draggabilly.desandro.com
# * MIT license
#
((window) ->

  # vars

  # -------------------------- helpers -------------------------- //

  # extend objects
  extend = (a, b) ->
    for prop of b
      a[prop] = b[prop]
    a
  noop = ->

  draggabillyDefinition = (classie, EventEmitter, eventie, getStyleProperty, getSize) ->


    noDragStart = ->
      false

    setPointerPoint = (point, pointer) ->
      point.x = if pointer.pageX isnt 'undefined' then pointer.pageX else pointer.clientX
      point.y = if pointer.pageY isnt 'undefined' then pointer.pageY else pointer.clientY
      return

    applyGrid = (value, grid, method) ->
      method = method or "round"
      (if grid then Math[method](value / grid) * grid else value)
    transformProperty = getStyleProperty("transform")
    is3d = !!getStyleProperty("perspective")
    isIE8 = "attachEvent" of document.documentElement
    disableImgOndragstart = (if not isIE8 then noop else (handle) ->
      handle.ondragstart = noDragStart  if handle.nodeName is "IMG"
      images = handle.querySelectorAll("img")
      i = 0
      len = images.length

      while i < len
        img = images[i]
        img.ondragstart = noDragStart
        i++
    )
    # transform translate function
    translate = (if is3d then (x, y) ->
      "translate3d( " + x + "px, " + y + "px, 0)"
     else (x, y) ->
      "translate( " + x + "px, " + y + "px)"
    )

    postStartEvents =
      mousedown: []
      touchstart: []
      pointerdown: []
      MSPointerDown: []

    class Draggabilly extends EventEmitter
      constructor : (element, @options) ->
        # querySelector if string
        @element = if typeof element is "string" then document.querySelector(element) else element
        @options = extend({}, @options)
        extend @options, options
        @_create()

      _create: ->
        @position = {}
        @_getPosition()
        @startPoint =
          x: 0
          y: 0

        @dragPoint =
          x: 0
          y: 0

        @startPosition = extend({}, @position)
        style = getStyle(@element)
        @element.style.position = "relative"  if style.position isnt "relative" and style.position isnt "absolute"
        @enable()
        @setHandles()

      setHandles: ->
        @handles = if @options.handle then @element.querySelectorAll(@options.handle) else [@element]
        i = 0
        len = @handles.length

        while i < len
          handle = @handles[i]
          if window.navigator.pointerEnabled
            eventie.bind handle, "pointerdown", this
            handle.style.touchAction = "none"
          else if window.navigator.msPointerEnabled
            eventie.bind handle, "MSPointerDown", this
            handle.style.msTouchAction = "none"
          else
            eventie.bind handle, "mousedown", this
            eventie.bind handle, "touchstart", this
            disableImgOndragstart handle
          i++

      _getPosition: ->
        style = getStyle(@element)
        x = parseInt(style.left, 10)
        y = parseInt(style.top, 10)
        @position.x = (if isNaN(x) then 0 else x)
        @position.y = (if isNaN(y) then 0 else y)
        @_addTransformPosition style

      _addTransformPosition: (style) ->
        unless transformProperty
          return
        transform = style[transformProperty]
        if transform.indexOf("matrix") isnt 0
          return
        matrixValues = transform.split(",")
        xIndex = (if transform.indexOf("matrix3d") is 0 then 12 else 4)
        translateX = parseInt(matrixValues[xIndex], 10)
        translateY = parseInt(matrixValues[xIndex + 1], 10)
        @position.x += translateX
        @position.y += translateY

      handleEvent: (event) ->
        method = "on" + event.type
        this[method] event  if this[method]
        return

      getTouch: (touches) ->
        i = 0
        len = touches.length

        while i < len
          touch = touches[i]
          if touch.identifier is @pointerIdentifier
            return touch
          i++
        return

      onmousedown: (event) ->
        button = event.button
        if button and (button isnt 0 and button isnt 1)
          return
        @dragStart event, event
        return

      ontouchstart: (event) ->
        if @isDragging
          return
        @dragStart event, event.changedTouches[0]
        return

      onMSPointerDown: (event) ->
        if @isDragging
          return
        @dragStart event, event
        return
      onpointerdown: (event) ->
        if @isDragging
          return
        @dragStart event, event
        return

      dragStart: (event, pointer) ->
        unless @isEnabled
          return
        if event.preventDefault
          event.preventDefault()
        else
          event.returnValue = false
        @pointerIdentifier = if pointer.pointerId isnt 'undefined' then pointer.pointerId else pointer.identifier
        @_getPosition()
        @measureContainment()
        setPointerPoint @startPoint, pointer
        @startPosition.x = @position.x
        @startPosition.y = @position.y
        @setLeftTop()
        @dragPoint.x = 0
        @dragPoint.y = 0
        @_bindEvents
          events: postStartEvents[event.type]
          node: (if event.preventDefault then window else document)

        classie.add @element, "is-dragging"
        @isDragging = true
        @emitEvent "dragStart", []
        @animate()
        return

      _bindEvents: (args) ->
        i = 0
        len = args.events.length

        while i < len
          event = args.events[i]
          eventie.bind args.node, event, this
          i++
        @_boundEvents = args
        return

      _unbindEvents: ->
        args = @_boundEvents
        if not args or not args.events
          return
        i = 0
        len = args.events.length

        while i < len
          event = args.events[i]
          eventie.unbind args.node, event, this
          i++
        delete @_boundEvents

      measureContainment: ->
        containment = @options.containment
        unless containment
          return
        @size = getSize(@element)
        elemRect = @element.getBoundingClientRect()
        container = (if isElement(containment) then containment else (if typeof containment is "string" then document.querySelector(containment) else @element.parentNode))
        @containerSize = getSize(container)
        containerRect = container.getBoundingClientRect()
        @relativeStartPosition =
          x: elemRect.left - containerRect.left
          y: elemRect.top - containerRect.top

      onmousemove: (event) ->
        @dragMove event, event
        return

      onMSPointerMove: (event) ->
        @dragMove event, event  if event.pointerId is @pointerIdentifier
        return
      onpointermove: (event) ->
        @dragMove event, event  if event.pointerId is @pointerIdentifier
        return

      ontouchmove: (event) ->
        touch = @getTouch(event.changedTouches)
        @dragMove event, touch  if touch
        return

      dragMove: (event, pointer) ->
        setPointerPoint @dragPoint, pointer
        dragX = @dragPoint.x - @startPoint.x
        dragY = @dragPoint.y - @startPoint.y
        grid = @options.grid
        gridX = grid and grid[0]
        gridY = grid and grid[1]
        dragX = applyGrid(dragX, gridX)
        dragY = applyGrid(dragY, gridY)
        dragX = @containDrag("x", dragX, gridX)
        dragY = @containDrag("y", dragY, gridY)
        dragX = (if @options.axis is "y" then 0 else dragX)
        dragY = (if @options.axis is "x" then 0 else dragY)
        @position.x = @startPosition.x + dragX
        @position.y = @startPosition.y + dragY
        @dragPoint.x = dragX
        @dragPoint.y = dragY
        @emitEvent "dragMove", []
        return

      containDrag: (axis, drag, grid) ->
        unless @options.containment
          return drag
        measure = (if axis is "x" then "width" else "height")
        rel = @relativeStartPosition[axis]
        min = applyGrid(-rel, grid, "ceil")
        max = @containerSize[measure] - rel - @size[measure]
        max = applyGrid(max, grid, "floor")
        Math.min max, Math.max(min, drag)


    # ----- end event ----- //
      onmouseup: (event) ->
        @dragEnd event, event

      onMSPointerUp: (event) ->
        @dragEnd event, event  if event.pointerId is @pointerIdentifier
      onpointerup: (event) ->
        @dragEnd event, event  if event.pointerId is @pointerIdentifier

      ontouchend: (event) ->
        touch = @getTouch(event.changedTouches)
        @dragEnd event, touch  if touch

      dragEnd: (event, pointer) ->
        @isDragging = false
        delete @pointerIdentifier
        if transformProperty
          @element.style[transformProperty] = ""
          @setLeftTop()

        # remove events
        @_unbindEvents()
        classie.remove @element, "is-dragging"
        @emitEvent "dragEnd", []

      onMSPointerCancel: (event) ->
        @dragEnd event, event  if event.pointerId is @pointerIdentifier
      onpointercancel: (event) ->
        @dragEnd event, event  if event.pointerId is @pointerIdentifier

      ontouchcancel: (event) ->
        touch = @getTouch(event.changedTouches)
        @dragEnd event, touch

      animate: ->
        unless @isDragging
          return
        @positionDrag()
        _this = this
        requestAnimationFrame animateFrame = ->
          _this.animate()

      setLeftTop: ->
        @element.style.left = @position.x + "px"
        @element.style.top = @position.y + "px"

      positionDrag: if transformProperty then -> @element.style[transformProperty] = translate(@dragPoint.x, @dragPoint.y) else @setLeftTop
      enable: ->
        @isEnabled = true

      disable: ->
        @isEnabled = false
        if @isDragging
          @dragEnd()

    Draggabilaty
  document = window.document
  defView = document.defaultView
  getStyle = if defView and defView.getComputedStyle then (elem) -> defView.getComputedStyle elem, null else (elem) -> elem.currentStyle

  isElement = if (typeof HTMLElement is "object") then isElementDOM2 = (obj) -> obj instanceof HTMLElement else isElementQuirky = (obj) -> obj and typeof obj is "object" and obj.nodeType is 1 and typeof obj.nodeName is "string"
  lastTime = 0
  prefixes = "webkit moz ms o".split(" ")
  requestAnimationFrame = window.requestAnimationFrame
  cancelAnimationFrame = window.cancelAnimationFrame
  prefix = undefined
  i = 0

  while i < prefixes.length
    break  if requestAnimationFrame and cancelAnimationFrame
    prefix = prefixes[i]
    requestAnimationFrame = requestAnimationFrame or window[prefix + "RequestAnimationFrame"]
    cancelAnimationFrame = cancelAnimationFrame or window[prefix + "CancelAnimationFrame"] or window[prefix + "CancelRequestAnimationFrame"]
    i++
  if not requestAnimationFrame or not cancelAnimationFrame
    requestAnimationFrame = (callback) ->
      currTime = new Date().getTime()
      timeToCall = Math.max(0, 16 - (currTime - lastTime))
      id = window.setTimeout(->
        callback currTime + timeToCall
        return
      , timeToCall)
      lastTime = currTime + timeToCall
      id

    cancelAnimationFrame = (id) ->
      window.clearTimeout id
      return
  # end definition

  # -------------------------- transport -------------------------- //
  if typeof define is "function" and define.amd

    # AMD
    define [

    ], draggabillyDefinition
  else if typeof exports is "object"

    # CommonJS
    module.exports = draggabillyDefinition(require("desandro-classie"), require("wolfy87-eventemitter"), require("eventie"), require("desandro-get-style-property"), require("get-size"))
  else

    # browser global
    window.Draggabilly = draggabillyDefinition(window.classie, window.EventEmitter, window.eventie, window.getStyleProperty, window.getSize)
  return
) window
