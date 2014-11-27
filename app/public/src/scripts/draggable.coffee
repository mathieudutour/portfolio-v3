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
    acceptDrop: () -> yes

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
      @setPosition(@ix, @iy)
      @raf = requestAnimationFrame(@onAnimationFrame)

    onMouseDown: (event) ->
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
        @callbackDragStart(event)

    onMouseMove: (event) ->
      {clientX, clientY} = @getCoordinatesFromEvent(event)
      @ix = clientX
      @iy = clientY
      @callbackDragging(event)

    initialise: () ->

      # Configure Context Styles
      if @transform3DSupport then @accelerate(@element)
      @start()

    start: () ->
      if !@started
        @started = yes
        @handle.addEventListener('mousedown', @onMouseDown)
        @handle.addEventListener('mouseup', @onMouseUp)
        @handle.addEventListener('touchstart', @onMouseDown)
        @handle.addEventListener('touchend', @onMouseUp)

    stop: () ->
      if @started
        @started = no
        cancelAnimationFrame(@raf)
        @handle.removeEventListener('mousedown', @onMouseDown)
        @handle.removeEventListener('mouseup', @onMouseUp)
        @handle.removeEventListener('touchstart', @onMouseDown)
        @handle.removeEventListener('touchend', @onMouseUp)

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
        @element.style.position = 'absolute'
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
          touch= find event.touches, (touch) -> touch.identifier is self.activeTouch
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
      @callbackDrop(event)

    # Expose CirclesUI

    window[NAME] = Draggable
