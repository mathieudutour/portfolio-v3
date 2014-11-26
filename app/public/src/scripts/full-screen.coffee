do (window, document) ->
  THRESHOLD_DISTANCE = 75
  THRESHOLD_TIME = 400

  class FullScreen
    constructor: (@element, @background) ->
      @classNameExpanded = 'expanded'
      @classNameAnimating = 'animating'
      @activeTouch = null
      @activeTouchX = null
      @activeTouchY = null
      @activeTouchStart = null

      # DOM Context
      @circle = @element.querySelector('.circle')
      @close = @element.querySelector('.close')
      @content = @element.querySelector('.content')

      # States
      @expanded = false
      @animating = false
      # Callbacks
      @onExpand = @onExpand.bind(this)
      @onClose = @onClose.bind(this)

      # Initialise
      @initialise()

    initialise: () ->
      @circle.addEventListener('click', @onExpand)
      @circle.addEventListener('touchstart', @onTouch)
      @circle.addEventListener('touchend', @onTouch)
      @close.addEventListener('click', @onClose)
      @close.addEventListener("touchend", @onClose);

    getCoordinatesFromEvent: (event) ->
      find = (arr, f) ->
        for e in arr when f e
          return e
        return
      self = this
      touch= find event.touches, (touch) -> touch.identifier is self.activeTouch
      return {clientX: touch.clientX, clientY: touch.clientY}

    onTouch: (event) ->
      if !@activeTouch
        @activeTouch = event.changedTouches[0].identifier
        {clientX, clientY} = @getCoordinatesFromEvent(event)
        @activeTouchX = clientX
        @activeTouchY = clientX
        @activeTouchStart = event.timeStamp
      else
        {clientX, clientY} = @getCoordinatesFromEvent(event)
        # Check if it's not a drag
        if Math.abs(@activeTouchX - clientX) < THRESHOLD_DISTANCE and Math.abs(@activeTouchY - clientY) < THRESHOLD_DISTANCE and event.timeStamp - @activeTouchStart < THRESHOLD_TIME
          onExpand(event)
        @activeTouch = null
        @activeTouchX = null
        @activeTouchY = null
        @activeTouchStart = null


    onExpand: (event) ->
      event.preventDefault()
      if !@expanded and !@animating
        @background.stop()
        @expanded = true
        @animating = true
        classie.addClass(@element, @classNameExpanded)
        classie.addClass(@element, @classNameAnimating)
        self = this
        setTimeout ( ->
          self.animating = false
          classie.removeClass(self.element, self.classNameAnimating)
        ), 300

    onClose: (event) ->
      event.preventDefault()
      if @expanded and !@animating
        @animating = true
        classie.removeClass(@element, @classNameExpanded)
        classie.addClass(@element, @classNameAnimating)
        @expanded = false
        self = this
        setTimeout ( ->
          self.background.start()
          self.animating = false
          classie.removeClass(self.element, self.classNameAnimating)
        ), 300

  window.FullScreen = FullScreen
