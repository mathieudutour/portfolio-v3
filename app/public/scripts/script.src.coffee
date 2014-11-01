###
 * CirclesUI.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Creates a Circles UI
###
do (window, document) ->

  Timer = () ->
    @framesUntilNextStat = 60
    @fps = 0
    @last = new Date
    @timerShow = document.createElement("div")
    document.body.insertBefore @timerShow, null
    @timerShow.style['position'] = "absolute"
    @timerShow.style['top'] = "10px"
    @timerShow.style['left'] = "10px"
    @timerShow.style['color'] = "#FFF"

  Timer.prototype.tick = (now)->
    @framesUntilNextStat--
    if @framesUntilNextStat <= 0
      @framesUntilNextStat = 60 # Scheduling the next statistics
      @fps = ~~(60 * 1000 / (now - @last))
      @last = now
      @timerShow.innerHTML = " FPS : #{@fps}"

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

  # Constants
  NAME = 'CirclesUI'
  DEFAULTS =
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
    showFPS: false

  CirclesUI = (element, options) ->

    # DOM Context
    @element = element
    @circles = element.getElementsByClassName('circle-container')

    if @circles.length < 24
      throw new Error("Not enought circle to display a proper UI")
    else
      # Data Extraction
      data =
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
        showFPS: @data(@element, 'show-fps')

      # Delete Null Data Values
      for key of data
        delete data[key] if data[key] is null

      # Compose Settings Object
      @extend(this, DEFAULTS, options, data);

      # States
      @enabled = false
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

      # Timer for FPS
      if @showFPS then @timer = new Timer()

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
      @transform2DSupport = true # TODO
      @transform3DSupport = ( (transform) ->
        el = document.createElement("p")
        has3d = undefined

        # Add it to the body to get the computed style.
        document.body.insertBefore el, null
        if typeof el.style[transform] isnt 'undefined'
          el.style[transform] = "translate3d(1px,1px,1px)"
          has3d = window.getComputedStyle(el).getPropertyValue(transform)
        document.body.removeChild el
        typeof has3d isnt 'undefined' and has3d.length > 0 and has3d isnt "none"
      )(@vendorPrefix.css + 'transform')

      @setPositionAndScale = if @transform3DSupport then (element, x, y, s) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        @css(element, @vendorPrefix.js + 'Transform', 'translate3d('+x+','+y+',0)')
      else if @transform2DSupport then (element, x, y, s) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        @css(element, @vendorPrefix.js + 'Transform', 'translate('+x+','+y+')')
      else (element, x, y, s) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        element.style.left = x
        element.style.top = y

      @onAnimationFrame = if @showFPS and !isNaN(parseFloat(@limitX)) and !isNaN(parseFloat(@limitY)) then (now) ->
        @mx = @clamp(@ix * @ew * @scalarX, -@limitX, @limitX)
        @my = @clamp(@iy * @eh * @scalarY, -@limitY, @limitY)
        @vx += (@mx - @vx) * @frictionX
        @vy += (@my - @vy) * @frictionY
        @moveCircles(@vx, @vy)
        @timer.tick(now)
        @raf = requestAnimationFrame(@onAnimationFrame)
      else if @showFPS and !isNaN(parseFloat(@limitX)) then (now) ->
        @mx = @clamp(@ix * @ew * @scalarX, -@limitX, @limitX)
        @my = @iy * @eh * @scalarY
        @vx += (@mx - @vx) * @frictionX
        @vy += (@my - @vy) * @frictionY
        @moveCircles(@vx, @vy)
        @timer.tick(now)
        @raf = requestAnimationFrame(@onAnimationFrame)
      else if @showFPS and !isNaN(parseFloat(@limitY)) then (now) ->
        @mx = @ix * @ew * @scalarX
        @my = @clamp(@iy * @eh * @scalarY, -@limitY, @limitY)
        @vx += (@mx - @vx) * @frictionX
        @vy += (@my - @vy) * @frictionY
        @moveCircles(@vx, @vy)
        @timer.tick(now)
        @raf = requestAnimationFrame(@onAnimationFrame)
      else if @showFPS then (now) ->
        @mx = @ix * @ew * @scalarX
        @my = @iy * @eh * @scalarY
        @vx += (@mx - @vx) * @frictionX
        @vy += (@my - @vy) * @frictionY
        @moveCircles(@vx, @vy)
        @timer.tick(now)
        @raf = requestAnimationFrame(@onAnimationFrame)
      else if !isNaN(parseFloat(@limitX)) and !isNaN(parseFloat(@limitY)) then (now) ->
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
        event.preventDefault()

        unless @enabled
          if event.changedTouches? and event.changedTouches.length > 0
            @activeTouch = event.changedTouches[0].identifier
          # Cache event coordinates.
          {clientX, clientY} = @getCoordinatesFromEvent(event)
          # Calculate Mouse Input
          clientX = @clamp(clientX, @ex, @ex + @ew)
          clientY = @clamp(clientY, @ey, @ey + @eh)
          @fix = clientX
          @fiy = clientY
          @enable()
      else (event) ->
        event.preventDefault()

        unless @enabled
          if event.changedTouches? and event.changedTouches.length > 0
            @activeTouch = event.changedTouches[0].identifier
          # Cache event coordinates.
          {clientX, clientY} = @getCoordinatesFromEvent(event)
          @fix = clientX
          @fiy = clientY
          @enable()

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

  CirclesUI.prototype.extend = () ->
    if arguments.length > 1
      master = arguments[0]
      for object in arguments
        do (object) ->
          for key of object
            master[key] = object[key]

  CirclesUI.prototype.data = (element, name) ->
    @deserialize(element.getAttribute('data-'+name))

  CirclesUI.prototype.deserialize = (value) ->
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

  CirclesUI.prototype.initialise = () ->

    # Configure Context Styles
    if @transform3DSupport then @accelerate(@element)
    style = window.getComputedStyle(@element)
    if style.getPropertyValue('position') is 'static'
      @element.style.position = 'relative'

    window.addEventListener('mousedown', @onMouseDown)
    window.addEventListener('mouseup', @onMouseUp)
    window.addEventListener('touchstart', @onMouseDown)
    window.addEventListener('touchend', @onMouseUp)
    window.addEventListener('resize', @onWindowResize)

    # Setup
    @updateDimensions()
    @updateCircles()

  CirclesUI.prototype.updateCircles = () ->

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

  CirclesUI.prototype.layoutCircles = (ci, cj) ->

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
        self.setCirclePosition(circle)

    @appeared()

    # Update max and min coordinates
    @miny = Math.min(parseFloat(@circles[0].y) - parseFloat(@circleDiameter)/2, -parseFloat(@circleDiameter)/2)
    @maxy = Math.max(parseFloat(@circles[@circles.length-1].y) + parseFloat(@circleDiameter)/2, @eh+parseFloat(@circleDiameter)/2)
    @ry = @maxy - @miny
    @minx = Math.min(parseFloat(Math.min(@circles[0].x, @circles[@numberOfCol].x)) - parseFloat(@circleDiameter)/2, -parseFloat(@circleDiameter)/2)
    @maxx = Math.max(Math.max(@circles[@circles.length-1].x, @circles[@circles.length-1-@numberOfCol].x) + parseFloat(@circleDiameter), @ew+parseFloat(@circleDiameter)/2)
    @rx = @maxx - @minx

  CirclesUI.prototype.appeared = () ->
    addClass(@element, "appeared")
    removeClass(@element, "moved")
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

  CirclesUI.prototype.updateDimensions = () ->
    @ww = window.innerWidth
    @wh = window.innerHeight

    @updateBounds()

    @portrait = @eh > @ew
    if @portrait
      @circleDiameter = (6/34 * @ew).toFixed(@precision)
    else
      @circleDiameter = (6/34 * @eh).toFixed(@precision)

    @updateCircles()

  CirclesUI.prototype.updateBounds = () ->
    @bounds = @element.getBoundingClientRect()
    @ex = @bounds.left
    @ey = @bounds.top
    @ew = @bounds.width
    @eh = @bounds.height

  CirclesUI.prototype.findCenterCircle = () ->
    self = this
    distance = @rx*@rx + @ry*@ry
    center = null
    for circle in @circles
      do (circle) ->
        dist = (circle.x-self.cx)*(circle.x-self.cx) + (circle.y-self.cy)*(circle.y-self.cy)
        if dist < distance
          distance = dist
          center = circle
    center

  CirclesUI.prototype.moveCircles = (dx, dy) ->
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
        self.setCirclePosition(circle)

  CirclesUI.prototype.enable = () ->
    if !@enabled
      @enabled = true
      window.addEventListener('mousemove', @onMouseMove)
      window.addEventListener('touchmove', @onMouseMove)
      @raf = requestAnimationFrame(@onAnimationFrame)

  CirclesUI.prototype.disable = () ->
    if @enabled
      @enabled = false
      window.removeEventListener('mousemove', @onMouseMove)
      window.removeEventListener('touchmove', @onMouseMove)

  CirclesUI.prototype.calibrate = (x, y) ->
    @calibrateX = x ? @calibrateX
    @calibrateY = y ? @calibrateY

  CirclesUI.prototype.invert = (x, y) ->
    @invertX = x ? @invertX
    @invertY = y ? @invertY

  CirclesUI.prototype.friction = (x, y) ->
    @frictionX = x ? @frictionX
    @frictionY = y ? @frictionY

  CirclesUI.prototype.scalar = (x, y) ->
    @scalarX = x ? @scalarX
    @scalarY = y ? @scalarY

  CirclesUI.prototype.limit = (x, y) ->
    @limitX = x ? @limitX
    @limitY = y ? @limitY

  CirclesUI.prototype.clamp = (value, min, max) ->
    value = Math.max(value, min)
    Math.min(value, max)

  CirclesUI.prototype.css = (element, property, value) ->
    element.style[property] = value

  CirclesUI.prototype.accelerate = (element) ->
    @css(element, @vendorPrefix.transform, 'translate3d(0,0,0)')

  CirclesUI.prototype.setCirclePosition = (circle) ->
    if circle.x > @circleDiameter*1/2 and circle.x < @ew - @circleDiameter*3/2 and circle.y > @circleDiameter*1/3 and circle.y < @eh - @circleDiameter*3/2
      addClass(circle, @classBig)
    else if hasClass(circle, @classBig)
      removeClass(circle, @classBig)

    if circle.x > -@circleDiameter and circle.x < @ew + @circleDiameter and circle.y > -@circleDiameter and circle.y < @eh + @circleDiameter
      addClass(circle, @classVisible)
    else if hasClass(circle, @classVisible)
      removeClass(circle, @classVisible)

    @setPositionAndScale(circle, circle.x, circle.y, 1)

  CirclesUI.prototype.onWindowResize = (event) ->
    @updateDimensions()

  CirclesUI.prototype.getCoordinatesFromEvent = (event) ->
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

  CirclesUI.prototype.onMouseUp = (event) ->
    @ix = 0
    @iy = 0
    @activeTouch = null
    @disable()

    # Easing
    i = 0
    while Math.abs(@vx) > 0 and Math.abs(@vx) > 0 and i < 50
      @raf = requestAnimationFrame(@onAnimationFrame)
      i++
    cancelAnimationFrame(@raf)

  # Expose CirclesUI

  window[NAME] = CirclesUI

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
