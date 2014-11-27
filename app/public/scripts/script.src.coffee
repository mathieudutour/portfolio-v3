do (window, document) ->
  class Age
    constructor: (@element, birthday, options) ->
      # DOM Context
      @number_of_millisecond_in_a_year = 31556926000
      @birthday = new Date(birthday).getTime()
      @age = 0
      @fraction = 0
      @precision = 9
      # States

      # Callbacks

      # Initialise
      @initialise()

    initialise: () ->
      @initDisplay()
      self = this
      setInterval ( ->
        self.updateDisplay()
      ), 10

    calculateAge: () ->
      @age = Math.floor((new Date().getTime() - @birthday) / @number_of_millisecond_in_a_year)
      @birthday += @age * @number_of_millisecond_in_a_year

    calculateFraction: () ->
      @fraction = (((new Date().getTime() - @birthday) / @number_of_millisecond_in_a_year).toFixed(@precision) * 1000000000).toString().substring(0,@precision)

    initDisplay: () ->
      @ageDisplay = document.createElement("span")
      @fractionDisplay = document.createElement("span")
      @element.insertBefore @ageDisplay, null
      @element.insertBefore @fractionDisplay, null

      @calculateAge()
      @ageDisplay.innerHTML = @age

      @updateDisplay()

    updateDisplay: () ->
      @calculateFraction()
      @fractionDisplay.innerHTML = '.' + @pad()

    pad: () ->
      if @fraction.length < @precision
        @fraction = "0" + @fraction
        @pad()
      else
        @fraction

  window.Age = Age

###
 * CirclesUI.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Creates a Circles UI
###
do (window, document) ->

  # class helper functions from classie https://github.com/desandro/classie
  classReg = ( className ) ->
    return new RegExp("(^|\\s+)" + className + "(\\s+|$)")

  if 'classList' in document.documentElement
    hasClass = ( elem, c ) ->
      elem.classList.contains( c )
    addClass = ( elem, c ) ->
      elem.classList.add( c )
    removeClass = ( elem, c ) ->
      elem.classList.remove( c )
  else
    hasClass = ( elem, c ) ->
      classReg( c ).test( elem.className )
    addClass = ( elem, c ) ->
      if !hasClass( elem, c )
        elem.className = elem.className + ' ' + c
    removeClass = ( elem, c ) ->
      elem.className = elem.className.replace( classReg( c ), ' ' )

  classie =
    hasClass: hasClass
    addClass: addClass
    removeClass: removeClass
  #Expose Classie
  window.classie = classie

  # Constants
  NAME = 'CirclesUI'
  DEFAULTS =
    wrap: true
    relativeInput: false
    clipRelativeInput: false
    invertX: false
    invertY: false
    limitX: false
    limitY: false
    scalarX: 1.0
    scalarY: 1.0
    frictionX: 0.1
    frictionY: 0.1
    precision: 1
    classBig: "circle-big"
    classVisible: "circle-visible"

  class CirclesUI
    constructor : (@element, options) ->

      # DOM Context
      @circles = element.getElementsByClassName('circle-container')

      if @circles.length < 24
        throw new Error("Not enought circle to display a proper UI")
      else
        # Data Extraction
        data =
          wrap: @data(@element, 'wrap')
          relativeInput: @data(@element, 'relative-input')
          clipRelativeInput: @data(@element, 'clipe-relative-input')
          invertX: @data(@element, 'invert-x')
          invertY: @data(@element, 'invert-y')
          limitX: @data(@element, 'limit-x')
          limitY: @data(@element, 'limit-y')
          scalarX: @data(@element, 'scalar-x')
          scalarY: @data(@element, 'scalar-y')
          frictionX: @data(@element, 'friction-x')
          frictionY: @data(@element, 'friction-y')
          precision: @data(@element, 'precision')
          classBig: @data(@element, 'class-big')
          classVisible: @data(@element, 'class-visible')

        # Delete Null Data Values
        for key of data
          delete data[key] if data[key] is null

        # Compose Settings Object
        @extend(this, DEFAULTS, options, data);

        # States
        @started = false
        @dragging = false
        @raf = null
        @moved = false

        # Element Bounds
        @bounds = null
        @ex = 0
        @ey = 0
        @ew = 0
        @eh = 0

        # Orientation of the element
        @portrait = null

        # Windows size
        @ww = 0
        @wh = 0

        # Circles size ( actually, size of the square container )
        @circleDiameter = 0

        # Matrix of the circles
        @numberOfCol = 0
        @numberOfRow = 0

        # Positions of the circles
          # Bounds of the circles coordinates
        @miny = 0
        @maxy = 0
        @minx = 0
        @maxx = 0
          # Coordinates of the center circle
        @cy = 0
        @cx = 0
          # Ranges of the coordinates
        @ry = @maxy - @miny
        @rx = @maxx - @minx

        # First Input
        @fix = 0
        @fiy = 0

        # Input
        @ix = 0
        @iy = 0

        # Motion
        @mx = 0
        @my = 0

        # Velocity
        @vx = 0
        @vy = 0

        # Vendor Prefixe from http://davidwalsh.name/vendor-prefix
        @vendorPrefix = (->
          styles = window.getComputedStyle(document.documentElement, "")
          pre = (Array::slice.call(styles).join("").match(/-(moz|webkit|ms)-/) or (styles.OLink is "" and ["", "o"]))[1]
          dom = ("WebKit|Moz|MS|O").match(new RegExp("(" + pre + ")", "i"))[1]
          dom: dom
          lowercase: pre
          css: "-" + pre + "-"
          js: pre[0].toUpperCase() + pre.substr(1)
        )()

        # Support for 2D and 3D transform
        [@transform2DSupport, @transform3DSupport] = ( (transform) ->
          el2d = document.createElement("p")
          el3d = document.createElement("p")
          has2d = undefined
          has3d = undefined
          # Add it to the body to get the computed style.
          document.body.insertBefore el2d, null
          if typeof el2d.style[transform] isnt 'undefined'
            document.body.insertBefore el3d, null
            el2d.style[transform] = "translate(1px,1px)"
            has2d = window.getComputedStyle(el2d).getPropertyValue(transform)
            el3d.style[transform] = "translate3d(1px,1px,1px)"
            has3d = window.getComputedStyle(el3d).getPropertyValue(transform)
            document.body.removeChild el3d
          document.body.removeChild el2d
          [typeof has2d isnt 'undefined' and has2d.length > 0 and has2d isnt "none", typeof has3d isnt 'undefined' and has3d.length > 0 and has3d isnt "none"]
        )(@vendorPrefix.css + 'transform')

        @setPositionAndScale = if @transform3DSupport then (element, x, y, s, updateS) ->
          x = x.toFixed(@precision) + 'px'
          y = y.toFixed(@precision) + 'px'
          @css(element, @vendorPrefix.js + 'Transform', 'translate3d('+x+','+y+',0)')
          if updateS
            circle = element.getElementsByClassName('circle')
            @css(circle[0], @vendorPrefix.js + 'Transform', 'scale3d('+s+','+s+',1)')
        else if @transform2DSupport then (element, x, y, s) ->
          x = x.toFixed(@precision) + 'px'
          y = y.toFixed(@precision) + 'px'
          @css(element, @vendorPrefix.js + 'Transform', 'translate('+x+','+y+')')
          if updateS
            circle = element.getElementsByClassName('circle')
            @css(circle[0], @vendorPrefix.js + 'Transform', 'scale('+s+','+s+')')
        else (element, x, y, s) ->
          x = x.toFixed(@precision) + 'px'
          y = y.toFixed(@precision) + 'px'
          element.style.left = x
          element.style.top = y
          if updateS
            circle = element.getElementsByClassName('circle')
            s = s * 100 + '%'
            circle.style.width = s
            circle.style.height = s

        @moveCircles = if @wrap then (dx, dy) ->
          self = this
          for circle in @circles
            do (circle) ->
              circle.x += dx
              circle.y += dy
              if circle.x < self.minx
                circle.x += self.rx * (1 + Math.floor((self.minx - circle.x)/self.rx))
              else if circle.x > self.maxx
                circle.x -= self.rx * (1 + Math.floor((circle.x - self.maxx)/self.rx))
              if circle.y < self.miny
                circle.y += self.ry * (1 + Math.floor((self.miny - circle.y)/self.ry))
              else if circle.y > self.maxy
                circle.y -= self.ry * (1 + Math.floor((circle.y - self.maxy)/self.ry))
              if self.minx < circle.x < self.maxx and self.miny < circle.y < self.maxy
                self.setCirclePosition(circle)
        else (dx, dy) ->
          self = this
          for circle in @circles
            do (circle) ->
              circle.x += dx
              circle.y += dy
              if self.minx < circle.x < self.maxx and self.miny < circle.y < self.maxy
                self.setCirclePosition(circle)

        @onAnimationFrame = if !isNaN(parseFloat(@limitX)) and !isNaN(parseFloat(@limitY)) then (now) ->
          @mx = @clamp(@ix * @ew * @scalarX, -@limitX, @limitX)
          @my = @clamp(@iy * @eh * @scalarY, -@limitY, @limitY)
          @vx += (@mx - @vx) * @frictionX
          @vy += (@my - @vy) * @frictionY
          @moveCircles(@vx, @vy)
          @raf = requestAnimationFrame(@onAnimationFrame)
        else if !isNaN(parseFloat(@limitX)) then (now) ->
          @mx = @clamp(@ix * @ew * @scalarX, -@limitX, @limitX)
          @my = @iy * @eh * @scalarY
          @vx += (@mx - @vx) * @frictionX
          @vy += (@my - @vy) * @frictionY
          @moveCircles(@vx, @vy)
          @raf = requestAnimationFrame(@onAnimationFrame)
        else if !isNaN(parseFloat(@limitY)) then (now) ->
          @mx = @ix * @ew * @scalarX
          @my = @clamp(@iy * @eh * @scalarY, -@limitY, @limitY)
          @vx += (@mx - @vx) * @frictionX
          @vy += (@my - @vy) * @frictionY
          @moveCircles(@vx, @vy)
          @raf = requestAnimationFrame(@onAnimationFrame)
        else (now) ->
          @mx = @ix * @ew * @scalarX
          @my = @iy * @eh * @scalarY
          @vx += (@mx - @vx) * @frictionX
          @vy += (@my - @vy) * @frictionY
          @moveCircles(@vx, @vy)
          @raf = requestAnimationFrame(@onAnimationFrame)

        @onMouseDown = if @relativeInput and @clipRelativeInput then (event) ->
          unless @dragging
            if event.changedTouches? and event.changedTouches.length > 0
              @activeTouch = event.changedTouches[0].identifier
            else
              event.preventDefault()
            # Cache event coordinates.
            {clientX, clientY} = @getCoordinatesFromEvent(event)
            # Calculate Mouse Input
            clientX = @clamp(clientX, @ex, @ex + @ew)
            clientY = @clamp(clientY, @ey, @ey + @eh)
            @fix = clientX
            @fiy = clientY
            @enableDrag()
        else (event) ->
          unless @dragging
            if event.changedTouches? and event.changedTouches.length > 0
              @activeTouch = event.changedTouches[0].identifier
            else
              event.preventDefault()
            # Cache event coordinates.
            {clientX, clientY} = @getCoordinatesFromEvent(event)
            @fix = clientX
            @fiy = clientY
            @enableDrag()

        @onMouseMove = if @relativeInput and @clipRelativeInput then (event) ->
          event.preventDefault()

          unless @moved
            addClass(@element, 'moved')
            @moved = true

          # Cache event coordinates.
          {clientX, clientY} = @getCoordinatesFromEvent(event)
          clientX = @clamp(clientX, @ex, @ex + @ew)
          clientY = @clamp(clientY, @ey, @ey + @eh)

          # Calculate input relative to the element.
          @ix = (clientX - @ex - @fix) / @ew
          @iy = (clientY - @ey - @fiy) / @eh

          @fix = clientX
          @fiy = clientY
        else if @relativeInput then (event) ->
          event.preventDefault()

          unless @moved
            addClass(@element, 'moved')
            @moved = true

          # Cache event coordinates.
          {clientX, clientY} = @getCoordinatesFromEvent(event)

          # Calculate input relative to the element.
          @ix = (clientX - @ex - @fix) / @ew
          @iy = (clientY - @ey - @fiy) / @eh

          @fix = clientX
          @fiy = clientY
        else (event) ->
          event.preventDefault()

          unless @moved
            addClass(@element, 'moved')
            @moved = true

          # Cache event coordinates.
          {clientX, clientY} = @getCoordinatesFromEvent(event)

          @ix = (clientX - @fix) / @ww
          @iy = (clientY - @fiy) / @wh

          @fix = clientX
          @fiy = clientY

        # Callbacks
        @onMouseDown = @onMouseDown.bind(this)
        @onMouseMove = @onMouseMove.bind(this)
        @onMouseUp = @onMouseUp.bind(this)
        @onAnimationFrame = @onAnimationFrame.bind(this)
        @onWindowResize = @onWindowResize.bind(this)

        # Initialise
        @initialise()

    extend: () ->
      if arguments.length > 1
        master = arguments[0]
        for object in arguments
          do (object) ->
            for key of object
              master[key] = object[key]

    data: (element, name) ->
      @deserialize(element.getAttribute('data-'+name))

    deserialize: (value) ->
      if value is "true"
        return true
      else if value is "false"
        return false
      else if value is "null"
        return null
      else if !isNaN(parseFloat(value)) and isFinite(value)
        return parseFloat(value)
      else
        return value

    initialise: () ->

      # Configure Context Styles
      if @transform3DSupport then @accelerate(@element)
      style = window.getComputedStyle(@element)
      if style.getPropertyValue('position') is 'static'
        @element.style.position = 'relative'

      @start()

      # Setup
      @updateDimensions()
      @updateCircles()

    start: () ->
      if !@started
        @started = yes
        window.addEventListener('mousedown', @onMouseDown)
        window.addEventListener('mouseup', @onMouseUp)
        window.addEventListener('touchstart', @onMouseDown)
        window.addEventListener('touchend', @onMouseUp)
        window.addEventListener('resize', @onWindowResize)

    stop: () ->
      if @started
        @started = no
        cancelAnimationFrame(@raf)
        window.removeEventListener('mousedown', @onMouseDown)
        window.removeEventListener('mouseup', @onMouseUp)
        window.removeEventListener('touchstart', @onMouseDown)
        window.removeEventListener('touchend', @onMouseUp)
        window.removeEventListener('resize', @onWindowResize)

    updateCircles: () ->

      # Cache Circle Elements
      @circles = @element.getElementsByClassName('circle-container')

      @numberOfCol = Math.ceil(Math.sqrt(2*@circles.length)/2)
      if @numberOfCol < 4
        # TODO
        throw new Error("Need more element")

      # Configure Circle Styles
      j = 0
      i = -1
      self = this
      for circle in @circles
        do (circle) ->
          if self.transform3DSupport
            self.accelerate(circle)
          circle.style.width = self.circleDiameter + "px"
          circle.style.height = self.circleDiameter + "px"
          if j % self.numberOfCol == 0
            i++
            j = 0
          circle.i = i
          circle.j = j
          j++

      @numberOfRow = @circles[@circles.length-1].i + 1

      # Find central Element
      ci = Math.floor(@numberOfRow/2)-1
      cj = Math.floor(@numberOfCol/2)-2

      @layoutCircles(ci, cj)

      @cx = parseFloat(@circles[cj + @numberOfCol*ci].x)
      @cy = parseFloat(@circles[cj + @numberOfCol*ci].y)

    layoutCircles: (ci, cj) ->

      # Configure Circle Positions
      self = this

      for circle in @circles
        do (circle) ->
          circle.y = 14 + (circle.i - ci) * 5
          if (circle.i - ci) % 2 is 1 or (circle.i - ci) % 2 is -1
            offset = 5
          else
            offset = -2
          circle.x = offset + (circle.j - cj) * 14
          circle.y = circle.y/34 * if self.portrait then self.ew else self.eh
          circle.x = circle.x/44 * if self.portrait then self.eh else self.ew
          self.setCirclePosition(circle, yes)

      @appeared()

      # Update max and min coordinates
      @miny = Math.min(parseFloat(@circles[0].y) - parseFloat(@circleDiameter)*2/3, -parseFloat(@circleDiameter)*2/3)
      @maxy = Math.max(parseFloat(@circles[@circles.length-1].y) + parseFloat(@circleDiameter)/2, @eh-parseFloat(@circleDiameter)*2/3)
      @ry = @maxy - @miny
      @minx = Math.min(parseFloat(Math.min(@circles[0].x, @circles[@numberOfCol].x)) - parseFloat(@circleDiameter)*2/3, -parseFloat(@circleDiameter)*2/3)
      @maxx = Math.max(Math.max(@circles[@circles.length-1].x, @circles[@circles.length-1-@numberOfCol].x) + parseFloat(@circleDiameter)*2/3, @ew-parseFloat(@circleDiameter)*2/3)
      @rx = @maxx - @minx

    appeared: () ->
      addClass(@element, "appeared")
      @moved = false

      css = "#{@vendorPrefix.css}animation : appear 1s;
          #{@vendorPrefix.css}animation-delay: -400ms;"
      keyframes = "
          0% {
            #{@vendorPrefix.css}transform:translate3d(#{(@ew-@circleDiameter)/2}px, #{(@eh-@circleDiameter)/2}px, 0);
            opacity: 0;
          }
          40% {
            opacity: 0;
          }"

      # http://davidwalsh.name/add-rules-stylesheets
      addCSSRule = (sheet, selector, rules, index) ->
        if "insertRule" of sheet
          sheet.insertRule selector + "{" + rules + "}", index
        else sheet.addRule selector, rules, index  if "addRule" of sheet

      if document.styleSheets and document.styleSheets.length
        addCSSRule(
          document.styleSheets[0],
          "@#{@vendorPrefix.css}keyframes appear",
          keyframes,
          0
        )
        addCSSRule(
          document.styleSheets[0],
          '#circlesUI.appeared > .circle-container.circle-visible',
          css,
          0
        )
      else
        s = document.createElement('style')
        s.innerHTML = "@#{@vendorPrefix.css}keyframes appear {" +
          keyframes +
          '} #circlesUI.appeared > .circle-container.circle-visible {' +
          css
        document.getElementsByTagName('head')[0].appendChild(s)

      self = this
      setTimeout ( ->
        removeClass self.element, "appeared"
      ), 1000

    updateDimensions: () ->
      @ww = window.innerWidth
      @wh = window.innerHeight

      @updateBounds()

      @portrait = @eh > @ew
      if @portrait
        @circleDiameter = (6/34 * @ew).toFixed(@precision)
      else
        @circleDiameter = (6/34 * @eh).toFixed(@precision)

      @updateCircles()

    updateBounds: () ->
      @bounds = @element.getBoundingClientRect()
      @ex = @bounds.left
      @ey = @bounds.top
      @ew = @bounds.width
      @eh = @bounds.height

    enableDrag: () ->
      if !@dragging
        @dragging = yes
        window.addEventListener('mousemove', @onMouseMove)
        window.addEventListener('touchmove', @onMouseMove)
        @raf = requestAnimationFrame(@onAnimationFrame)

    disableDrag: () ->
      if @dragging
        @dragging = no
        window.removeEventListener('mousemove', @onMouseMove)
        window.removeEventListener('touchmove', @onMouseMove)

    calibrate: (x, y) ->
      @calibrateX = x ? @calibrateX
      @calibrateY = y ? @calibrateY

    invert: (x, y) ->
      @invertX = x ? @invertX
      @invertY = y ? @invertY

    friction: (x, y) ->
      @frictionX = x ? @frictionX
      @frictionY = y ? @frictionY

    scalar: (x, y) ->
      @scalarX = x ? @scalarX
      @scalarY = y ? @scalarY

    limit: (x, y) ->
      @limitX = x ? @limitX
      @limitY = y ? @limitY

    clamp: (value, min, max) ->
      value = Math.max(value, min)
      Math.min(value, max)

    css: (element, property, value) ->
      element.style[property] = value

    accelerate: (element) ->
      @css(element, @vendorPrefix.transform, 'translate3d(0,0,0)')

    setCirclePosition: (circle, forceUpdate) ->
      if circle.x > -@circleDiameter and circle.x < @ew + @circleDiameter and circle.y > -@circleDiameter and circle.y < @eh + @circleDiameter
        addClass(circle, @classVisible)
        if circle.x > @circleDiameter*1/2 and circle.x < @ew - @circleDiameter*3/2 and circle.y > @circleDiameter*1/3 and circle.y < @eh - @circleDiameter*3/2
          if !hasClass(circle, @classBig)
            addClass(circle, @classBig)
            @setPositionAndScale(circle, circle.x, circle.y, 1, yes)
          else
            @setPositionAndScale(circle, circle.x, circle.y, 1, forceUpdate)
        else if hasClass(circle, @classBig)
          removeClass(circle, @classBig)
          @setPositionAndScale(circle, circle.x, circle.y, 0.33333, yes)
        else
          @setPositionAndScale(circle, circle.x, circle.y, 0.33333, forceUpdate)
      else if hasClass(circle, @classVisible)
        removeClass(circle, @classVisible)

    onWindowResize: (event) ->
      @updateDimensions()

    getCoordinatesFromEvent: (event) ->
      # The user is using a touch screen
      if event.touches? and event.touches.length? and event.touches.length > 0
        @getCoordinatesFromEvent = (event) ->
          find = (arr, f) ->
            for e in arr when f e
              return e
            return
          self = this
          touch= find event.touches, (touch) -> touch.identifier is self.activeTouch
          return {clientX: touch.clientX, clientY: touch.clientY}
      # The user is using a mouse
      else
        @getCoordinatesFromEvent = (event) ->
          {clientX: event.clientX, clientY: event.clientY}
      #Now that we have rewrite this function, call it again
      @getCoordinatesFromEvent event

    onMouseUp: (event) ->
      @ix = 0
      @iy = 0
      @activeTouch = null
      @disableDrag()

      # Easing
      i = 0
      while Math.abs(@vx) > 0 and Math.abs(@vx) > 0 and i < 50
        @raf = requestAnimationFrame(@onAnimationFrame)
        i++
      cancelAnimationFrame(@raf)

    # Expose CirclesUI

    window[NAME] = CirclesUI

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

    Draggabilly
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

###
# Request Animation Frame Polyfill.
# @author Tino Zijdel
# @author Paul Irish
# @see https://gist.github.com/paulirish/1579671
###

lastTime = 0
vendors = ['ms', 'moz', 'webkit', 'o']

for vendor in vendors
  do (vendor) ->
    window.requestAnimationFrame = window[vendor+'RequestAnimationFrame']
    window.cancelAnimationFrame = window[vendor+'CancelAnimationFrame'] ||
      window[vendor+'CancelRequestAnimationFrame']

if !window.requestAnimationFrame
  window.requestAnimationFrame = (callback, element) ->
    currTime = new Date().getTime()
    timeToCall = Math.max(0, 16 - (currTime - lastTime))
    id = window.setTimeout(
      () ->
        callback(currTime + timeToCall)
    , timeToCall )
    lastTime = currTime + timeToCall
    return id;

if !window.cancelAnimationFrame
  window.cancelAnimationFrame = (id) ->
    clearTimeout(id)

do (window, document) ->
  class Signup
    constructor: (@form, options) ->
      # DOM Context
      @first_name = @form.querySelector('#first_name')
      @last_name = @form.querySelector('#last_name')
      @slug_name = @form.querySelector('#slug_name')
      @birthday = @form.querySelector('#birthday')
      @email = @form.querySelector('#email')
      @password = @form.querySelector('#password')

      # States
      @slug_changed = false

      # Callbacks
      @onFirstNameBlur = @onFirstNameBlur.bind(this)
      @onLastNameBlur = @onLastNameBlur.bind(this)
      @onNamesChange = @onNamesChange.bind(this)
      @onSlugNameBlur = @onSlugNameBlur.bind(this)
      @onBirthdayBlur = @onBirthdayBlur.bind(this)
      @onPasswordBlur = @onPasswordBlur.bind(this)
      @onSubmit = @onSubmit.bind(this)

      # Initialise
      @initialise()

    initialise: () ->
      @first_name.addEventListener('blur', @onFirstNameBlur)
      @last_name.addEventListener('blur', @onLastNameBlur)
      @first_name.addEventListener('input', @onNamesChange)
      @last_name.addEventListener('input', @onNamesChange)
      @slug_name.addEventListener('blur', @onSlugNameBlur)
      @birthday.addEventListener('blur', @onBirthdayBlur)
      @password.addEventListener('blur', @onPasswordBlur)
      @form.addEventListener('submit', @onSubmit)

    checkFirstName: () ->
      if @first_name.value.length > 1
        if classie.hasClass @first_name, 'error' then classie.removeClass @first_name, 'error'
        true
      else
        classie.addClass @first_name, 'error'
        false

    checkLastName: () ->
      if @last_name.value.length > 1
        if classie.hasClass @last_name, 'error' then classie.removeClass @last_name, 'error'
        true
      else
        classie.addClass @last_name, 'error'
        false

    checkPassword: () ->
      if @password.value.length > 5
        if classie.hasClass @password, 'error' then classie.removeClass @password, 'error'
        true
      else
        classie.addClass @password, 'error'
        false

    checkSlugName: () ->
      if @slug_name.value.length > 1 and @checkSluggish()
        if classie.hasClass @slug_name, 'error' then classie.removeClass @slug_name, 'error'
        true
      else
        classie.addClass @slug_name, 'error'
        false

    checkSluggish: () ->
      re = /^[a-z0-9\-]*$/
      re.test(@slug_name.value)

    checkBirthday: () ->
      re = /^[0-3][0-9][\/][0-1][0-9][\/][1-2][0-9]{3}$/
      parts = @birthday.value.split('/')
      if re.test(@birthday.value) and (new Date(parts[2], parts[1]-1, parts[0]))?
        if classie.hasClass @birthday, 'error' then classie.removeClass @birthday, 'error'
        true
      else
        classie.addClass @birthday, 'error'
        false

    generateSlug: () ->
      base = if @last_name.value.length > 0 and @first_name.value.length > 0 then @first_name.value + '-' + @last_name.value
      else if @first_name.value.length > 0 then @first_name.value
      else @last_name.value
      base.toString().toLowerCase()
        .replace(/\s+/g, '-')           # Replace spaces with -
        .replace(/[^\w\-]+/g, '')       # Remove all non-word chars
        .replace(/\-\-+/g, '-')         # Replace multiple - with single -
        .replace(/^-+/, '')             # Trim - from start of text
        .replace(/-+$/, '');            # Trim - from end of text

    onFirstNameBlur: () ->
      @checkFirstName()

    onLastNameBlur: () ->
      @checkLastName()

    onNamesChange: () ->
      unless @slug_changed
        @slug_name.value = @generateSlug()

    onSlugNameBlur: () ->
      @slug_changed = true
      @checkSlugName()

    onBirthdayBlur: () ->
      @checkBirthday()

    onPasswordBlur: () ->
      @checkPassword()

    onSubmit: (event) ->
      unless @checkFirstName() and @checkLastName() and @checkSlugName() and @checkBirthday() and @checkPassword()
        event.preventDefault()

  window.Signup = Signup
