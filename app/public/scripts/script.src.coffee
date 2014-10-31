###
 * CirclesUI.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Creates a CirclesUI effect between an array of layers,
 *              driving the motion from the gyroscope output of a smartdevice.
 *              If no gyroscope is available, the cursor position is used.
###
do (window, document) ->

  # class helper functions from bonzo https://github.com/ded/bonzo
  classReg = ( className ) ->
    return new RegExp("(^|\\s+)" + className + "(\\s+|$)")

  # classList support for class management
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
    relativeInput: false,
    clipRelativeInput: false,
    invertX: false,
    invertY: false,
    limitX: false,
    limitY: false,
    scalarX: 200.0,
    scalarY: 200.0,
    frictionX: 0.1,
    frictionY: 0.1,
    precision: 1,
    classBig: "circle-big"
    classVisible: "circle-visible"

  CirclesUI = (element, options) ->

    # DOM Context
    @element = element
    @circles = element.getElementsByClassName('circle-container')

    if @circles.length < 24
      console.log "Not enought circle to display a proper UI"
    else
      # Data Extraction
      data =
        invertX: @data(@element, 'invert-x'),
        invertY: @data(@element, 'invert-y'),
        limitX: @data(@element, 'limit-x'),
        limitY: @data(@element, 'limit-y'),
        scalarX: @data(@element, 'scalar-x'),
        scalarY: @data(@element, 'scalar-y'),
        frictionX: @data(@element, 'friction-x'),
        frictionY: @data(@element, 'friction-y'),
        precision: @data(@element, 'precision')
        classBig: @data(@element, 'class-big')
        classVisible: @data(@element, 'class-visible')

      # Delete Null Data Values
      for key of data
        delete data[key] if data[key] is null

      # Compose Settings Object
      @extend(this, DEFAULTS, options, data);

      # States
      @enabled = false
      @raf = null

      # Element Bounds
      @bounds = null
      @ex = 0
      @ey = 0
      @ew = 0
      @eh = 0

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

      # Callbacks
      @onMouseDown = @onMouseDown.bind(this)
      @onMouseMove = @onMouseMove.bind(this)
      @onMouseUp = @onMouseUp.bind(this)
      @onAnimationFrame = @onAnimationFrame.bind(this)
      @onWindowResize = @onWindowResize.bind(this)

      # Vendors Prefixes
      getVendorPrefix = (arrayOfPrefixes) ->
        result = null
        i = 0

        while i < arrayOfPrefixes.length
          unless typeof element.style[arrayOfPrefixes[i]] is "undefined"
            result = arrayOfPrefixes[i]
            break
          ++i
        result

      getVendorCSSPrefix = (arrayOfPrefixes) ->
        result = null
        i = 0

        while i < arrayOfPrefixes.length
          unless typeof element.style[arrayOfPrefixes[i][0]] is "undefined"
            result = arrayOfPrefixes[i][1]
            break
          ++i
        result

      @vendorPrefix =
        css : getVendorCSSPrefix([["transform", ""], ["msTransform", "-ms-"], ["MozTransform", "-moz-"], ["WebkitTransform", "-webkit-"], ["OTransform", "-o-"]])
        transform : getVendorPrefix(["transform", "msTransform", "MozTransform", "WebkitTransform", "OTransform"])

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

  CirclesUI.prototype.transfSupport = (value) ->
    element = document.createElement('div')
    propertySupport = false
    propertyValue = null
    featureSupport = false
    cssProperty = null
    jsProperty = null
    i = 0
    propertySupport = @vendorPrefix.transform?
    switch value
      when '2D' then featureSupport = propertySupport
      when '3D' then do () ->
        if propertySupport
          body = document.body || document.createElement('body')
          documentElement = document.documentElement
          documentOverflow = documentElement.style.overflow
          isCreatedBody = false
          if !document.body
            isCreatedBody = true
            documentElement.style.overflow = 'hidden'
            documentElement.appendChild(body)
            body.style.overflow = 'hidden'
            body.style.background = ''
          body.appendChild(element)
          element.style[@vendorPrefix.transform] = 'translate3d(1px,1px,1px)'
          propertyValue = window.getComputedStyle(element).getPropertyValue(cssProperty)
          featureSupport = propertyValue? and
            propertyValue.length > 0 and
            propertyValue isnt "none"
          documentElement.style.overflow = documentOverflow
          body.removeChild(element)
          if isCreatedBody
            body.removeAttribute('style')
            body.parentNode.removeChild(body)
    return featureSupport

  CirclesUI.prototype.ww = null
  CirclesUI.prototype.wh = null
  CirclesUI.prototype.wrx = null
  CirclesUI.prototype.wry = null
  CirclesUI.prototype.portrait = null
  CirclesUI.prototype.transform2DSupport = true #CirclesUI.prototype.transfSupport('2D')
  CirclesUI.prototype.transform3DSupport = true #CirclesUI.prototype.transfSupport('3D')

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
    circlesMatrix = []
    numberOfCol = Math.ceil(Math.sqrt(2*@circles.length)/2)
    if numberOfCol < 4
      # TODO
      console.log "need more for now"

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
        if j % numberOfCol == 0
          i++
          j = 0
        circle.i = i
        circle.j = j
        j++

    @numberOfCol = numberOfCol
    @numberOfRow = @circles[@circles.length-1].i + 1

    # Find central Element
    ci = Math.floor(@numberOfRow/2)-1
    cj = Math.floor(@numberOfCol/2)-2

    @layoutCircles(ci, cj)

  CirclesUI.prototype.layoutCircles = (ci, cj) ->

    # Configure Circle Positions
    self = this

    for circle in @circles
      do (circle) ->
        circle.y = 14 + (circle.i - ci) * 5
        if (circle.i - ci) % 2 is 1 or (circle.i - ci) % 2 is -1
          offset = -7
        else
          offset = -14
        circle.x = offset + 12 + (circle.j - cj) * 14
        circle.y = circle.y/34 * if self.portrait then self.ew else self.eh
        circle.x = circle.x/44 * if self.portrait then self.eh else self.ew
        self.setCirclePosition(circle)

    @appeared()

    @miny = Math.min(parseFloat(@circles[0].y) - parseFloat(@circleDiameter)/2, -parseFloat(@circleDiameter)/2)
    @maxy = Math.max(parseFloat(@circles[@circles.length-1].y) + parseFloat(@circleDiameter)/2, @eh+parseFloat(@circleDiameter)/2)
    @cy = parseFloat(@circles[cj + @numberOfCol*ci].y)
    @ry = @maxy - @miny
    @minx = Math.min(parseFloat(Math.min(@circles[0].x, @circles[@numberOfCol].x)) - parseFloat(@circleDiameter)/2, -parseFloat(@circleDiameter)/2)
    @maxx = Math.max(Math.max(@circles[@circles.length-1].x, @circles[@circles.length-1-@numberOfCol].x) + parseFloat(@circleDiameter), @ew+parseFloat(@circleDiameter)/2)
    @cx = parseFloat(@circles[cj + @numberOfCol*ci].x)
    @rx = @maxx - @minx

  CirclesUI.prototype.appeared = () ->
    addClass(@element, "appeared")
    self = this
    setTimeout ( ->
      removeClass self.element, "appeared"
    ), 1000
    css = "
      #circlesUI.appeared > .circle-container.circle-visible {
        #{@vendorPrefix.css}animation : appear 1s;
        #{@vendorPrefix.css}animation-delay: -400ms;
      }"
    keyframes = "
      @#{@vendorPrefix.css}keyframes appear {
        0% {
          #{@vendorPrefix.css}transform:translate3d(#{(@ew-@circleDiameter)/2}px, #{(@eh-@circleDiameter)/2}px, 0);
          opacity: 0;
        }
        40% {
          opacity: 0;
        }
      }"

    if document.styleSheets and document.styleSheets.length
      document.styleSheets[0].insertRule(keyframes, 0)
      document.styleSheets[0].insertRule(css, 0)
    else
      s = document.createElement('style')
      s.innerHTML = keyframes + css
      document.getElementsByTagName('head')[0].appendChild(s)

  CirclesUI.prototype.updateDimensions = () ->
    @ww = window.innerWidth
    @wh = window.innerHeight
    @updateBounds()
    portrait = @eh > @ew
    if portrait
      @circleDiameter = (6/34 * @ew).toFixed(@precision)
    else
      @circleDiameter = (6/34 * @eh).toFixed(@precision)
    @updateCircles()
    @portrait = portrait

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
          addClass(circle, "hideMovement")
          circle.x += self.rx * (1 + Math.floor((self.minx - circle.x)/self.rx))
        else if circle.x > self.maxx
          addClass(circle, "hideMovement")
          circle.x -= self.rx * (1 + Math.floor((circle.x - self.maxx)/self.rx))
        if circle.y < self.miny
          addClass(circle, "hideMovement")
          circle.y += self.ry * (1 + Math.floor((self.miny - circle.y)/self.ry))
        else if circle.y > self.maxy
          addClass(circle, "hideMovement")
          circle.y -= self.ry * (1 + Math.floor((circle.y - self.maxy)/self.ry))
        self.setCirclePosition(circle)
        removeClass(circle, "hideMovement")

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
      cancelAnimationFrame(@raf)

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
    if circle.x > @circleDiameter*1/2 and circle.x < @ww - @circleDiameter*3/2 and circle.y > @circleDiameter*1/3 and circle.y < @wh - @circleDiameter*3/2
      addClass(circle, @classBig)
    else if hasClass(circle, @classBig)
      removeClass(circle, @classBig)

    if circle.x > -@circleDiameter and circle.x < @ww + @circleDiameter and circle.y > -@circleDiameter and circle.y < @wh + @circleDiameter
      addClass(circle, @classVisible)
    else if hasClass(circle, @classVisible)
      removeClass(circle, @classVisible)

    @setPositionAndScale(circle, circle.x, circle.y, 1)

  CirclesUI.prototype.setPositionAndScale = (element, x, y, s) ->
    x = x.toFixed(@precision)
    y = y.toFixed(@precision)
    x += 'px'
    y += 'px'
    if @transform3DSupport
      @css(element, @vendorPrefix.transform, 'translate3d('+x+','+y+',0)')
    else if @transform2DSupport
      @css(element, @vendorPrefix.transform, 'translate('+x+','+y+')')
    else
      element.style.left = x
      element.style.top = y

  CirclesUI.prototype.onWindowResize = (event) ->
    @updateDimensions()

  CirclesUI.prototype.onAnimationFrame = () ->

    @mx = @ix
    @my = @iy

    @mx *= @ew * (@scalarX / 100)
    @my *= @eh * (@scalarY / 100)

    if !isNaN(parseFloat(@limitX))
      @mx = @clamp(@mx, -@limitX, @limitX)
    if !isNaN(parseFloat(@limitY))
      @my = @clamp(@my, -@limitY, @limitY)

    @vx += (@mx - @vx) * @frictionX
    @vy += (@my - @vy) * @frictionY

    if Math.abs(@vx) < 1 then @vx = 0
    if Math.abs(@vy) < 1 then @vy = 0

    @moveCircles(@vx, @vy)

    @raf = requestAnimationFrame(@onAnimationFrame)

  CirclesUI.prototype.getCoordinatesFromEvent= (event) ->
    self = this
    if event.touches? and event.touches.length? and event.touches.length > 0
      for touch in event.touches
        do (touch) ->
          console.log touch.identifier
          console.log self.activeTouch
          if touch.identifier is self.activeTouch
            return {clientX: touch.clientX, clientY: touch.clientY}
    else
      return {clientX: event.clientX, clientY: event.clientY}

  CirclesUI.prototype.onMouseDown = (event) ->
    event.preventDefault()

    unless @enabled
      if event.changedTouches? and event.changedTouches.length > 0
        @activeTouch = event.changedTouches[0].identifier
      # Cache event coordinates.
      {clientX, clientY} = @getCoordinatesFromEvent(event)

      # Calculate Mouse Input
      if @relativeInput and @clipRelativeInput
        clientX = @clamp(clientX, @ex, @ex + @ew)
        clientY = @clamp(clientY, @ey, @ey + @eh)
      @fix = clientX
      @fiy = clientY
      @enable()

  CirclesUI.prototype.onMouseUp = (event) ->
    @ix = 0
    @iy = 0
    @activeTouch = null
    # Easing
    i = 0
    while Math.abs(@vx) > 0 and Math.abs(@vx) > 0 and i < 50
      @raf = requestAnimationFrame(@onAnimationFrame)
      i++

    @disable()

    ###addClass(@element, "animating")
    center = @findCenterCircle()
    dx = center.x - @cx
    dy = center.y - @cy
    @moveCircles(dx, dy)
    self = this
    setTimeout ( ->
      removeClass self.element, "animating"
    ), 300###

  CirclesUI.prototype.onMouseMove = (event) ->
    event.preventDefault()

    addClass(@element, 'moved') unless hasClass(@element, 'moved')

    # Cache event coordinates.
    {clientX, clientY} = @getCoordinatesFromEvent(event)

    # Calculate Mouse Input
    if @relativeInput

      # Clip mouse coordinates inside element bounds.
      if @clipRelativeInput
        clientX = @clamp(clientX, @ex, @ex + @ew)
        clientY = @clamp(clientY, @ey, @ey + @eh)

      # Calculate input relative to the element.
      @ix = (clientX - @ex - @fix) / @ew
      @iy = (clientY - @ey - @fiy) / @eh

    else
      # Calculate input relative to the window.
      @ix = (clientX - @fix) / @ww
      @iy = (clientY - @fiy) / @wh
    console.log @ix
    console.log @iy
    @fix = clientX
    @fiy = clientY

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
