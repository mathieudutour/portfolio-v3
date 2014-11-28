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
        else if @transform2DSupport then (element, x, y, s, updateS) ->
          x = x.toFixed(@precision) + 'px'
          y = y.toFixed(@precision) + 'px'
          @css(element, @vendorPrefix.js + 'Transform', 'translate('+x+','+y+')')
          if updateS
            circle = element.getElementsByClassName('circle')
            @css(circle[0], @vendorPrefix.js + 'Transform', 'scale('+s+','+s+')')
        else (element, x, y, s, updateS) ->
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
            classie.addClass(@element, 'moved')
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
            classie.addClass(@element, 'moved')
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
            classie.addClass(@element, 'moved')
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
      classie.addClass(@element, "appeared")
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
        classie.removeClass self.element, "appeared"
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
        classie.addClass(circle, @classVisible)
        if circle.x > @circleDiameter*1/2 and circle.x < @ew - @circleDiameter*3/2 and circle.y > @circleDiameter*1/3 and circle.y < @eh - @circleDiameter*3/2
          if !classie.hasClass(circle, @classBig)
            classie.addClass(circle, @classBig)
            @setPositionAndScale(circle, circle.x, circle.y, 1, yes)
          else
            @setPositionAndScale(circle, circle.x, circle.y, 1, forceUpdate)
        else if classie.hasClass(circle, @classBig)
          classie.removeClass(circle, @classBig)
          @setPositionAndScale(circle, circle.x, circle.y, 0.33333, yes)
        else
          @setPositionAndScale(circle, circle.x, circle.y, 0.33333, forceUpdate)
      else if classie.hasClass(circle, @classVisible)
        classie.removeClass(circle, @classVisible)

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
    has: hasClass
    addClass: addClass
    add: addClass
    removeClass: removeClass
    remove: removeClass
  #Expose Classie
  window.classie = classie

###
 * Draggable.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Drag an object
###
do (window, document) ->

  # Constants
  NAME = 'Draggable'
  DEFAULTS =
    axis: null
    containment: false
    grid: [1,1]
    handle: false
    precision: 1
    classDragging: "is-dragging"
    callbackDragStart: () ->
    callbackDragging: () ->
    callbackDrop: () ->
    droppables: []

  class Draggable
    constructor : (@element, options) ->
      # Data Extraction
      data =
        axis: @data(@element, 'wrap')
        containment: @data(@element, 'relative-input')
        handle: @data(@element, 'clipe-relative-input')
        precision: @data(@element, 'invert-x')
        classDragging: @data(@element, 'invert-y')

      # Delete Null Data Values
      for key of data
        delete data[key] if data[key] is null

      # Compose Settings Object
      @extend(this, DEFAULTS, options, data);

      @handle = @element #TODO

      # States
      @started = false
      @dragging = false
      @raf = null

      # Element Bounds
      @bounds = null
      @ex = 0
      @ey = 0
      @ew = 0
      @eh = 0

      # Windows size
      @ww = 0
      @wh = 0

      # First Input
      @fix = 0
      @fiy = 0

      # Input
      @ix = 0
      @iy = 0

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

      @setPosition = if @transform3DSupport then (x, y) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        @css(@element, @vendorPrefix.js + 'Transform', 'translate3d('+x+','+y+',0)')
      else if @transform2DSupport then (element, x, y, s) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        @css(@element, @vendorPrefix.js + 'Transform', 'translate('+x+','+y+')')
      else (element, x, y, s) ->
        x = x.toFixed(@precision) + 'px'
        y = y.toFixed(@precision) + 'px'
        @element.style.left = x
        @element.style.top = y

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

    onAnimationFrame: (now) ->
      @setPosition(@ix-@fix+@offsetx, @iy-@fiy+@offsety)
      @raf = requestAnimationFrame(@onAnimationFrame)

    getComputedTranslate: (obj) ->
      if !window.getComputedStyle
        return
      style = getComputedStyle(obj)
      transform = style.transform || style.webkitTransform || style.mozTransform
      mat = transform.match(/^matrix3d\((.+)\)$/)
      if mat
        return [parseFloat(mat[1].split(', ')[12]),parseFloat(mat[1].split(', ')[13])]
      mat = transform.match(/^matrix\((.+)\)$/)
      if mat
        return [parseFloat(mat[1].split(', ')[4]), parseFloat(mat[1].split(', ')[5])]
      else
        return [0, 0]

    onMouseDown: (event) ->
      unless @dragging
        if event.changedTouches? and event.changedTouches.length > 0
          @activeTouch = event.changedTouches[0].identifier
        else
          event.preventDefault()
        # Cache event coordinates.
        {clientX, clientY} = @getCoordinatesFromEvent(event)
        @fix = @ix = clientX
        @fiy = @iy = clientY
        [@offsetx, @offsety] = @getComputedTranslate(@element)
        @enableDrag()
        @callbackDragStart(event)

    onMouseMove: (event) ->
      {clientX, clientY} = @getCoordinatesFromEvent(event)
      @ix = clientX
      @iy = clientY
      for droppable in @droppables
        droppable.highlight this
      @callbackDragging(event)

    initialise: () ->
      @updateDimensions()
      # Configure Context Styles
      if @transform3DSupport then @accelerate(@element)
      style = window.getComputedStyle(@element)
      if style.getPropertyValue('position') is 'static'
        @element.style.position = 'relative'
      @start()

    start: () ->
      if !@started
        @started = yes
        @handle.addEventListener('mousedown', @onMouseDown)
        @handle.addEventListener('mouseup', @onMouseUp)
        @handle.addEventListener('touchstart', @onMouseDown)
        @handle.addEventListener('touchend', @onMouseUp)
        window.addEventListener('resize', @onWindowResize)

    stop: () ->
      if @started
        @started = no
        cancelAnimationFrame(@raf)
        @handle.removeEventListener('mousedown', @onMouseDown)
        @handle.removeEventListener('mouseup', @onMouseUp)
        @handle.removeEventListener('touchstart', @onMouseDown)
        @handle.removeEventListener('touchend', @onMouseUp)
        window.addEventListener('resize', @onWindowResize)

    updateDimensions: () ->
      @ww = window.innerWidth
      @wh = window.innerHeight
      @updateBounds()

    updateBounds: () ->
      @bounds = @element.parentNode.getBoundingClientRect()
      @ex = @bounds.left
      @ey = @bounds.top
      @ew = @bounds.width
      @eh = @bounds.height

    enableDrag: () ->
      if !@dragging
        @dragging = yes
        classie.add @element, @classDragging
        window.addEventListener('mousemove', @onMouseMove)
        window.addEventListener('touchmove', @onMouseMove)
        @raf = requestAnimationFrame(@onAnimationFrame)

    disableDrag: () ->
      if @dragging
        @dragging = no
        classie.remove @element, @classDragging
        window.removeEventListener('mousemove', @onMouseMove)
        window.removeEventListener('touchmove', @onMouseMove)

    css: (element, property, value) ->
      element.style[property] = value

    accelerate: (element) ->
      @css(element, @vendorPrefix.transform, 'translate3d(0,0,0)')

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
          touch = find event.touches, (touch) -> touch.identifier is self.activeTouch
          return {clientX: touch.clientX, clientY: touch.clientY}
      # The user is using a mouse
      else
        @getCoordinatesFromEvent = (event) ->
          {clientX: event.clientX, clientY: event.clientY}
      #Now that we have rewrite this function, call it again
      @getCoordinatesFromEvent event

    onMouseUp: (event) ->
      @activeTouch = null
      @disableDrag()
      cancelAnimationFrame(@raf)
      find = (arr, f) ->
        for e in arr when f e
          return e
        return
      self = this
      droppable = find @droppables, (droppable) -> droppable.isDroppable(self)
      @callbackDrop(event, droppable?)
      if droppable?
        droppable.accept(this)
      else
        @goBack()

    goBack: () ->
      @setPosition(@offsetx, @offsety)

    # Expose CirclesUI

    window[NAME] = Draggable

###
 * Droppable.coffee
 * @author Mathieu Dutour - @MathieuDutour
 * @description Drop an object
###
do (window, document) ->

  # Constants
  NAME = 'Droppable'
  DEFAULTS =
    percentageIn: 0.5
    precision: 1
    classDroppable: "is-droppable"
    classNotDroppable: "is-droppable"
    callbackDrop: () ->

  class Draggable
    constructor : (@element, options) ->
      # Data Extraction
      data =
        percentageIn: @data(@element, 'percentageIn')
        classDroppable: @data(@element, 'class-droppable')
        classNotDroppable: @data(@element, 'class-not-droppable')

      # Delete Null Data Values
      for key of data
        delete data[key] if data[key] is null

      # Compose Settings Object
      @extend(this, DEFAULTS, options, data);

      # Element Bounds
      @bounds = null
      @ex = 0
      @ey = 0
      @ew = 0
      @eh = 0

      # Callbacks
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

    getOffset: ( el ) ->
      offset = el.getBoundingClientRect()
      return {top: offset.top + @scrollY(),left: offset.left + @scrollX()}

    scrollX: () ->
      window.pageXOffset or window.document.documentElement.scrollLeft
    scrollY: () ->
      window.pageYOffset or window.document.documentElement.scrollTop

    isDroppable: ( draggable ) ->
      offset1 = getOffset( draggable.element )
      width1 = draggable.element.offsetWidth
      height1 = draggable.element.offsetHeight
      offset2 = getOffset( @element )

      !(offset2.left > offset1.left + width1 - width1 * @percentageIn or offset2.left + @width < offset1.left + width1 * @percentageIn or offset2.top > offset1.top + height1 - height1 * @percentageIn or offset2.top + @height < offset1.top + height1 * @percentageIn )

    initialise: () ->
      @updateDimensions()
      window.addEventListener('resize', @onWindowResize)

    updateDimensions: () ->
      @updateBounds()

    updateBounds: () ->
      @bounds = @element.parentNode.getBoundingClientRect()
      @ex = @bounds.left
      @ey = @bounds.top
      @ew = @bounds.width
      @eh = @bounds.height
      @width = @element.offsetWidth
      @height = @element.offsetHeight

    onWindowResize: (event) ->
      @updateDimensions()

    highlight: (draggable) ->
      if @isDroppable draggable
        classie.add @element, 'highlight'
      else
        classie.remove @element, 'highlight'

    collect: (draggable) ->
      classie.remove @element, 'highlight'
      @callbackDrop this, draggable

    # Expose CirclesUI

    window[NAME] = Droppable

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
