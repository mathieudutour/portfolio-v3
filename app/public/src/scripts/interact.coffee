###*
interact.js v1.1.2

Copyright (c) 2012, 2013, 2014 Taye Adeyemi <dev@taye.me>
Open source under the MIT License.
https://raw.github.com/taye/interact.js/master/LICENSE
###
(->
  # reduce object creation in getXY()
  # all set interactables
  # all interactions

  # {
  #      type: {
  #          selectors: ['selector', ...],
  #          contexts : [document, ...],
  #          listeners: [[listener, useCapture], ...]
  #      }
  #  }

  # no more than this number of actions can target the Interactable

  # no more than this number of actions can target the same
  # element of this Interactable simultaneously

  # aww snap
  # the item that is scrolled (Window or HTMLElement)
  # the scroll speed in pixels per second
  # the lambda in exponential decay
  # target speed must be above this for inertia to start
  # the speed at which inertia is slow enough to stop
  # allow resuming an action in inertia phase
  # if an action is resumed after launch, set dx/dy to 0
  # animate to snap/restrict endOnly if there's no inertia
  # allow inertia on these actions. gesture might not work
  # the Node on which querySelector will be called

  # Things related to autoScroll
  # the handle returned by window.setInterval
  # Direction each pulse is to scroll in

  # scroll the window by the values in scroll.x/y

  # change in time in seconds

  # displacement

  # set the autoScroll properties to those of the target

  # Does the browser support touch input?

  # Does the browser support PointerEvents

  # Less Precision with touch input

  # for ignoring taps from browser's simulated mouse events

  # Allow this many interactions to happen simultaneously

  # because Webkit and Opera still use 'mousewheel' event type

  # Opera Mobile must be handled differently

  # scrolling doesn't change the result of
  # getBoundingClientRect/getClientRects on iOS <=7 but it does on iOS 8

  # prefix matchesSelector

  # will be polyfill function if browser is IE8

  # native requestAnimationFrame or polyfill

  # used for adding event listeners to window and document

  # Events wrapper
  blank = ->
  isElement = (o) ->
    #DOM2
    !!o and (typeof o is "object") and ((if /object|function/.test(typeof Element) then o instanceof Element else o.nodeType is 1 and typeof o.nodeName is "string"))
  isObject = (thing) ->
    thing instanceof Object
  isArray = (thing) ->
    thing instanceof Array
  isFunction = (thing) ->
    typeof thing is "function"
  isNumber = (thing) ->
    typeof thing is "number"
  isBool = (thing) ->
    typeof thing is "boolean"
  isString = (thing) ->
    typeof thing is "string"
  trySelector = (value) ->
    return false  unless isString(value)

    # an exception will be raised if it is invalid
    document.querySelector value
    true
  extend = (dest, source) ->
    for prop of source
      dest[prop] = source[prop]
    dest
  copyCoords = (dest, src) ->
    dest.page = dest.page or {}
    dest.page.x = src.page.x
    dest.page.y = src.page.y
    dest.client = dest.client or {}
    dest.client.x = src.client.x
    dest.client.y = src.client.y
    dest.timeStamp = src.timeStamp
    return
  setEventXY = (targetObj, pointer, interaction) ->
    unless pointer
      if interaction.pointerIds.length > 1
        pointer = touchAverage(interaction.pointers)
      else
        pointer = interaction.pointers[0]
    getPageXY pointer, tmpXY, interaction
    targetObj.page.x = tmpXY.x
    targetObj.page.y = tmpXY.y
    getClientXY pointer, tmpXY, interaction
    targetObj.client.x = tmpXY.x
    targetObj.client.y = tmpXY.y
    targetObj.timeStamp = new Date().getTime()
    return
  setEventDeltas = (targetObj, prev, cur) ->
    targetObj.page.x = cur.page.x - prev.page.x
    targetObj.page.y = cur.page.y - prev.page.y
    targetObj.client.x = cur.client.x - prev.client.x
    targetObj.client.y = cur.client.y - prev.client.y
    targetObj.timeStamp = new Date().getTime() - prev.timeStamp

    # set pointer velocity
    dt = Math.max(targetObj.timeStamp / 1000, 0.001)
    targetObj.page.speed = hypot(targetObj.page.x, targetObj.page.y) / dt
    targetObj.page.vx = targetObj.page.x / dt
    targetObj.page.vy = targetObj.page.y / dt
    targetObj.client.speed = hypot(targetObj.client.x, targetObj.page.y) / dt
    targetObj.client.vx = targetObj.client.x / dt
    targetObj.client.vy = targetObj.client.y / dt
    return

  # Get specified X/Y coords for mouse or event.touches[0]
  getXY = (type, pointer, xy) ->
    xy = xy or {}
    type = type or "page"
    xy.x = pointer[type + "X"]
    xy.y = pointer[type + "Y"]
    xy
  getPageXY = (pointer, page, interaction) ->
    page = page or {}
    if pointer instanceof InteractEvent
      if /inertiastart/.test(pointer.type)
        interaction = interaction or pointer.interaction
        extend page, interaction.inertiaStatus.upCoords.page
        page.x += interaction.inertiaStatus.sx
        page.y += interaction.inertiaStatus.sy
      else
        page.x = pointer.pageX
        page.y = pointer.pageY

    # Opera Mobile handles the viewport and scrolling oddly
    else if isOperaMobile
      getXY "screen", pointer, page
      page.x += window.scrollX
      page.y += window.scrollY
    else
      getXY "page", pointer, page
    page
  getClientXY = (pointer, client, interaction) ->
    client = client or {}
    if pointer instanceof InteractEvent
      if /inertiastart/.test(pointer.type)
        extend client, interaction.inertiaStatus.upCoords.client
        client.x += interaction.inertiaStatus.sx
        client.y += interaction.inertiaStatus.sy
      else
        client.x = pointer.clientX
        client.y = pointer.clientY
    else

      # Opera Mobile handles the viewport and scrolling oddly
      getXY (if isOperaMobile then "screen" else "client"), pointer, client
    client
  getScrollXY = ->
    x: window.scrollX or document.documentElement.scrollLeft
    y: window.scrollY or document.documentElement.scrollTop
  getPointerId = (pointer) ->
    (if isNumber(pointer.pointerId) then pointer.pointerId else pointer.identifier)
  getActualElement = (element) ->
    (if element instanceof SVGElementInstance then element.correspondingUseElement else element)
  getElementRect = (element) ->
    scroll = if isIOS7orLower then {x: 0,y: 0} else getScrollXY()
    clientRect = (if (element instanceof SVGElement) then element.getBoundingClientRect() else element.getClientRects()[0])
    clientRect and
      left: clientRect.left + scroll.x
      right: clientRect.right + scroll.x
      top: clientRect.top + scroll.y
      bottom: clientRect.bottom + scroll.y
      width: clientRect.width or clientRect.right - clientRect.left
      height: clientRect.heigh or clientRect.bottom - clientRect.top
  getTouchPair = (event) ->
    touches = []

    # array of touches is supplied
    if isArray(event)
      touches[0] = event[0]
      touches[1] = event[1]

    # an event
    else
      if event.type is "touchend"
        if event.touches.length is 1
          touches[0] = event.touches[0]
          touches[1] = event.changedTouches[0]
        else if event.touches.length is 0
          touches[0] = event.changedTouches[0]
          touches[1] = event.changedTouches[1]
      else
        touches[0] = event.touches[0]
        touches[1] = event.touches[1]
    touches
  touchAverage = (event) ->
    touches = getTouchPair(event)
    pageX: (touches[0].pageX + touches[1].pageX) / 2
    pageY: (touches[0].pageY + touches[1].pageY) / 2
    clientX: (touches[0].clientX + touches[1].clientX) / 2
    clientY: (touches[0].clientY + touches[1].clientY) / 2
  touchBBox = (event) ->
    return  if not event.length and not (event.touches and event.touches.length > 1)
    touches = getTouchPair(event)
    minX = Math.min(touches[0].pageX, touches[1].pageX)
    minY = Math.min(touches[0].pageY, touches[1].pageY)
    maxX = Math.max(touches[0].pageX, touches[1].pageX)
    maxY = Math.max(touches[0].pageY, touches[1].pageY)
    x: minX
    y: minY
    left: minX
    top: minY
    width: maxX - minX
    height: maxY - minY
  touchDistance = (event, deltaSource) ->
    deltaSource = deltaSource or defaultOptions.deltaSource
    sourceX = deltaSource + "X"
    sourceY = deltaSource + "Y"
    touches = getTouchPair(event)
    dx = touches[0][sourceX] - touches[1][sourceX]
    dy = touches[0][sourceY] - touches[1][sourceY]
    hypot dx, dy
  touchAngle = (event, prevAngle, deltaSource) ->
    deltaSource = deltaSource or defaultOptions.deltaSource
    sourceX = deltaSource + "X"
    sourceY = deltaSource + "Y"
    touches = getTouchPair(event)
    dx = touches[0][sourceX] - touches[1][sourceX]
    dy = touches[0][sourceY] - touches[1][sourceY]
    angle = 180 * Math.atan(dy / dx) / Math.PI
    if isNumber(prevAngle)
      dr = angle - prevAngle
      drClamped = dr % 360
      if drClamped > 315
        angle -= 360 + (angle / 360) | 0 * 360
      else if drClamped > 135
        angle -= 180 + (angle / 360) | 0 * 360
      else if drClamped < -315
        angle += 360 + (angle / 360) | 0 * 360
      else angle += 180 + (angle / 360) | 0 * 360  if drClamped < -135
    angle
  getOriginXY = (interactable, element) ->
    origin = (if interactable then interactable.options.origin else defaultOptions.origin)
    if origin is "parent"
      origin = element.parentNode
    else if origin is "self"
      origin = interactable.getRect(element)
    else if trySelector(origin)
      origin = matchingParent(element, origin) or
        x: 0
        y: 0
    origin = origin(interactable and element)  if isFunction(origin)
    origin = getElementRect(origin)  if isElement(origin)
    origin.x = (if ("x" of origin) then origin.x else origin.left)
    origin.y = (if ("y" of origin) then origin.y else origin.top)
    origin

  # http://stackoverflow.com/a/5634528/2280888
  _getQBezierValue = (t, p1, p2, p3) ->
    iT = 1 - t
    iT * iT * p1 + 2 * iT * t * p2 + t * t * p3
  getQuadraticCurvePoint = (startX, startY, cpX, cpY, endX, endY, position) ->
    x: _getQBezierValue(position, startX, cpX, endX)
    y: _getQBezierValue(position, startY, cpY, endY)

  # http://gizma.com/easing/
  easeOutQuad = (t, b, c, d) ->
    t /= d
    -c * t * (t - 2) + b
  nodeContains = (parent, child) ->
    return true  if child is parent  while (child = child.parentNode)
    false
  matchingParent = (child, selector) ->
    parent = child.parentNode
    while isElement(parent)
      return parent  if matchesSelector(parent, selector)
      parent = parent.parentNode
    null
  inContext = (interactable, element) ->
    interactable._context is document or nodeContains(interactable._context, element)
  testIgnore = (interactable, interactableElement, element) ->
    ignoreFrom = interactable.options.ignoreFrom

    # limit test to the interactable's element and its children
    return false  if not ignoreFrom or not isElement(element) or element is interactableElement.parentNode
    if isString(ignoreFrom)
      return matchesSelector(element, ignoreFrom) or testIgnore(interactable, element.parentNode)
    else return element is ignoreFrom or nodeContains(ignoreFrom, element)  if isElement(ignoreFrom)
    false
  testAllow = (interactable, interactableElement, element) ->
    allowFrom = interactable.options.allowFrom
    return true  unless allowFrom

    # limit test to the interactable's element and its children
    return false  if not isElement(element) or element is interactableElement.parentNode
    if isString(allowFrom)
      return matchesSelector(element, allowFrom) or testAllow(interactable, element.parentNode)
    else return element is allowFrom or nodeContains(allowFrom, element)  if isElement(allowFrom)
    false
  checkAxis = (axis, interactable) ->
    return false  unless interactable
    thisAxis = interactable.options.dragAxis
    axis is "xy" or thisAxis is "xy" or thisAxis is axis
  checkSnap = (interactable, action) ->
    options = interactable.options
    action = "resize"  if /^resize/.test(action)
    action isnt "gesture" and options.snapEnabled and contains(options.snap.actions, action)
  checkRestrict = (interactable, action) ->
    options = interactable.options
    action = "resize"  if /^resize/.test(action)
    options.restrictEnabled and options.restrict[action]
  withinInteractionLimit = (interactable, element, action) ->
    action = (if /resize/.test(action) then "resize" else action)
    options = interactable.options
    maxActions = options[action + "Max"]
    maxPerElement = options[action + "MaxPerElement"]
    activeInteractions = 0
    targetCount = 0
    targetElementCount = 0
    i = 0
    len = interactions.length

    while i < len
      interaction = interactions[i]
      otherAction = (if /resize/.test(interaction.prepared) then "resize" else interaction.prepared)
      active = interaction.interacting()
      continue  unless active
      activeInteractions++
      return false  if activeInteractions >= maxInteractions
      continue  if interaction.target isnt interactable
      targetCount += (otherAction is action) | 0
      return false  if targetCount >= maxActions
      if interaction.element is element
        targetElementCount++
        return false  if otherAction isnt action or targetElementCount >= maxPerElement
      i++
    maxInteractions > 0

  # Test for the element that's "above" all other qualifiers
  indexOfDeepestElement = (elements) ->
    dropzone = undefined
    deepestZone = elements[0]
    index = (if deepestZone then 0 else -1)
    parent = undefined
    deepestZoneParents = []
    dropzoneParents = []
    child = undefined
    i = undefined
    n = undefined
    i = 1
    while i < elements.length
      dropzone = elements[i]

      # an element might belong to multiple selector dropzones
      continue  if not dropzone or dropzone is deepestZone
      unless deepestZone
        deepestZone = dropzone
        index = i
        continue

      # check if the deepest or current are document.documentElement or document.rootElement
      # - if the current dropzone is, do nothing and continue
      if dropzone.parentNode is document
        continue

      # - if deepest is, update with the current dropzone and continue to next
      else if deepestZone.parentNode is document
        deepestZone = dropzone
        index = i
        continue
      unless deepestZoneParents.length
        parent = deepestZone
        while parent.parentNode and parent.parentNode isnt document
          deepestZoneParents.unshift parent
          parent = parent.parentNode

      # if this element is an svg element and the current deepest is
      # an HTMLElement
      if deepestZone instanceof HTMLElement and dropzone instanceof SVGElement and (dropzone not instanceof SVGSVGElement)
        continue  if dropzone is deepestZone.parentNode
        parent = dropzone.ownerSVGElement
      else
        parent = dropzone
      dropzoneParents = []
      while parent.parentNode isnt document
        dropzoneParents.unshift parent
        parent = parent.parentNode
      n = 0

      # get (position of last common ancestor) + 1
      n++  while dropzoneParents[n] and dropzoneParents[n] is deepestZoneParents[n]
      parents = [
        dropzoneParents[n - 1]
        dropzoneParents[n]
        deepestZoneParents[n]
      ]
      child = parents[0].lastChild
      while child
        if child is parents[1]
          deepestZone = dropzone
          index = i
          deepestZoneParents = []
          break
        else break  if child is parents[2]
        child = child.previousSibling
      i++
    index
  Interaction = ->
    @target = null # current interactable being interacted with
    @element = null # the target element of the interactable
    @dropTarget = null # the dropzone a drag target might be dropped into
    @dropElement = null # the element at the time of checking
    @prevDropTarget = null # the dropzone that was recently dragged away from
    @prevDropElement = null # the element at the time of checking
    @prepared = null # Action that's ready to be fired on next move event
    @matches = [] # all selectors that are matched by target element
    @matchElements = [] # corresponding elements
    @inertiaStatus =
      active: false
      smoothEnd: false
      startEvent: null
      upCoords: {}
      xe: 0
      ye: 0
      sx: 0
      sy: 0
      t0: 0
      vx0: 0
      vys: 0
      duration: 0
      resumeDx: 0
      resumeDy: 0
      lambda_v0: 0
      one_ve_v0: 0
      i: null

    if isFunction(Function::bind)
      @boundInertiaFrame = @inertiaFrame.bind(this)
      @boundSmoothEndFrame = @smoothEndFrame.bind(this)
    else
      that = this
      @boundInertiaFrame = ->
        that.inertiaFrame()

      @boundSmoothEndFrame = ->
        that.smoothEndFrame()
    @activeDrops =
      dropzones: [] # the dropzones that are mentioned below
      elements: [] # elements of dropzones that accept the target draggable
      rects: [] # the rects of the elements mentioned above


    # keep track of added pointers
    @pointers = []
    @pointerIds = []

    # Previous native pointer move event coordinates
    @prevCoords =
      page:
        x: 0
        y: 0

      client:
        x: 0
        y: 0

      timeStamp: 0


    # current native pointer move event coordinates
    @curCoords =
      page:
        x: 0
        y: 0

      client:
        x: 0
        y: 0

      timeStamp: 0


    # Starting InteractEvent pointer coordinates
    @startCoords =
      page:
        x: 0
        y: 0

      client:
        x: 0
        y: 0

      timeStamp: 0


    # Change in coordinates and time of the pointer
    @pointerDelta =
      page:
        x: 0
        y: 0
        vx: 0
        vy: 0
        speed: 0

      client:
        x: 0
        y: 0
        vx: 0
        vy: 0
        speed: 0

      timeStamp: 0

    @downTime = 0 # the timeStamp of the starting event
    @downEvent = null # pointerdown/mousedown/touchstart event
    @downPointer = {}
    @downTarget = null
    @prevEvent = null # previous action event
    @tapTime = 0 # time of the most recent tap event
    @prevTap = null
    @startOffset =
      left: 0
      right: 0
      top: 0
      bottom: 0

    @restrictOffset =
      left: 0
      right: 0
      top: 0
      bottom: 0

    @snapOffset =
      x: 0
      y: 0

    @gesture =
      start:
        x: 0
        y: 0

      startDistance: 0 # distance between two touches of touchStart
      prevDistance: 0
      distance: 0
      scale: 1 # gesture.distance / gesture.startDistance
      startAngle: 0 # angle of line joining two touches
      prevAngle: 0 # angle of the previous gesture event

    @snapStatus =
      x: 0
      y: 0
      dx: 0
      dy: 0
      realX: 0
      realY: 0
      snappedX: 0
      snappedY: 0
      anchors: []
      paths: []
      locked: false
      changed: false

    @restrictStatus =
      dx: 0
      dy: 0
      restrictedX: 0
      restrictedY: 0
      snap: null
      restricted: false
      changed: false

    @restrictStatus.snap = @snapStatus
    @pointerIsDown = false
    @pointerWasMoved = false
    @gesturing = false
    @dragging = false
    @resizing = false
    @resizeAxes = "xy"
    @mouse = false
    interactions.push this
    return

  # if the eventTarget should be ignored or shouldn't be allowed
  # clear the previous target

  # Check what action would be performed on pointerMove target if a mouse
  # button were pressed and change the cursor accordingly

  # update pointer coords for defaultActionChecker to use

  # Remove temporary event listeners for selector Interactables

  # Check if the down event hits the current inertia target

  # climb up the DOM tree from the event target

  # if this element is the current inertia target element

  # and the prospective action is the same as the ongoing one

  # stop inertia so that the next move will be a normal one

  # do nothing if interacting

  # update pointer coords for defaultActionChecker to use

  # do these now since pointerDown isn't being called from here

  # Determine action to be performed on next pointerMove and add appropriate
  # style and event Liseners

  # If it is the second touch of a multi-touch gesture, keep the target
  # the same if a target was set by the first touch
  # Otherwise, set the target if there is no action prepared

  # if inertia is active try to resume action

  # set pointer coordinate, time changes and speeds

  # register movement of more than 1 pixel

  # ignore movement while inertia is active

  # if just starting an action, calculate the pointer speed now

  # check if a drag is in the correct axis

  # if the movement isn't in the axis of the interactable

  # cancel the prepared action

  # then try to get a drag from another ineractable

  # check element interactables

  # if there's no drag from element interactables,
  # check the selector interactables

  # move if snapping or restriction doesn't prevent it

  # reset active dropzones

  # set snapping and restriction for the move event

  # End interact move events and stop auto-scroll unless inertia is enabled
  #options.dragAxis === 'xy'

  # check if inertia should be started

  # fire a move event at the snapped coordinates

  # collect all dropzones and their elements which qualify for a drop

  # test the draggable element against the dropzone's accept setting

  # query for new elements if necessary

  # loop through all active dropzones and trigger event

  # prevent trigger of duplicate events on same element

  # set current element as event target

  # Collect a new set of possible drops and save them in activeDrops.
  # setActiveDrops should always be called when a drag has just started or a
  # drag event happens while dynamicDrop is true

  # get dropzones and their elements that could recieve the draggable

  # collect all dropzones and their elements which qualify for a drop

  # get the most apprpriate dropzone based on DOM depth and order

  # if there was a prevDropTarget, create a dragleave event

  # if the dropTarget is not null, create a dragenter event

  # prevent Default only if were previously interacting

  # pointers should be retained
  #this.pointers.splice(0);

  # delete interaction if it's not the only one

  # move events are kept so that multi-touch properties can still be
  # calculated at the end of a gesture; use pointerIds index

  # move events are kept so that multi-touch properties can still be
  # calculated at the end of a GestureEvnt sequence
  #this.pointers.splice(index, 1);

  # Do not update pointers while inertia is active.
  # The inertiastart event should be this.pointers[0]

  # change to infinite range when range is negative

  # create an anchor representative for each path's returned point

  # Infinite anchors count as being out of range
  # compared to non infinite ones that are in range

  # is the closest anchor in range?

  # the pointer is relatively deeper in this anchor

  #the pointer is closer to this anchor

  # The other is not in range and the pointer is closer to this anchor

  # object is assumed to have
  # x, y, width, height or
  # left, top, right, bottom

  # do not preventDefault on pointerdown if the prepared action is a drag
  # and dragging can only start from a certain direction - this allows
  # a touch to pan the viewport if a drag isn't in the right direction
  getInteractionFromPointer = (pointer, eventType, eventTarget) ->
    i = 0
    len = interactions.length

    # MSPointerEvent.MSPOINTER_TYPE_MOUSE
    mouseEvent = (/mouse/i.test(pointer.pointerType or eventType) or pointer.pointerType is 4)
    interaction = undefined
    id = getPointerId(pointer)

    # try to resume inertia with a new pointer
    if /down|start/i.test(eventType)
      i = 0
      while i < len
        interaction = interactions[i]
        element = eventTarget
        if interaction.inertiaStatus.active and (interaction.mouse is mouseEvent)
          while element

            # if the element is the interaction element
            if element is interaction.element

              # update the interaction's pointer
              interaction.removePointer interaction.pointers[0]
              interaction.addPointer pointer
              return interaction
            element = element.parentNode
        i++

    # if it's a mouse interaction
    if mouseEvent or not (supportsTouch or supportsPointerEvent)

      # find a mouse interaction that's not in inertia phase
      i = 0
      while i < len
        return interactions[i]  if interactions[i].mouse and not interactions[i].inertiaStatus.active
        i++

      # find any interaction specifically for mouse.
      # if the eventType is a mousedown, and inertia is active
      # ignore the interaction
      i = 0
      while i < len
        return interaction  if interactions[i].mouse and not (/down/.test(eventType) and interactions[i].inertiaStatus.active)
        i++

      # create a new interaction for mouse
      interaction = new Interaction()
      interaction.mouse = true
      return interaction

    # get interaction that has this pointer
    i = 0
    while i < len
      return interactions[i]  if contains(interactions[i].pointerIds, id)
      i++

    # at this stage, a pointerUp should not return an interaction
    return null  if /up|end|out/i.test(eventType)

    # get first idle interaction
    i = 0
    while i < len
      interaction = interactions[i]
      if (not interaction.prepared or (interaction.target.gesturable())) and not interaction.interacting() and not (not mouseEvent and interaction.mouse)
        interaction.addPointer pointer
        return interaction
      i++
    new Interaction()
  doOnInteractions = (method) ->
    (event) ->
      interaction = undefined
      eventTarget = getActualElement(event.target)
      curEventTarget = getActualElement(event.currentTarget)
      i = undefined
      if supportsTouch and /touch/.test(event.type)
        i = 0
        while i < event.changedTouches.length
          pointer = event.changedTouches[i]
          interaction = getInteractionFromPointer(pointer, event.type, eventTarget)
          continue  unless interaction
          interaction[method] pointer, event, eventTarget, curEventTarget
          i++
      else

        # ignore mouse events while touch interactions are active
        if not supportsPointerEvent and /mouse/.test(event.type)
          i = 0
          while i < interactions.length
            return  if not interactions[i].mouse and interactions[i].pointerIsDown
            i++
        interaction = getInteractionFromPointer(event, event.type, eventTarget)
        return  unless interaction
        interaction[method] event, event, eventTarget, curEventTarget
      return
  InteractEvent = (interaction, event, action, phase, element, related) ->
    client = undefined
    page = undefined
    target = interaction.target
    snapStatus = interaction.snapStatus
    restrictStatus = interaction.restrictStatus
    pointers = interaction.pointers
    deltaSource = (target and target.options or defaultOptions).deltaSource
    sourceX = deltaSource + "X"
    sourceY = deltaSource + "Y"
    options = (if target then target.options else defaultOptions)
    origin = getOriginXY(target, element)
    starting = phase is "start"
    ending = phase is "end"
    coords = (if starting then interaction.startCoords else interaction.curCoords)
    element = element or interaction.element
    page = extend({}, coords.page)
    client = extend({}, coords.client)
    page.x -= origin.x
    page.y -= origin.y
    client.x -= origin.x
    client.y -= origin.y
    if checkSnap(target, action) and not (starting and options.snap.elementOrigin)
      @snap =
        range: snapStatus.range
        locked: snapStatus.locked
        x: snapStatus.snappedX
        y: snapStatus.snappedY
        realX: snapStatus.realX
        realY: snapStatus.realY
        dx: snapStatus.dx
        dy: snapStatus.dy

      if snapStatus.locked
        page.x += snapStatus.dx
        page.y += snapStatus.dy
        client.x += snapStatus.dx
        client.y += snapStatus.dy
    if checkRestrict(target, action) and not (starting and options.restrict.elementRect) and restrictStatus.restricted
      page.x += restrictStatus.dx
      page.y += restrictStatus.dy
      client.x += restrictStatus.dx
      client.y += restrictStatus.dy
      @restrict =
        dx: restrictStatus.dx
        dy: restrictStatus.dy
    @pageX = page.x
    @pageY = page.y
    @clientX = client.x
    @clientY = client.y
    @x0 = interaction.startCoords.page.x
    @y0 = interaction.startCoords.page.y
    @clientX0 = interaction.startCoords.client.x
    @clientY0 = interaction.startCoords.client.y
    @ctrlKey = event.ctrlKey
    @altKey = event.altKey
    @shiftKey = event.shiftKey
    @metaKey = event.metaKey
    @button = event.button
    @target = element
    @t0 = interaction.downTime
    @type = action + (phase or "")
    @interaction = interaction
    @interactable = target
    inertiaStatus = interaction.inertiaStatus
    @detail = "inertia"  if inertiaStatus.active
    @relatedTarget = related  if related

    # end event dx, dy is difference between start and end points
    if ending or action is "drop"
      if deltaSource is "client"
        @dx = client.x - interaction.startCoords.client.x
        @dy = client.y - interaction.startCoords.client.y
      else
        @dx = page.x - interaction.startCoords.page.x
        @dy = page.y - interaction.startCoords.page.y
    else if starting
      @dx = 0
      @dy = 0

    # copy properties from previousmove if starting inertia
    else if phase is "inertiastart"
      @dx = interaction.prevEvent.dx
      @dy = interaction.prevEvent.dy
    else
      if deltaSource is "client"
        @dx = client.x - interaction.prevEvent.clientX
        @dy = client.y - interaction.prevEvent.clientY
      else
        @dx = page.x - interaction.prevEvent.pageX
        @dy = page.y - interaction.prevEvent.pageY
    if interaction.prevEvent and interaction.prevEvent.detail is "inertia" and not inertiaStatus.active and options.inertia.zeroResumeDelta
      inertiaStatus.resumeDx += @dx
      inertiaStatus.resumeDy += @dy
      @dx = @dy = 0
    if action is "resize"
      if options.squareResize or event.shiftKey
        if interaction.resizeAxes is "y"
          @dx = @dy
        else
          @dy = @dx
        @axes = "xy"
      else
        @axes = interaction.resizeAxes
        if interaction.resizeAxes is "x"
          @dy = 0
        else @dx = 0  if interaction.resizeAxes is "y"
    else if action is "gesture"
      @touches = [
        pointers[0]
        pointers[1]
      ]
      if starting
        @distance = touchDistance(pointers, deltaSource)
        @box = touchBBox(pointers)
        @scale = 1
        @ds = 0
        @angle = touchAngle(pointers, 'undefined', deltaSource)
        @da = 0
      else if ending or event instanceof InteractEvent
        @distance = interaction.prevEvent.distance
        @box = interaction.prevEvent.box
        @scale = interaction.prevEvent.scale
        @ds = @scale - 1
        @angle = interaction.prevEvent.angle
        @da = @angle - interaction.gesture.startAngle
      else
        @distance = touchDistance(pointers, deltaSource)
        @box = touchBBox(pointers)
        @scale = @distance / interaction.gesture.startDistance
        @angle = touchAngle(pointers, interaction.gesture.prevAngle, deltaSource)
        @ds = @scale - interaction.gesture.prevScale
        @da = @angle - interaction.gesture.prevAngle
    if starting
      @timeStamp = interaction.downTime
      @dt = 0
      @duration = 0
      @speed = 0
      @velocityX = 0
      @velocityY = 0
    else if phase is "inertiastart"
      @timeStamp = interaction.prevEvent.timeStamp
      @dt = interaction.prevEvent.dt
      @duration = interaction.prevEvent.duration
      @speed = interaction.prevEvent.speed
      @velocityX = interaction.prevEvent.velocityX
      @velocityY = interaction.prevEvent.velocityY
    else
      @timeStamp = new Date().getTime()
      @dt = @timeStamp - interaction.prevEvent.timeStamp
      @duration = @timeStamp - interaction.downTime
      if event instanceof InteractEvent
        dx = this[sourceX] - interaction.prevEvent[sourceX]
        dy = this[sourceY] - interaction.prevEvent[sourceY]
        dt = @dt / 1000
        @speed = hypot(dx, dy) / dt
        @velocityX = dx / dt
        @velocityY = dy / dt

      # if normal move or end event, use previous user event coords
      else

        # speed and velocity in pixels per second
        @speed = interaction.pointerDelta[deltaSource].speed
        @velocityX = interaction.pointerDelta[deltaSource].vx
        @velocityY = interaction.pointerDelta[deltaSource].vy
    if (ending or phase is "inertiastart") and interaction.prevEvent.speed > 600 and @timeStamp - interaction.prevEvent.timeStamp < 150
      angle = 180 * Math.atan2(interaction.prevEvent.velocityY, interaction.prevEvent.velocityX) / Math.PI
      overlap = 22.5
      angle += 360  if angle < 0
      left = 135 - overlap <= angle and angle < 225 + overlap
      up = 225 - overlap <= angle and angle < 315 + overlap
      right = not left and (315 - overlap <= angle or angle < 45 + overlap)
      down = not up and 45 - overlap <= angle and angle < 135 + overlap
      @swipe =
        up: up
        down: down
        left: left
        right: right
        angle: angle
        speed: interaction.prevEvent.speed
        velocity:
          x: interaction.prevEvent.velocityX
          y: interaction.prevEvent.velocityY
    return
  preventOriginalDefault = ->
    @originalEvent.preventDefault()
    return
  defaultActionChecker = (pointer, interaction, element) ->
    rect = @getRect(element)
    right = undefined
    bottom = undefined
    action = null
    page = extend({}, interaction.curCoords.page)
    options = @options
    return null  unless rect
    if actionIsEnabled.resize and options.resizable
      right = options.resizeAxis isnt "y" and page.x > (rect.right - margin)
      bottom = options.resizeAxis isnt "x" and page.y > (rect.bottom - margin)
    interaction.resizeAxes = ((if right then "x" else "")) + ((if bottom then "y" else ""))
    action = (if (interaction.resizeAxes) then "resize" + interaction.resizeAxes else (if actionIsEnabled.drag and options.draggable then "drag" else null))
    action = "gesture"  if actionIsEnabled.gesture and interaction.pointerIds.length >= 2 and not (interaction.dragging or interaction.resizing)
    action

  # Check if action is enabled globally and the current target supports it
  # If so, return the validated action. Otherwise, return null
  validateAction = (action, interactable) ->
    return null  unless isString(action)
    actionType = (if action.search("resize") isnt -1 then "resize" else action)
    options = interactable
    if ((actionType is "resize" and options.resizable) or (action is "drag" and options.draggable) or (action is "gesture" and options.gesturable)) and actionIsEnabled[actionType]
      action = "resizexy"  if action is "resize" or action is "resizeyx"
      return action
    null

  # bound to the interactable context when a DOM event
  # listener is added to a selector interactable
  delegateListener = (event, useCapture) ->
    fakeEvent = {}
    delegated = delegatedEvents[event.type]
    element = event.target
    useCapture = (if useCapture then true else false)

    # duplicate the event so that currentTarget can be changed
    for prop of event
      fakeEvent[prop] = event[prop]
    fakeEvent.originalEvent = event
    fakeEvent.preventDefault = preventOriginalDefault

    # climb up document tree looking for selector matches
    while element and element isnt document
      i = 0

      while i < delegated.selectors.length
        selector = delegated.selectors[i]
        context = delegated.contexts[i]
        if matchesSelector(element, selector) and context is event.currentTarget and nodeContains(context, element)
          listeners = delegated.listeners[i]
          fakeEvent.currentTarget = element
          j = 0

          while j < listeners.length
            listeners[j][0] fakeEvent  if listeners[j][1] is useCapture
            j++
        i++
      element = element.parentNode
    return
  delegateUseCapture = (event) ->
    delegateListener.call this, event, true

  #\
  #     * interact
  #     [ method ]
  #     *
  #     * The methods of this variable can be used to set elements as
  #     * interactables and also to change various default settings.
  #     *
  #     * Calling it as a function and passing an element or a valid CSS selector
  #     * string returns an Interactable object which has various methods to
  #     * configure it.
  #     *
  #     - element (Element | string) The HTML or SVG Element to interact with or CSS selector
  #     = (object) An @Interactable
  #     *
  #     > Usage
  #     | interact(document.getElementById('draggable')).draggable(true);
  #     |
  #     | var rectables = interact('rect');
  #     | rectables
  #     |     .gesturable(true)
  #     |     .on('gesturemove', function (event) {
  #     |         // something cool...
  #     |     })
  #     |     .autoScroll(true);
  #    \
  interact = (element, options) ->
    interactables.get(element, options) or new Interactable(element, options)

  # A class for easy inheritance and setting of an Interactable's options
  IOptions = (options) ->
    for option of defaultOptions
      this[option] = options[option]  if options.hasOwnProperty(option) and typeof options[option] is typeof defaultOptions[option]
    return

  #\
  #     * Interactable
  #     [ property ]
  #     **
  #     * Object type returned by @interact
  #    \
  Interactable = (element, options) ->
    @_element = element
    @_iEvents = @_iEvents or {}
    if trySelector(element)
      @selector = element
      @_context = options.context  if options and options.context and ((if window.Node then options.context instanceof window.Node else (isElement(options.context) or options.context is document)))
    else if isElement(element)
      if PointerEvent
        events.add this, pEventTypes.down, listeners.pointerDown
        events.add this, pEventTypes.move, listeners.pointerHover
      else
        events.add this, "mousedown", listeners.pointerDown
        events.add this, "mousemove", listeners.pointerHover
        events.add this, "touchstart", listeners.pointerDown
        events.add this, "touchmove", listeners.pointerHover
    interactables.push this
    @set options
    return

  #\
  #         * Interactable.draggable
  #         [ method ]
  #         *
  #         * Gets or sets whether drag actions can be performed on the
  #         * Interactable
  #         *
  #         = (boolean) Indicates if this can be the target of drag events
  #         | var isDraggable = interact('ul li').draggable();
  #         * or
  #         - options (boolean | object) #optional true/false or An object with event listeners to be fired on drag events (object makes the Interactable draggable)
  #         = (object) This Interactable
  #         | interact(element).draggable({
  #         |     onstart: function (event) {},
  #         |     onmove : function (event) {},
  #         |     onend  : function (event) {},
  #         |
  #         |     // the axis in which the first movement must be
  #         |     // for the drag sequence to start
  #         |     // 'xy' by default - any direction
  #         |     axis: 'x' || 'y' || 'xy',
  #         |
  #         |     // max number of drags that can happen concurrently
  #         |     // with elements of this Interactable. 1 by default
  #         |     max: Infinity,
  #         |
  #         |     // max number of drags that can target the same element
  #         |     // 1 by default
  #         |     maxPerElement: 2
  #         | });
  #        \

  #\
  #         * Interactable.dropzone
  #         [ method ]
  #         *
  #         * Returns or sets whether elements can be dropped onto this
  #         * Interactable to trigger drop events
  #         *
  #         * Dropzones can recieve the following events:
  #         *  - 'dragactivate' and 'dragdeactivate' when an acceptable drag starts and ends
  #         *  - 'dragenter' and 'dragleave' when a draggable enters and leaves the dropzone
  #         *  - 'drop' when a draggable is dropped into this dropzone
  #         *
  #         *  Use the 'accept' option to allow only elements that match the given CSS selector or element.
  #         *
  #         *  Use the 'overlap' option to set how drops are checked for. The allowed values are:
  #         *   - ''pointer'', the pointer must be over the dropzone (default)
  #         *   - ''center'', the draggable element's center must be over the dropzone
  #         *   - a number from 0-1 which is the '(intersetion area) / (draggable area)'.
  #         *       e.g. '0.5' for drop to happen when half of the area of the
  #         *       draggable is over the dropzone
  #         *
  #         - options (boolean | object | null) #optional The new value to be set.
  #         | interact('.drop').dropzone({
  #         |   accept: '.can-drop' || document.getElementById('single-drop'),
  #         |   overlap: 'pointer' || 'center' || zeroToOne
  #         | }
  #         = (boolean | object) The current setting or this Interactable
  #        \

  #\
  #         * Interactable.dropCheck
  #         [ method ]
  #         *
  #         * The default function to determine if a dragend event occured over
  #         * this Interactable's element. Can be overridden using
  #         * @Interactable.dropChecker.
  #         *
  #         - pointer (MouseEvent | PointerEvent | Touch) The event that ends a drag
  #         - draggable (Interactable) The Interactable being dragged
  #         - draggableElement (ELement) The actual element that's being dragged
  #         - dropElement (Element) The dropzone element
  #         - rect (object) #optional The rect of dropElement
  #         = (boolean) whether the pointer was over this Interactable
  #        \

  #\
  #         * Interactable.dropChecker
  #         [ method ]
  #         *
  #         * Gets or sets the function used to check if a dragged element is
  #         * over this Interactable. See @Interactable.dropCheck.
  #         *
  #         - checker (function) #optional
  #         * The checker is a function which takes a mouseUp/touchEnd event as a
  #         * parameter and returns true or false to indicate if the the current
  #         * draggable can be dropped into this Interactable
  #         *
  #         = (Function | Interactable) The checker function or this Interactable
  #        \

  #\
  #         * Interactable.accept
  #         [ method ]
  #         *
  #         * Gets or sets the Element or CSS selector match that this
  #         * Interactable accepts if it is a dropzone.
  #         *
  #         - newValue (Element | string | null) #optional
  #         * If it is an Element, then only that element can be dropped into this dropzone.
  #         * If it is a string, the element being dragged must match it as a selector.
  #         * If it is null, the accept options is cleared - it accepts any element.
  #         *
  #         = (string | Element | null | Interactable) The current accept option if given 'undefined' or this Interactable
  #        \

  # test if it is a valid CSS selector

  #\
  #         * Interactable.resizable
  #         [ method ]
  #         *
  #         * Gets or sets whether resize actions can be performed on the
  #         * Interactable
  #         *
  #         = (boolean) Indicates if this can be the target of resize elements
  #         | var isResizeable = interact('input[type=text]').resizable();
  #         * or
  #         - options (boolean | object) #optional true/false or An object with event listeners to be fired on resize events (object makes the Interactable resizable)
  #         = (object) This Interactable
  #         | interact(element).resizable({
  #         |     onstart: function (event) {},
  #         |     onmove : function (event) {},
  #         |     onend  : function (event) {},
  #         |
  #         |     axis   : 'x' || 'y' || 'xy' // default is 'xy',
  #         |
  #         |     // limit multiple resizes.
  #         |     // See the explanation in @Interactable.draggable example
  #         |     max: 1,
  #         |     maxPerElement: 1,
  #         | });
  #        \

  # misspelled alias

  #\
  #         * Interactable.squareResize
  #         [ method ]
  #         *
  #         * Gets or sets whether resizing is forced 1:1 aspect
  #         *
  #         = (boolean) Current setting
  #         *
  #         * or
  #         *
  #         - newValue (boolean) #optional
  #         = (object) this Interactable
  #        \

  #\
  #         * Interactable.gesturable
  #         [ method ]
  #         *
  #         * Gets or sets whether multitouch gestures can be performed on the
  #         * Interactable's element
  #         *
  #         = (boolean) Indicates if this can be the target of gesture events
  #         | var isGestureable = interact(element).gesturable();
  #         * or
  #         - options (boolean | object) #optional true/false or An object with event listeners to be fired on gesture events (makes the Interactable gesturable)
  #         = (object) this Interactable
  #         | interact(element).gesturable({
  #         |     onstart: function (event) {},
  #         |     onmove : function (event) {},
  #         |     onend  : function (event) {},
  #         |
  #         |     // limit multiple gestures.
  #         |     // See the explanation in @Interactable.draggable example
  #         |     max: 1,
  #         |     maxPerElement: 1,
  #         | });
  #        \

  # misspelled alias

  #\
  #         * Interactable.autoScroll
  #         [ method ]
  #         *
  #         * Returns or sets whether or not any actions near the edges of the
  #         * window/container trigger autoScroll for this Interactable
  #         *
  #         = (boolean | object)
  #         * 'false' if autoScroll is disabled; object with autoScroll properties
  #         * if autoScroll is enabled
  #         *
  #         * or
  #         *
  #         - options (object | boolean | null) #optional
  #         * options can be:
  #         * - an object with margin, distance and interval properties,
  #         * - true or false to enable or disable autoScroll or
  #         * - null to use default settings
  #         = (Interactable) this Interactable
  #        \

  #\
  #         * Interactable.snap
  #         [ method ]
  #         **
  #         * Returns or sets if and how action coordinates are snapped. By
  #         * default, snapping is relative to the pointer coordinates. You can
  #         * change this by setting the
  #         * ['elementOrigin'](https://github.com/taye/interact.js/pull/72).
  #         **
  #         = (boolean | object) 'false' if snap is disabled; object with snap properties if snap is enabled
  #         **
  #         * or
  #         **
  #         - options (object | boolean | null) #optional
  #         = (Interactable) this Interactable
  #         > Usage
  #         | interact('.handle').snap({
  #         |     mode        : 'grid',                // event coords should snap to the corners of a grid
  #         |     range       : Infinity,              // the effective distance of snap ponts
  #         |     grid        : { x: 100, y: 100 },    // the x and y spacing of the grid points
  #         |     gridOffset  : { x:   0, y:   0 },    // the offset of the grid points
  #         | });
  #         |
  #         | interact('.handle').snap({
  #         |     mode        : 'anchor',              // snap to specified points
  #         |     anchors     : [
  #         |         { x: 100, y: 100, range: 25 },   // a point with x, y and a specific range
  #         |         { x: 200, y: 200 }               // a point with x and y. it uses the default range
  #         |     ]
  #         | });
  #         |
  #         | interact(document.querySelector('#thing')).snap({
  #         |     mode : 'path',
  #         |     paths: [
  #         |         {            // snap to points on these x and y axes
  #         |             x: 100,
  #         |             y: 100,
  #         |             range: 25
  #         |         },
  #         |         // give this function the x and y page coords and snap to the object returned
  #         |         function (x, y) {
  #         |             return {
  #         |                 x: x,
  #         |                 y: (75 + 50 * Math.sin(x * 0.04)),
  #         |                 range: 40
  #         |             };
  #         |         }]
  #         | })
  #         |
  #         | interact(element).snap({
  #         |     // do not snap during normal movement.
  #         |     // Instead, trigger only one snapped move event
  #         |     // immediately before the end event.
  #         |     endOnly: true,
  #         |
  #         |     // https://github.com/taye/interact.js/pull/72#issue-41813493
  #         |     elementOrigin: { x: 0, y: 0 }
  #         | });
  #        \

  #\
  #         * Interactable.inertia
  #         [ method ]
  #         **
  #         * Returns or sets if and how events continue to run after the pointer is released
  #         **
  #         = (boolean | object) 'false' if inertia is disabled; 'object' with inertia properties if inertia is enabled
  #         **
  #         * or
  #         **
  #         - options (object | boolean | null) #optional
  #         = (Interactable) this Interactable
  #         > Usage
  #         | // enable and use default settings
  #         | interact(element).inertia(true);
  #         |
  #         | // enable and use custom settings
  #         | interact(element).inertia({
  #         |     // value greater than 0
  #         |     // high values slow the object down more quickly
  #         |     resistance     : 16,
  #         |
  #         |     // the minimum launch speed (pixels per second) that results in inertiastart
  #         |     minSpeed       : 200,
  #         |
  #         |     // inertia will stop when the object slows down to this speed
  #         |     endSpeed       : 20,
  #         |
  #         |     // boolean; should actions be resumed when the pointer goes down during inertia
  #         |     allowResume    : true,
  #         |
  #         |     // boolean; should the jump when resuming from inertia be ignored in event.dx/dy
  #         |     zeroResumeDelta: false,
  #         |
  #         |     // if snap/restrict are set to be endOnly and inertia is enabled, releasing
  #         |     // the pointer without triggering inertia will animate from the release
  #         |     // point to the snaped/restricted point in the given amount of time (ms)
  #         |     smoothEndDuration: 300,
  #         |
  #         |     // an array of action types that can have inertia (no gesture)
  #         |     actions        : ['drag', 'resize']
  #         | });
  #         |
  #         | // reset custom settings and use all defaults
  #         | interact(element).inertia(null);
  #        \

  #\
  #         * Interactable.actionChecker
  #         [ method ]
  #         *
  #         * Gets or sets the function used to check action to be performed on
  #         * pointerDown
  #         *
  #         - checker (function | null) #optional A function which takes a pointer event, defaultAction string and an interactable as parameters and returns 'drag' 'resize[axes]' or 'gesture' or null.
  #         = (Function | Interactable) The checker function or this Interactable
  #        \

  #\
  #         * Interactable.getRect
  #         [ method ]
  #         *
  #         * The default function to get an Interactables bounding rect. Can be
  #         * overridden using @Interactable.rectChecker.
  #         *
  #         - element (Element) #optional The element to measure. Meant to be used for selector Interactables which don't have a specific element.
  #         = (object) The object's bounding rectangle.
  #         o {
  #         o     top   : 0,
  #         o     left  : 0,
  #         o     bottom: 0,
  #         o     right : 0,
  #         o     width : 0,
  #         o     height: 0
  #         o }
  #        \

  #\
  #         * Interactable.rectChecker
  #         [ method ]
  #         *
  #         * Returns or sets the function used to calculate the interactable's
  #         * element's rectangle
  #         *
  #         - checker (function) #optional A function which returns this Interactable's bounding rectangle. See @Interactable.getRect
  #         = (function | object) The checker function or this Interactable
  #        \

  #\
  #         * Interactable.styleCursor
  #         [ method ]
  #         *
  #         * Returns or sets whether the action that would be performed when the
  #         * mouse on the element are checked on 'mousemove' so that the cursor
  #         * may be styled appropriately
  #         *
  #         - newValue (boolean) #optional
  #         = (boolean | Interactable) The current setting or this Interactable
  #        \

  #\
  #         * Interactable.preventDefault
  #         [ method ]
  #         *
  #         * Returns or sets whether to prevent the browser's default behaviour
  #         * in response to pointer events. Can be set to
  #         *  - 'true' to always prevent
  #         *  - 'false' to never prevent
  #         *  - ''auto'' to allow interact.js to try to guess what would be best
  #         *  - 'null' to set to the default ('auto')
  #         *
  #         - newValue (boolean | string | null) #optional 'true', 'false' or ''auto''
  #         = (boolean | string | Interactable) The current setting or this Interactable
  #        \

  #\
  #         * Interactable.origin
  #         [ method ]
  #         *
  #         * Gets or sets the origin of the Interactable's element.  The x and y
  #         * of the origin will be subtracted from action event coordinates.
  #         *
  #         - origin (object | string) #optional An object eg. { x: 0, y: 0 } or string 'parent', 'self' or any CSS selector
  #         * OR
  #         - origin (Element) #optional An HTML or SVG Element whose rect will be used
  #         **
  #         = (object) The current origin or this Interactable
  #        \

  #\
  #         * Interactable.deltaSource
  #         [ method ]
  #         *
  #         * Returns or sets the mouse coordinate types used to calculate the
  #         * movement of the pointer.
  #         *
  #         - newValue (string) #optional Use 'client' if you will be scrolling while interacting; Use 'page' if you want autoScroll to work
  #         = (string | object) The current deltaSource or this Interactable
  #        \

  #\
  #         * Interactable.restrict
  #         [ method ]
  #         **
  #         * Returns or sets the rectangles within which actions on this
  #         * interactable (after snap calculations) are restricted. By default,
  #         * restricting is relative to the pointer coordinates. You can change
  #         * this by setting the
  #         * ['elementRect'](https://github.com/taye/interact.js/pull/72).
  #         **
  #         - newValue (object) #optional an object with keys drag, resize, and/or gesture whose values are rects, Elements, CSS selectors, or 'parent' or 'self'
  #         = (object) The current restrictions object or this Interactable
  #         **
  #         | interact(element).restrict({
  #         |     // the rect will be 'interact.getElementRect(element.parentNode)'
  #         |     drag: element.parentNode,
  #         |
  #         |     // x and y are relative to the the interactable's origin
  #         |     resize: { x: 100, y: 100, width: 200, height: 200 }
  #         | })
  #         |
  #         | interact('.draggable').restrict({
  #         |     // the rect will be the selected element's parent
  #         |     drag: 'parent',
  #         |
  #         |     // do not restrict during normal movement.
  #         |     // Instead, trigger only one restricted move event
  #         |     // immediately before the end event.
  #         |     endOnly: true,
  #         |
  #         |     // https://github.com/taye/interact.js/pull/72#issue-41813493
  #         |     elementRect: { top: 0, left: 0, bottom: 1, right: 1 }
  #         | });
  #        \

  #\
  #         * Interactable.context
  #         [ method ]
  #         *
  #         * Get's the selector context Node of the Interactable. The default is 'window.document'.
  #         *
  #         = (Node) The context Node of this Interactable
  #         **
  #        \

  #\
  #         * Interactable.ignoreFrom
  #         [ method ]
  #         *
  #         * If the target of the 'mousedown', 'pointerdown' or 'touchstart'
  #         * event or any of it's parents match the given CSS selector or
  #         * Element, no drag/resize/gesture is started.
  #         *
  #         - newValue (string | Element | null) #optional a CSS selector string, an Element or 'null' to not ignore any elements
  #         = (string | Element | object) The current ignoreFrom value or this Interactable
  #         **
  #         | interact(element, { ignoreFrom: document.getElementById('no-action') });
  #         | // or
  #         | interact(element).ignoreFrom('input, textarea, a');
  #        \
  # CSS selector to match event.target
  # specific element

  #\
  #         * Interactable.allowFrom
  #         [ method ]
  #         *
  #         * A drag/resize/gesture is started only If the target of the
  #         * 'mousedown', 'pointerdown' or 'touchstart' event or any of it's
  #         * parents match the given CSS selector or Element.
  #         *
  #         - newValue (string | Element | null) #optional a CSS selector string, an Element or 'null' to allow from any element
  #         = (string | Element | object) The current allowFrom value or this Interactable
  #         **
  #         | interact(element, { allowFrom: document.getElementById('drag-handle') });
  #         | // or
  #         | interact(element).allowFrom('.handle');
  #        \
  # CSS selector to match event.target
  # specific element

  #\
  #         * Interactable.validateSetting
  #         [ method ]
  #         *
  #         - context (string) eg. 'snap', 'autoScroll'
  #         - option (string) The name of the value being set
  #         - value (any type) The value being validated
  #         *
  #         = (typeof value) A valid value for the give context-option pair
  #         * - null if defaultOptions[context][value] is undefined
  #         * - value if it is the same type as defaultOptions[context][value],
  #         * - this.options[context][value] if it is the same type as defaultOptions[context][value],
  #         * - or defaultOptions[context][value]
  #        \

  #\
  #         * Interactable.element
  #         [ method ]
  #         *
  #         * If this is not a selector Interactable, it returns the element this
  #         * interactable represents
  #         *
  #         = (Element) HTML / SVG Element
  #        \

  #\
  #         * Interactable.fire
  #         [ method ]
  #         *
  #         * Calls listeners for the given InteractEvent type bound globablly
  #         * and directly to this Interactable
  #         *
  #         - iEvent (InteractEvent) The InteractEvent object to be fired on this Interactable
  #         = (Interactable) this Interactable
  #        \

  # Interactable#on() listeners

  # interactable.onevent listener

  # interact.on() listeners

  #\
  #         * Interactable.on
  #         [ method ]
  #         *
  #         * Binds a listener for an InteractEvent or DOM event.
  #         *
  #         - eventType  (string)   The type of event to listen for
  #         - listener   (function) The function to be called on that event
  #         - useCapture (boolean) #optional useCapture flag for addEventListener
  #         = (object) This Interactable
  #        \

  # convert to boolean

  # if this type of event was never bound to this Interactable

  # if the event listener is not already bound for this type

  # delegated event for selector

  # add delegate listener functions

  # keep listener and useCapture flag

  #\
  #         * Interactable.off
  #         [ method ]
  #         *
  #         * Removes an InteractEvent or DOM event listener
  #         *
  #         - eventType  (string)   The type of event that was listened for
  #         - listener   (function) The listener function to be removed
  #         - useCapture (boolean) #optional useCapture flag for removeEventListener
  #         = (object) This Interactable
  #        \

  # convert to boolean

  # if it is an action event type

  # delegated event

  # count from last index of delegated to 0

  # look for matching selector and context Node

  # each item of the listeners array is an array: [function, useCaptureFlag]

  # check if the listener functions and useCapture flags match

  # remove the listener from the array of listeners

  # if all listeners for this interactable have been removed
  # remove the interactable from the delegated arrays

  # remove delegate function from context

  # remove the arrays if they are empty

  # only remove one listener

  # remove listener from this Interatable's element

  #\
  #         * Interactable.set
  #         [ method ]
  #         *
  #         * Reset the options of this Interactable
  #         - options (object) The new settings to apply
  #         = (object) This Interactablw
  #        \

  #\
  #         * Interactable.unset
  #         [ method ]
  #         *
  #         * Remove this interactable from the list of interactables and remove
  #         * it's drag, drop, resize and gesture capabilities
  #         *
  #         = (object) @interact
  #        \

  # remove delegated events

  # remove the arrays if they are empty

  #\
  #     * interact.isSet
  #     [ method ]
  #     *
  #     * Check if an element has been set
  #     - element (Element) The Element being searched for
  #     = (boolean) Indicates if the element or CSS selector was previously passed to interact
  #    \

  #\
  #     * interact.on
  #     [ method ]
  #     *
  #     * Adds a global listener for an InteractEvent or adds a DOM event to
  #     * 'document'
  #     *
  #     - type       (string)   The type of event to listen for
  #     - listener   (function) The function to be called on that event
  #     - useCapture (boolean) #optional useCapture flag for addEventListener
  #     = (object) interact
  #    \

  # if it is an InteractEvent type, add listener to globalEvents

  # if this type of event was never bound

  # if the event listener is not already bound for this type

  # If non InteratEvent type, addEventListener to document

  #\
  #     * interact.off
  #     [ method ]
  #     *
  #     * Removes a global InteractEvent listener or DOM event from 'document'
  #     *
  #     - type       (string)   The type of event that was listened for
  #     - listener   (function) The listener function to be removed
  #     - useCapture (boolean) #optional useCapture flag for removeEventListener
  #     = (object) interact
  #    \

  #\
  #     * interact.simulate
  #     [ method ]
  #     *
  #     * Simulate pointer down to begin to interact with an interactable element
  #     - action       (string)  The action to be performed - drag, resize, etc.
  #     - element      (Element) The DOM Element to resize/drag
  #     - pointerEvent (object) #optional Pointer event whose pageX/Y coordinates will be the starting point of the interact drag/resize
  #     = (object) interact
  #    \

  # return if the action is not recognised

  #\
  #     * interact.enableDragging
  #     [ method ]
  #     *
  #     * Returns or sets whether dragging is enabled for any Interactables
  #     *
  #     - newValue (boolean) #optional 'true' to allow the action; 'false' to disable action for all Interactables
  #     = (boolean | object) The current setting or interact
  #    \

  #\
  #     * interact.enableResizing
  #     [ method ]
  #     *
  #     * Returns or sets whether resizing is enabled for any Interactables
  #     *
  #     - newValue (boolean) #optional 'true' to allow the action; 'false' to disable action for all Interactables
  #     = (boolean | object) The current setting or interact
  #    \

  #\
  #     * interact.enableGesturing
  #     [ method ]
  #     *
  #     * Returns or sets whether gesturing is enabled for any Interactables
  #     *
  #     - newValue (boolean) #optional 'true' to allow the action; 'false' to disable action for all Interactables
  #     = (boolean | object) The current setting or interact
  #    \

  #\
  #     * interact.debug
  #     [ method ]
  #     *
  #     * Returns debugging data
  #     = (object) An object with properties that outline the current state and expose internal functions and variables
  #    \

  # expose the functions used to caluclate multi-touch properties

  #\
  #     * interact.margin
  #     [ method ]
  #     *
  #     * Returns or sets the margin for autocheck resizing used in
  #     * @Interactable.getAction. That is the distance from the bottom and right
  #     * edges of an element clicking in which will start resizing
  #     *
  #     - newValue (number) #optional
  #     = (number | interact) The current margin value or interact
  #    \

  #\
  #     * interact.styleCursor
  #     [ styleCursor ]
  #     *
  #     * Returns or sets whether the cursor style of the document is changed
  #     * depending on what action is being performed
  #     *
  #     - newValue (boolean) #optional
  #     = (boolean | interact) The current setting of interact
  #    \

  #\
  #     * interact.autoScroll
  #     [ method ]
  #     *
  #     * Returns or sets whether or not actions near the edges of the window or
  #     * specified container element trigger autoScroll by default
  #     *
  #     - options (boolean | object) true or false to simply enable or disable or an object with margin, distance, container and interval properties
  #     = (object) interact
  #     * or
  #     = (boolean | object) 'false' if autoscroll is disabled and the default autoScroll settings if it is enabled
  #    \

  # return the autoScroll settings if autoScroll is enabled
  # otherwise, return false

  #\
  #     * interact.snap
  #     [ method ]
  #     *
  #     * Returns or sets whether actions are constrained to a grid or a
  #     * collection of coordinates
  #     *
  #     - options (boolean | object) #optional New settings
  #     * 'true' or 'false' to simply enable or disable
  #     * or an object with some of the following properties
  #     o {
  #     o     mode   : 'grid', 'anchor' or 'path',
  #     o     range  : the distance within which snapping to a point occurs,
  #     o     actions: ['drag', 'resizex', 'resizey', 'resizexy'], an array of action types that can snapped (['drag'] by default) (no gesture)
  #     o     grid   : {
  #     o         x, y: the distances between the grid lines,
  #     o     },
  #     o     gridOffset: {
  #     o             x, y: the x/y-axis values of the grid origin
  #     o     },
  #     o     anchors: [
  #     o         {
  #     o             x: x coordinate to snap to,
  #     o             y: y coordinate to snap to,
  #     o             range: optional range for this anchor
  #     o         }
  #     o         {
  #     o             another anchor
  #     o         }
  #     o     ]
  #     o }
  #     *
  #     = (object | interact) The default snap settings object or interact
  #    \

  #\
  #     * interact.inertia
  #     [ method ]
  #     *
  #     * Returns or sets inertia settings.
  #     *
  #     * See @Interactable.inertia
  #     *
  #     - options (boolean | object) #optional New settings
  #     * 'true' or 'false' to simply enable or disable
  #     * or an object of inertia options
  #     = (object | interact) The default inertia settings object or interact
  #    \

  #\
  #     * interact.supportsTouch
  #     [ method ]
  #     *
  #     = (boolean) Whether or not the browser supports touch input
  #    \

  #\
  #     * interact.supportsPointerEvent
  #     [ method ]
  #     *
  #     = (boolean) Whether or not the browser supports PointerEvents
  #    \

  #\
  #     * interact.currentAction
  #     [ method ]
  #     *
  #     = (string) What action is currently being performed
  #    \

  #\
  #     * interact.stop
  #     [ method ]
  #     *
  #     * Cancels the current interaction
  #     *
  #     - event (Event) An event on which to call preventDefault()
  #     = (object) interact
  #    \

  #\
  #     * interact.dynamicDrop
  #     [ method ]
  #     *
  #     * Returns or sets whether the dimensions of dropzone elements are
  #     * calculated on every dragmove or only on dragstart for the default
  #     * dropChecker
  #     *
  #     - newValue (boolean) #optional True to check on each move. False to check only before start
  #     = (boolean | interact) The current setting or interact
  #    \

  #if (dragging && dynamicDrop !== newValue && !newValue) {
  #calcRects(dropzones);
  #}

  #\
  #     * interact.deltaSource
  #     [ method ]
  #     * Returns or sets weather pageX/Y or clientX/Y is used to calculate dx/dy.
  #     *
  #     * See @Interactable.deltaSource
  #     *
  #     - newValue (string) #optional 'page' or 'client'
  #     = (string | Interactable) The current setting or interact
  #    \

  #\
  #     * interact.restrict
  #     [ method ]
  #     *
  #     * Returns or sets the default rectangles within which actions (after snap
  #     * calculations) are restricted.
  #     *
  #     * See @Interactable.restrict
  #     *
  #     - newValue (object) #optional an object with keys drag, resize, and/or gesture and rects or Elements as values
  #     = (object) The current restrictions object or interact
  #    \

  #\
  #     * interact.pointerMoveTolerance
  #     [ method ]
  #     * Returns or sets the distance the pointer must be moved before an action
  #     * sequence occurs. This also affects tolerance for tap events.
  #     *
  #     - newValue (number) #optional The movement from the start position must be greater than this value
  #     = (number | Interactable) The current setting or interact
  #    \

  #\
  #     * interact.maxInteractions
  #     [ method ]
  #     **
  #     * Returns or sets the maximum number of concurrent interactions allowed.
  #     * By default only 1 interaction is allowed at a time (for backwards
  #     * compatibility). To allow multiple interactions on the same Interactables
  #     * and elements, you need to enable it in the draggable, resizable and
  #     * gesturable ''max'' and ''maxPerElement'' options.
  #     **
  #     - newValue (number) #optional Any number. newValue <= 0 means no interactions.
  #    \
  endAllInteractions = (event) ->
    i = 0

    while i < interactions.length
      interactions[i].pointerUp event, event
      i++
    return

  # remove pointers after ending actions in pointerUp

  # autoscroll

  # remove touches after ending actions in pointerUp

  # autoscroll
  indexOf = (array, target) ->
    i = 0
    len = array.length

    while i < len
      return i  if array[i] is target
      i++
    -1
  contains = (array, target) ->
    indexOf(array, target) isnt -1

  # For IE's lack of Event#preventDefault
  matchesSelector = (element, selector, nodeList) ->
    return ie8MatchesSelector(element, selector, nodeList)  if ie8MatchesSelector
    element[prefixedMatchesSelector] selector
  "use strict"
  document = window.document
  SVGElement = window.SVGElement or blank
  SVGSVGElement = window.SVGSVGElement or blank
  SVGElementInstance = window.SVGElementInstance or blank
  HTMLElement = window.HTMLElement or window.Element
  PointerEvent = (window.PointerEvent or window.MSPointerEvent)
  pEventTypes = undefined
  hypot = Math.hypot or (x, y) ->
    Math.sqrt x * x + y * y

  tmpXY = {}
  interactables = []
  interactions = []
  dynamicDrop = false
  delegatedEvents = {}
  defaultOptions =
    draggable: false
    dragAxis: "xy"
    dropzone: false
    accept: null
    dropOverlap: "pointer"
    resizable: false
    squareResize: false
    resizeAxis: "xy"
    gesturable: false
    dragMax: 1
    resizeMax: 1
    gestureMax: 1
    dragMaxPerElement: 1
    resizeMaxPerElement: 1
    gestureMaxPerElement: 1
    pointerMoveTolerance: 1
    actionChecker: null
    styleCursor: true
    preventDefault: "auto"
    snap:
      mode: "grid"
      endOnly: false
      actions: ["drag"]
      range: Infinity
      grid:
        x: 100
        y: 100

      gridOffset:
        x: 0
        y: 0

      anchors: []
      paths: []
      elementOrigin: null
      arrayTypes: /^anchors$|^paths$|^actions$/
      objectTypes: /^grid$|^gridOffset$|^elementOrigin$/
      stringTypes: /^mode$/
      numberTypes: /^range$/
      boolTypes: /^endOnly$/

    snapEnabled: false
    restrict:
      drag: null
      resize: null
      gesture: null
      endOnly: false

    restrictEnabled: false
    autoScroll:
      container: window
      margin: 60
      speed: 300
      numberTypes: /^margin$|^speed$/

    autoScrollEnabled: false
    inertia:
      resistance: 10
      minSpeed: 100
      endSpeed: 10
      allowResume: true
      zeroResumeDelta: false
      smoothEndDuration: 300
      actions: [
        "drag"
        "resize"
      ]
      numberTypes: /^resistance$|^minSpeed$|^endSpeed$|^smoothEndDuration$/
      arrayTypes: /^actions$/
      boolTypes: /^(allowResume|zeroResumeDelta)$/

    inertiaEnabled: false
    origin:
      x: 0
      y: 0

    deltaSource: "page"
    context: document

  autoScroll =
    target: null
    i: null
    x: 0
    y: 0
    scroll: ->
      options = autoScroll.target.options.autoScroll
      container = options.container
      now = new Date().getTime()
      dt = (now - autoScroll.prevTime) / 1000
      s = options.speed * dt
      if s >= 1
        if container instanceof window.Window
          container.scrollBy autoScroll.x * s, autoScroll.y * s
        else if container
          container.scrollLeft += autoScroll.x * s
          container.scrollTop += autoScroll.y * s
        autoScroll.prevTime = now
      if autoScroll.isScrolling
        cancelFrame autoScroll.i
        autoScroll.i = reqFrame(autoScroll.scroll)
      return

    edgeMove: (event) ->
      target = undefined
      doAutoscroll = false
      i = 0

      while i < interactions.length
        interaction = interactions[i]
        target = interaction.target
        if target and target.options.autoScrollEnabled and (interaction.dragging or interaction.resizing)
          doAutoscroll = true
          break
        i++
      return  unless doAutoscroll
      top = undefined
      right = undefined
      bottom = undefined
      left = undefined
      options = target.options.autoScroll
      if options.container instanceof window.Window
        left = event.clientX < autoScroll.margin
        top = event.clientY < autoScroll.margin
        right = event.clientX > options.container.innerWidth - autoScroll.margin
        bottom = event.clientY > options.container.innerHeight - autoScroll.margin
      else
        rect = getElementRect(options.container)
        left = event.clientX < rect.left + autoScroll.margin
        top = event.clientY < rect.top + autoScroll.margin
        right = event.clientX > rect.right - autoScroll.margin
        bottom = event.clientY > rect.bottom - autoScroll.margin
      autoScroll.x = ((if right then 1 else (if left then -1 else 0)))
      autoScroll.y = ((if bottom then 1 else (if top then -1 else 0)))
      unless autoScroll.isScrolling
        autoScroll.margin = options.margin
        autoScroll.speed = options.speed
        autoScroll.start target
      return

    isScrolling: false
    prevTime: 0
    start: (target) ->
      autoScroll.isScrolling = true
      cancelFrame autoScroll.i
      autoScroll.target = target
      autoScroll.prevTime = new Date().getTime()
      autoScroll.i = reqFrame(autoScroll.scroll)
      return

    stop: ->
      autoScroll.isScrolling = false
      cancelFrame autoScroll.i
      return

  supportsTouch = (("ontouchstart" of window) or window.DocumentTouch and document instanceof window.DocumentTouch)
  supportsPointerEvent = !!PointerEvent
  margin = (if supportsTouch or supportsPointerEvent then 20 else 10)
  prevTouchTapTime = 0
  maxInteractions = 1
  actionCursors =
    drag: "move"
    resizex: "e-resize"
    resizey: "s-resize"
    resizexy: "se-resize"
    gesture: ""

  actionIsEnabled =
    drag: true
    resize: true
    gesture: true

  wheelEvent = (if "onmousewheel" of document then "mousewheel" else "wheel")
  eventTypes = [

  ]
  globalEvents = {}
  isOperaMobile = navigator.appName is "Opera" and supportsTouch and navigator.userAgent.match("Presto")
  isIOS7orLower = (/iP(hone|od|ad)/.test(navigator.platform) and /OS [1-7][^\d]/.test(navigator.appVersion))
  prefixedMatchesSelector = (if "matchesSelector" of Element:: then "matchesSelector" else (if "webkitMatchesSelector" of Element:: then "webkitMatchesSelector" else (if "mozMatchesSelector" of Element:: then "mozMatchesSelector" else (if "oMatchesSelector" of Element:: then "oMatchesSelector" else "msMatchesSelector"))))
  ie8MatchesSelector = undefined
  reqFrame = window.requestAnimationFrame
  cancelFrame = window.cancelAnimationFrame
  windowTarget =
    _element: window
    events: {}

  docTarget =
    _element: document
    events: {}

  parentWindowTarget =
    _element: window.parent
    events: {}

  parentDocTarget =
    _element: null
    events: {}

  events = (->
    add = (element, type, listener, useCapture) ->
      elementIndex = indexOf(elements, element)
      target = targets[elementIndex]
      unless target
        target =
          events: {}
          typeCount: 0

        elementIndex = elements.push(element) - 1
        targets.push target
        attachedListeners.push ((if useAttachEvent then
          supplied: []
          wrapped: []
          useCount: []
         else null))
      unless target.events[type]
        target.events[type] = []
        target.typeCount++
      unless contains(target.events[type], listener)
        ret = undefined
        if useAttachEvent
          listeners = attachedListeners[elementIndex]
          listenerIndex = indexOf(listeners.supplied, listener)
          wrapped = listeners.wrapped[listenerIndex] or (event) ->
            unless event.immediatePropagationStopped
              event.target = event.srcElement
              event.currentTarget = element
              event.preventDefault = event.preventDefault or preventDef
              event.stopPropagation = event.stopPropagation or stopProp
              event.stopImmediatePropagation = event.stopImmediatePropagation or stopImmProp
              if /mouse|click/.test(event.type)
                event.pageX = event.clientX + document.documentElement.scrollLeft
                event.pageY = event.clientY + document.documentElement.scrollTop
              listener event
            return

          ret = element[addEvent](on_ + type, wrapped, Boolean(useCapture))
          if listenerIndex is -1
            listeners.supplied.push listener
            listeners.wrapped.push wrapped
            listeners.useCount.push 1
          else
            listeners.useCount[listenerIndex]++
        else
          ret = element[addEvent](type, listener, useCapture or false)
        target.events[type].push listener
        ret
    remove = (element, type, listener, useCapture) ->
      i = undefined
      elementIndex = indexOf(elements, element)
      target = targets[elementIndex]
      listeners = undefined
      listenerIndex = undefined
      wrapped = listener
      return  if not target or not target.events
      if useAttachEvent
        listeners = attachedListeners[elementIndex]
        listenerIndex = indexOf(listeners.supplied, listener)
        wrapped = listeners.wrapped[listenerIndex]
      if type is "all"
        for type of target.events
          remove element, type, "all"  if target.events.hasOwnProperty(type)
        return
      if target.events[type]
        len = target.events[type].length
        if listener is "all"
          i = 0
          while i < len
            remove element, type, target.events[type][i], Boolean(useCapture)
            i++
        else
          i = 0
          while i < len
            if target.events[type][i] is listener
              element[removeEvent] on_ + type, wrapped, useCapture or false
              target.events[type].splice i, 1
              if useAttachEvent and listeners
                listeners.useCount[listenerIndex]--
                if listeners.useCount[listenerIndex] is 0
                  listeners.supplied.splice listenerIndex, 1
                  listeners.wrapped.splice listenerIndex, 1
                  listeners.useCount.splice listenerIndex, 1
              break
            i++
        if target.events[type] and target.events[type].length is 0
          target.events[type] = null
          target.typeCount--
      unless target.typeCount
        targets.splice elementIndex
        elements.splice elementIndex
        attachedListeners.splice elementIndex
      return
    preventDef = ->
      @returnValue = false
      return
    stopProp = ->
      @cancelBubble = true
      return
    stopImmProp = ->
      @cancelBubble = true
      @immediatePropagationStopped = true
      return
    useAttachEvent = ("attachEvent" of window) and ("addEventListener" not of window)
    addEvent = (if useAttachEvent then "attachEvent" else "addEventListener")
    removeEvent = (if useAttachEvent then "detachEvent" else "removeEventListener")
    on_ = (if useAttachEvent then "on" else "")
    elements = []
    targets = []
    attachedListeners = []
    add: (target, type, listener, useCapture) ->
      add target._element, type, listener, useCapture
      return

    remove: (target, type, listener, useCapture) ->
      remove target._element, type, listener, useCapture
      return

    addToElement: add
    removeFromElement: remove
    useAttachEvent: useAttachEvent
    _elements: elements
    _targets: targets
    _attachedListeners: attachedListeners
  ())
  Interaction:: =
    getPageXY: (pointer, xy) ->
      getPageXY pointer, xy, this

    getClientXY: (pointer, xy) ->
      getClientXY pointer, xy, this

    setEventXY: (target, ptr) ->
      setEventXY target, ptr, this

    pointerOver: (pointer, event, eventTarget) ->
      pushCurMatches = (interactable, selector) ->
        if interactable and inContext(interactable, eventTarget) and not testIgnore(interactable, eventTarget, eventTarget) and testAllow(interactable, eventTarget, eventTarget) and matchesSelector(eventTarget, selector)
          curMatches.push interactable
          curMatchElements.push eventTarget
        return
      return  if @prepared or not @mouse
      curMatches = []
      curMatchElements = []
      prevTargetElement = @element
      @addPointer pointer
      if @target and (testIgnore(@target, @element, eventTarget) or not testAllow(@target, @element, eventTarget) or not withinInteractionLimit(@target, @element, @prepared))
        @target = null
        @element = null
        @matches = []
        @matchElements = []
      elementInteractable = interactables.get(eventTarget)
      elementAction = (elementInteractable and not testIgnore(elementInteractable, eventTarget, eventTarget) and testAllow(elementInteractable, eventTarget, eventTarget) and validateAction(elementInteractable.getAction(pointer, this, eventTarget), elementInteractable))
      elementAction = (if elementInteractable and withinInteractionLimit(elementInteractable, eventTarget, elementAction) then elementAction else null)
      if elementAction
        @target = elementInteractable
        @element = eventTarget
        @matches = []
        @matchElements = []
      else
        interactables.forEachSelector pushCurMatches
        if @validateSelector(pointer, curMatches, curMatchElements)
          @matches = curMatches
          @matchElements = curMatchElements
          @pointerHover pointer, event, @matches, @matchElements
          events.addToElement eventTarget, (if PointerEvent then pEventTypes.move else "mousemove"), listeners.pointerHover
        else if @target
          if nodeContains(prevTargetElement, eventTarget)
            @pointerHover pointer, event, @matches, @matchElements
            events.addToElement @element, (if PointerEvent then pEventTypes.move else "mousemove"), listeners.pointerHover
          else
            @target = null
            @element = null
            @matches = []
            @matchElements = []
      return

    pointerHover: (pointer, event, eventTarget, curEventTarget, matches, matchElements) ->
      target = @target
      if not @prepared and @mouse
        action = undefined
        @setEventXY @curCoords, pointer
        if matches
          action = @validateSelector(pointer, matches, matchElements)
        else action = validateAction(target.getAction(@pointers[0], this, @element), @target)  if target
        if target and target.options.styleCursor
          if action
            document.documentElement.style.cursor = actionCursors[action]
          else
            document.documentElement.style.cursor = ""
      else @checkAndPreventDefault event, target, @element  if @prepared
      return

    pointerOut: (pointer, event, eventTarget) ->
      return  if @prepared
      events.removeFromElement eventTarget, (if PointerEvent then pEventTypes.move else "mousemove"), listeners.pointerHover  unless interactables.get(eventTarget)
      document.documentElement.style.cursor = ""  if @target and @target.options.styleCursor and not @interacting()
      return

    selectorDown: (pointer, event, eventTarget, curEventTarget) ->
      pushMatches = (interactable, selector, context) ->
        elements = (if ie8MatchesSelector then context.querySelectorAll(selector) else 'undefined')
        if inContext(interactable, element) and not testIgnore(interactable, element, eventTarget) and testAllow(interactable, element, eventTarget) and matchesSelector(element, selector, elements)
          that.matches.push interactable
          that.matchElements.push element
        return
      @pointerIsDown = true
      element = eventTarget
      action = undefined
      @addPointer pointer
      if @inertiaStatus.active and @target.selector
        while element and element isnt document
          if element is @element and validateAction(@target.getAction(pointer, this, @element), @target) is @prepared
            cancelFrame @inertiaStatus.i
            @inertiaStatus.active = false
            return
          element = element.parentNode
      return  if @interacting()
      that = this
      @setEventXY @curCoords, pointer
      if @matches.length and @mouse
        action = @validateSelector(pointer, @matches, @matchElements)
      else
        while element and element isnt document and not action
          @matches = []
          @matchElements = []
          interactables.forEachSelector pushMatches
          action = @validateSelector(pointer, @matches, @matchElements)
          element = element.parentNode
      if action
        @prepared = action
        @pointerDown pointer, event, eventTarget, curEventTarget, action
      else
        @downTime = new Date().getTime()
        @downTarget = eventTarget
        @downEvent = event
        extend @downPointer, pointer
        copyCoords @prevCoords, @curCoords
        @pointerWasMoved = false
      return

    pointerDown: (pointer, event, eventTarget, curEventTarget, forceAction) ->
      if not forceAction and not @inertiaStatus.active and @pointerWasMoved and @prepared
        @checkAndPreventDefault event, @target, @element
        return
      @pointerIsDown = true
      @addPointer pointer
      action = undefined
      if (@pointerIds.length < 2 and not @target) or not @prepared
        interactable = interactables.get(curEventTarget)
        if interactable and not testIgnore(interactable, curEventTarget, eventTarget) and testAllow(interactable, curEventTarget, eventTarget) and (action = validateAction(forceAction or interactable.getAction(pointer, this), interactable, eventTarget)) and withinInteractionLimit(interactable, curEventTarget, action)
          @target = interactable
          @element = curEventTarget
      target = @target
      options = target and target.options
      if target and not @interacting()
        action = action or validateAction(forceAction or target.getAction(pointer, this), target, @element)
        @setEventXY @startCoords
        return  unless action
        document.documentElement.style.cursor = actionCursors[action]  if options.styleCursor
        @resizeAxes = (if action is "resizexy" then "xy" else (if action is "resizex" then "x" else (if action is "resizey" then "y" else "")))
        action = null  if action is "gesture" and @pointerIds.length < 2
        @prepared = action
        @snapStatus.snappedX = @snapStatus.snappedY = @restrictStatus.restrictedX = @restrictStatus.restrictedY = NaN
        @downTime = new Date().getTime()
        @downTarget = eventTarget
        @downEvent = event
        extend @downPointer, pointer
        @setEventXY @prevCoords
        @pointerWasMoved = false
        @checkAndPreventDefault event, target, @element
      else if @inertiaStatus.active and @target.options.inertia.allowResume and curEventTarget is @element and validateAction(target.getAction(pointer, this, @element), target) is @prepared
        cancelFrame @inertiaStatus.i
        @inertiaStatus.active = false
        @checkAndPreventDefault event, target, @element
      return

    pointerMove: (pointer, event, eventTarget, curEventTarget, preEnd) ->
      return  unless @pointerIsDown
      @setEventXY @curCoords, (if (pointer instanceof InteractEvent) then @inertiaStatus.startEvent else 'undefined')
      if @pointerWasMoved and not preEnd and @curCoords.page.x is @prevCoords.page.x and @curCoords.page.y is @prevCoords.page.y and @curCoords.client.x is @prevCoords.client.x and @curCoords.client.y is @prevCoords.client.y
        @checkAndPreventDefault event, @target, @element
        return
      setEventDeltas @pointerDelta, @prevCoords, @curCoords
      dx = undefined
      dy = undefined
      unless @pointerWasMoved
        dx = @curCoords.client.x - @startCoords.client.x
        dy = @curCoords.client.y - @startCoords.client.y
        @pointerWasMoved = hypot(dx, dy) > defaultOptions.pointerMoveTolerance
      return  unless @prepared
      if @pointerWasMoved and (not @inertiaStatus.active or (pointer instanceof InteractEvent and /inertiastart/.test(pointer.type)))
        unless @interacting()
          setEventDeltas @pointerDelta, @prevCoords, @curCoords
          if @prepared is "drag"
            absX = Math.abs(dx)
            absY = Math.abs(dy)
            targetAxis = @target.options.dragAxis
            axis = ((if absX > absY then "x" else (if absX < absY then "y" else "xy")))
            if axis isnt "xy" and targetAxis isnt "xy" and targetAxis isnt axis
              @prepared = null
              element = eventTarget
              while element and element isnt document
                elementInteractable = interactables.get(element)
                if elementInteractable and elementInteractable isnt @target and elementInteractable.getAction(@downPointer, this, element) is "drag" and checkAxis(axis, elementInteractable)
                  @prepared = "drag"
                  @target = elementInteractable
                  @element = element
                  break
                element = element.parentNode
              unless @prepared
                getDraggable = (interactable, selector, context) ->
                  elements = (if ie8MatchesSelector then context.querySelectorAll(selector) else 'undefined')
                  return  if interactable is @target
                  interactable  if inContext(interactable, eventTarget) and not testIgnore(interactable, element, eventTarget) and testAllow(interactable, element, eventTarget) and matchesSelector(element, selector, elements) and interactable.getAction(@downPointer, this, element) is "drag" and checkAxis(axis, interactable) and withinInteractionLimit(interactable, element, "drag")

                element = eventTarget
                while element and element isnt document
                  selectorInteractable = interactables.forEachSelector(getDraggable)
                  if selectorInteractable
                    @prepared = "drag"
                    @target = selectorInteractable
                    @element = element
                    break
                  element = element.parentNode
        starting = !!@prepared and not @interacting()
        if starting and not withinInteractionLimit(@target, @element, @prepared)
          @stop()
          return
        if @prepared and @target
          target = @target
          shouldSnap = checkSnap(target, @prepared) and (not target.options.snap.endOnly or preEnd)
          shouldRestrict = checkRestrict(target, @prepared) and (not target.options.restrict.endOnly or preEnd)
          if starting
            rect = target.getRect(@element)
            snap = target.options.snap
            restrict = target.options.restrict
            width = undefined
            height = undefined
            if rect
              @startOffset.left = @startCoords.page.x - rect.left
              @startOffset.top = @startCoords.page.y - rect.top
              @startOffset.right = rect.right - @startCoords.page.x
              @startOffset.bottom = rect.bottom - @startCoords.page.y
              if "width" of rect
                width = rect.width
              else
                width = rect.right - rect.left
              if "height" of rect
                height = rect.height
              else
                height = rect.bottom - rect.top
            else
              @startOffset.left = @startOffset.top = @startOffset.right = @startOffset.bottom = 0
            if rect and snap.elementOrigin
              @snapOffset.x = @startOffset.left - (width * snap.elementOrigin.x)
              @snapOffset.y = @startOffset.top - (height * snap.elementOrigin.y)
            else
              @snapOffset.x = @snapOffset.y = 0
            if rect and restrict.elementRect
              @restrictOffset.left = @startOffset.left - (width * restrict.elementRect.left)
              @restrictOffset.top = @startOffset.top - (height * restrict.elementRect.top)
              @restrictOffset.right = @startOffset.right - (width * (1 - restrict.elementRect.right))
              @restrictOffset.bottom = @startOffset.bottom - (height * (1 - restrict.elementRect.bottom))
            else
              @restrictOffset.left = @restrictOffset.top = @restrictOffset.right = @restrictOffset.bottom = 0
          snapCoords = (if starting then @startCoords.page else @curCoords.page)
          if shouldSnap
            @setSnapping snapCoords
          else
            @snapStatus.locked = false
          if shouldRestrict
            @setRestriction snapCoords
          else
            @restrictStatus.restricted = false
          shouldMove = ((if shouldSnap then (@snapStatus.changed or not @snapStatus.locked) else true)) and ((if shouldRestrict then (not @restrictStatus.restricted or (@restrictStatus.restricted and @restrictStatus.changed)) else true))
          if shouldMove
            action = (if /resize/.test(@prepared) then "resize" else @prepared)
            if starting
              dragStartEvent = this[action + "Start"](@downEvent)
              @prevEvent = dragStartEvent
              @activeDrops.dropzones = []
              @activeDrops.elements = []
              @activeDrops.rects = []
              @setActiveDrops @element  unless @dynamicDrop
              dropEvents = @getDropEvents(event, dragStartEvent)
              @fireActiveDrops dropEvents.activate  if dropEvents.activate
              snapCoords = @curCoords.page
              @setSnapping snapCoords  if shouldSnap
              @setRestriction snapCoords  if shouldRestrict
            @prevEvent = this[action + "Move"](event)
          @checkAndPreventDefault event, @target, @element
      copyCoords @prevCoords, @curCoords
      autoScroll.edgeMove event  if @dragging or @resizing
      return

    dragStart: (event) ->
      dragEvent = new InteractEvent(this, event, "drag", "start", @element)
      @dragging = true
      @target.fire dragEvent
      dragEvent

    dragMove: (event) ->
      target = @target
      dragEvent = new InteractEvent(this, event, "drag", "move", @element)
      draggableElement = @element
      drop = @getDrop(dragEvent, draggableElement)
      @dropTarget = drop.dropzone
      @dropElement = drop.element
      dropEvents = @getDropEvents(event, dragEvent)
      target.fire dragEvent
      @prevDropTarget.fire dropEvents.leave  if dropEvents.leave
      @dropTarget.fire dropEvents.enter  if dropEvents.enter
      @dropTarget.fire dropEvents.move  if dropEvents.move
      @prevDropTarget = @dropTarget
      @prevDropElement = @dropElement
      dragEvent

    resizeStart: (event) ->
      resizeEvent = new InteractEvent(this, event, "resize", "start", @element)
      @target.fire resizeEvent
      @resizing = true
      resizeEvent

    resizeMove: (event) ->
      resizeEvent = new InteractEvent(this, event, "resize", "move", @element)
      @target.fire resizeEvent
      resizeEvent

    gestureStart: (event) ->
      gestureEvent = new InteractEvent(this, event, "gesture", "start", @element)
      gestureEvent.ds = 0
      @gesture.startDistance = @gesture.prevDistance = gestureEvent.distance
      @gesture.startAngle = @gesture.prevAngle = gestureEvent.angle
      @gesture.scale = 1
      @gesturing = true
      @target.fire gestureEvent
      gestureEvent

    gestureMove: (event) ->
      return @prevEvent  unless @pointerIds.length
      gestureEvent = undefined
      gestureEvent = new InteractEvent(this, event, "gesture", "move", @element)
      gestureEvent.ds = gestureEvent.scale - @gesture.scale
      @target.fire gestureEvent
      @gesture.prevAngle = gestureEvent.angle
      @gesture.prevDistance = gestureEvent.distance
      @gesture.scale = gestureEvent.scale  if gestureEvent.scale isnt Infinity and gestureEvent.scale isnt null and gestureEvent.scale isnt 'undefined' and not isNaN(gestureEvent.scale)
      gestureEvent

    pointerUp: (pointer, event, eventTarget, curEventTarget) ->
      endEvent = undefined
      target = @target
      options = target and target.options
      inertiaOptions = options and options.inertia
      inertiaStatus = @inertiaStatus
      if @interacting()
        return  if inertiaStatus.active
        pointerSpeed = undefined
        now = new Date().getTime()
        inertiaPossible = false
        inertia = false
        smoothEnd = false
        endSnap = checkSnap(target, @prepared) and options.snap.endOnly
        endRestrict = checkRestrict(target, @prepared) and options.restrict.endOnly
        dx = 0
        dy = 0
        startEvent = undefined
        if @dragging
          if options.dragAxis is "x"
            pointerSpeed = Math.abs(@pointerDelta.client.vx)
          else if options.dragAxis is "y"
            pointerSpeed = Math.abs(@pointerDelta.client.vy)
          else
            pointerSpeed = @pointerDelta.client.speed
        inertiaPossible = (options.inertiaEnabled and @prepared isnt "gesture" and contains(inertiaOptions.actions, @prepared) and event isnt inertiaStatus.startEvent)
        inertia = (inertiaPossible and (now - @curCoords.timeStamp) < 50 and pointerSpeed > inertiaOptions.minSpeed and pointerSpeed > inertiaOptions.endSpeed)
        if inertiaPossible and not inertia and (endSnap or endRestrict)
          snapRestrict = {}
          snapRestrict.snap = snapRestrict.restrict = snapRestrict
          if endSnap
            @setSnapping @curCoords.page, snapRestrict
            if snapRestrict.locked
              dx += snapRestrict.dx
              dy += snapRestrict.dy
          if endRestrict
            @setRestriction @curCoords.page, snapRestrict
            if snapRestrict.restricted
              dx += snapRestrict.dx
              dy += snapRestrict.dy
          smoothEnd = true  if dx or dy
        if inertia or smoothEnd
          copyCoords inertiaStatus.upCoords, @curCoords
          @pointers[0] = inertiaStatus.startEvent = startEvent = new InteractEvent(this, event, @prepared, "inertiastart", @element)
          inertiaStatus.t0 = now
          target.fire inertiaStatus.startEvent
          if inertia
            inertiaStatus.vx0 = @pointerDelta.client.vx
            inertiaStatus.vy0 = @pointerDelta.client.vy
            inertiaStatus.v0 = pointerSpeed
            @calcInertia inertiaStatus
            page = extend({}, @curCoords.page)
            origin = getOriginXY(target, @element)
            statusObject = undefined
            page.x = page.x + inertiaStatus.xe - origin.x
            page.y = page.y + inertiaStatus.ye - origin.y
            statusObject =
              useStatusXY: true
              x: page.x
              y: page.y
              dx: 0
              dy: 0
              snap: null

            statusObject.snap = statusObject
            dx = dy = 0
            if endSnap
              snap = @setSnapping(@curCoords.page, statusObject)
              if snap.locked
                dx += snap.dx
                dy += snap.dy
            if endRestrict
              restrict = @setRestriction(@curCoords.page, statusObject)
              if restrict.restricted
                dx += restrict.dx
                dy += restrict.dy
            inertiaStatus.modifiedXe += dx
            inertiaStatus.modifiedYe += dy
            inertiaStatus.i = reqFrame(@boundInertiaFrame)
          else
            inertiaStatus.smoothEnd = true
            inertiaStatus.xe = dx
            inertiaStatus.ye = dy
            inertiaStatus.sx = inertiaStatus.sy = 0
            inertiaStatus.i = reqFrame(@boundSmoothEndFrame)
          inertiaStatus.active = true
          return
        @pointerMove pointer, event, eventTarget, curEventTarget, true  if endSnap or endRestrict
      if @dragging
        endEvent = new InteractEvent(this, event, "drag", "end", @element)
        draggableElement = @element
        drop = @getDrop(endEvent, draggableElement)
        @dropTarget = drop.dropzone
        @dropElement = drop.element
        dropEvents = @getDropEvents(event, endEvent)
        @prevDropTarget.fire dropEvents.leave  if dropEvents.leave
        @dropTarget.fire dropEvents.enter  if dropEvents.enter
        @dropTarget.fire dropEvents.drop  if dropEvents.drop
        @fireActiveDrops dropEvents.deactivate  if dropEvents.deactivate
        target.fire endEvent
      else if @resizing
        endEvent = new InteractEvent(this, event, "resize", "end", @element)
        target.fire endEvent
      else if @gesturing
        endEvent = new InteractEvent(this, event, "gesture", "end", @element)
        target.fire endEvent
      @stop event
      return

    collectDrops: (element) ->
      drops = []
      elements = []
      i = undefined
      element = element or @element
      i = 0
      while i < interactables.length
        continue  unless interactables[i].options.dropzone
        current = interactables[i]
        continue  if (isElement(current.options.accept) and current.options.accept isnt element) or (isString(current.options.accept) and not matchesSelector(element, current.options.accept))
        dropElements = (if current.selector then current._context.querySelectorAll(current.selector) else [current._element])
        j = 0
        len = dropElements.length

        while j < len
          currentElement = dropElements[j]
          continue  if currentElement is element
          drops.push current
          elements.push currentElement
          j++
        i++
      dropzones: drops
      elements: elements

    fireActiveDrops: (event) ->
      i = undefined
      current = undefined
      currentElement = undefined
      prevElement = undefined
      i = 0
      while i < @activeDrops.dropzones.length
        current = @activeDrops.dropzones[i]
        currentElement = @activeDrops.elements[i]
        if currentElement isnt prevElement
          event.target = currentElement
          current.fire event
        prevElement = currentElement
        i++
      return

    setActiveDrops: (dragElement) ->
      possibleDrops = @collectDrops(dragElement, true)
      @activeDrops.dropzones = possibleDrops.dropzones
      @activeDrops.elements = possibleDrops.elements
      @activeDrops.rects = []
      i = 0

      while i < @activeDrops.dropzones.length
        @activeDrops.rects[i] = @activeDrops.dropzones[i].getRect(@activeDrops.elements[i])
        i++
      return

    getDrop: (event, dragElement) ->
      validDrops = []
      @setActiveDrops dragElement  if dynamicDrop
      j = 0

      while j < @activeDrops.dropzones.length
        current = @activeDrops.dropzones[j]
        currentElement = @activeDrops.elements[j]
        rect = @activeDrops.rects[j]
        validDrops.push (if current.dropCheck(@pointers[0], @target, dragElement, currentElement, rect) then currentElement else null)
        j++
      dropIndex = indexOfDeepestElement(validDrops)
      dropzone = @activeDrops.dropzones[dropIndex] or null
      element = @activeDrops.elements[dropIndex] or null
      dropzone: dropzone
      element: element

    getDropEvents: (pointerEvent, dragEvent) ->
      dragLeaveEvent = null
      dragEnterEvent = null
      dropActivateEvent = null
      dropDectivateEvent = null
      dropMoveEvent = null
      dropEvent = null
      if @dropElement isnt @prevDropElement
        if @prevDropTarget
          dragLeaveEvent = new InteractEvent(this, pointerEvent, "drag", "leave", @prevDropElement, dragEvent.target)
          dragLeaveEvent.draggable = dragEvent.interactable
          dragEvent.dragLeave = @prevDropElement
          dragEvent.prevDropzone = @prevDropTarget
        if @dropTarget
          dragEnterEvent = new InteractEvent(this, pointerEvent, "drag", "enter", @dropElement, dragEvent.target)
          dragEnterEvent.draggable = dragEvent.interactable
          dragEvent.dragEnter = @dropElement
          dragEvent.dropzone = @dropTarget
      if dragEvent.type is "dragend" and @dropTarget
        dropEvent = new InteractEvent(this, pointerEvent, "drop", null, @dropElement, dragEvent.target)
        dropEvent.draggable = dragEvent.interactable
        dragEvent.dropzone = @dropTarget
      if dragEvent.type is "dragstart"
        dropActivateEvent = new InteractEvent(this, pointerEvent, "drop", "activate", @element, dragEvent.target)
        dropActivateEvent.draggable = dragEvent.interactable
      if dragEvent.type is "dragend"
        dropDectivateEvent = new InteractEvent(this, pointerEvent, "drop", "deactivate", @element, dragEvent.target)
        dropDectivateEvent.draggable = dragEvent.interactable
      if dragEvent.type is "dragmove" and @dropTarget
        dropMoveEvent =
          target: @dropElement
          relatedTarget: dragEvent.target
          draggable: dragEvent.interactable
          dragmove: dragEvent
          type: "dropmove"
          timeStamp: dragEvent.timeStamp

        dragEvent.dropzone = @dropTarget
      enter: dragEnterEvent
      leave: dragLeaveEvent
      activate: dropActivateEvent
      deactivate: dropDectivateEvent
      move: dropMoveEvent
      drop: dropEvent

    currentAction: ->
      (@dragging and "drag") or (@resizing and "resize") or (@gesturing and "gesture") or null

    interacting: ->
      @dragging or @resizing or @gesturing

    clearTargets: ->
      @target = @element = null  if @target and not @target.selector
      @dropTarget = @dropElement = @prevDropTarget = @prevDropElement = null
      return

    stop: (event) ->
      if @interacting()
        autoScroll.stop()
        @matches = []
        @matchElements = []
        target = @target
        document.documentElement.style.cursor = ""  if target.options.styleCursor
        @checkAndPreventDefault event, target, @element  if event and isFunction(event.preventDefault)
        @activeDrops.dropzones = @activeDrops.elements = @activeDrops.rects = null  if @dragging
        @clearTargets()
      @pointerIsDown = @snapStatus.locked = @dragging = @resizing = @gesturing = false
      @prepared = @prevEvent = null
      @inertiaStatus.resumeDx = @inertiaStatus.resumeDy = 0
      @pointerIds.splice 0
      interactions.splice indexOf(interactions, this), 1  if interactions.length > 1
      return

    inertiaFrame: ->
      inertiaStatus = @inertiaStatus
      options = @target.options.inertia
      lambda = options.resistance
      t = new Date().getTime() / 1000 - inertiaStatus.t0
      if t < inertiaStatus.te
        progress = 1 - (Math.exp(-lambda * t) - inertiaStatus.lambda_v0) / inertiaStatus.one_ve_v0
        if inertiaStatus.modifiedXe is inertiaStatus.xe and inertiaStatus.modifiedYe is inertiaStatus.ye
          inertiaStatus.sx = inertiaStatus.xe * progress
          inertiaStatus.sy = inertiaStatus.ye * progress
        else
          quadPoint = getQuadraticCurvePoint(0, 0, inertiaStatus.xe, inertiaStatus.ye, inertiaStatus.modifiedXe, inertiaStatus.modifiedYe, progress)
          inertiaStatus.sx = quadPoint.x
          inertiaStatus.sy = quadPoint.y
        @pointerMove inertiaStatus.startEvent, inertiaStatus.startEvent
        inertiaStatus.i = reqFrame(@boundInertiaFrame)
      else
        inertiaStatus.sx = inertiaStatus.modifiedXe
        inertiaStatus.sy = inertiaStatus.modifiedYe
        @pointerMove inertiaStatus.startEvent, inertiaStatus.startEvent
        inertiaStatus.active = false
        @pointerUp inertiaStatus.startEvent, inertiaStatus.startEvent
      return

    smoothEndFrame: ->
      inertiaStatus = @inertiaStatus
      t = new Date().getTime() - inertiaStatus.t0
      duration = @target.options.inertia.smoothEndDuration
      if t < duration
        inertiaStatus.sx = easeOutQuad(t, 0, inertiaStatus.xe, duration)
        inertiaStatus.sy = easeOutQuad(t, 0, inertiaStatus.ye, duration)
        @pointerMove inertiaStatus.startEvent, inertiaStatus.startEvent
        inertiaStatus.i = reqFrame(@boundSmoothEndFrame)
      else
        inertiaStatus.sx = inertiaStatus.xe
        inertiaStatus.sy = inertiaStatus.ye
        @pointerMove inertiaStatus.startEvent, inertiaStatus.startEvent
        inertiaStatus.active = false
        inertiaStatus.smoothEnd = false
        @pointerUp inertiaStatus.startEvent, inertiaStatus.startEvent
      return

    addPointer: (pointer) ->
      id = getPointerId(pointer)
      index = (if @mouse then 0 else indexOf(@pointerIds, id))
      if index is -1
        index = @pointerIds.length
        @pointerIds.push id
        @pointers[index] = pointer
      else
        @pointers[index] = pointer
      return

    removePointer: (pointer) ->
      id = getPointerId(pointer)
      index = (if @mouse then 0 else indexOf(@pointerIds, id))
      return  if index is -1
      @pointerIds.splice index, 1
      return

    recordPointer: (pointer) ->
      return  if @inertiaStatus.active
      index = (if @mouse then 0 else indexOf(@pointerIds, getPointerId(pointer)))
      return  if index is -1
      @pointers[index] = pointer
      return

    fireTaps: (pointer, event, targets, elements) ->
      tap = {}
      i = undefined
      extend tap, event
      extend tap, pointer
      tap.preventDefault = preventOriginalDefault
      tap.stopPropagation = InteractEvent::stopPropagation
      tap.stopImmediatePropagation = InteractEvent::stopImmediatePropagation
      tap.timeStamp = new Date().getTime()
      tap.originalEvent = event
      tap.dt = tap.timeStamp - @downTime
      tap.type = "tap"
      interval = tap.timeStamp - @tapTime
      dbl = (@prevTap and @prevTap.type isnt "doubletap" and @prevTap.target is tap.target and interval < 500)
      @tapTime = tap.timeStamp
      prevTouchTapTime = @tapTime  unless @mouse
      i = 0
      while i < targets.length
        origin = getOriginXY(targets[i], elements[i])
        tap.pageX -= origin.x
        tap.pageY -= origin.y
        tap.clientX -= origin.x
        tap.clientY -= origin.y
        tap.currentTarget = elements[i]
        targets[i].fire tap
        break  if tap.immediatePropagationStopped or (tap.propagationStopped and targets[i + 1] isnt tap.currentTarget)
        i++
      if dbl
        doubleTap = {}
        extend doubleTap, tap
        doubleTap.dt = interval
        doubleTap.type = "doubletap"
        i = 0
        while i < targets.length
          doubleTap.currentTarget = elements[i]
          targets[i].fire doubleTap
          break  if doubleTap.immediatePropagationStopped or (doubleTap.propagationStopped and targets[i + 1] isnt doubleTap.currentTarget)
          i++
        @prevTap = doubleTap
      else
        @prevTap = tap
      return

    collectTaps: (pointer, event, eventTarget) ->
      collectSelectorTaps = (interactable, selector, context) ->
        elements = (if ie8MatchesSelector then context.querySelectorAll(selector) else 'undefined')
        if element isnt document and inContext(interactable, element) and not testIgnore(interactable, element, eventTarget) and testAllow(interactable, element, eventTarget) and matchesSelector(element, selector, elements)
          tapTargets.push interactable
          tapElements.push element
        return
      return  if @pointerWasMoved or not (@downTarget and @downTarget is eventTarget) or (@mouse and (new Date().getTime() - prevTouchTapTime) < 300)
      tapTargets = []
      tapElements = []
      element = eventTarget
      while element
        if interact.isSet(element)
          tapTargets.push interact(element)
          tapElements.push element
        interactables.forEachSelector collectSelectorTaps
        element = element.parentNode
      @fireTaps pointer, event, tapTargets, tapElements  if tapTargets.length
      return

    validateSelector: (pointer, matches, matchElements) ->
      i = 0
      len = matches.length

      while i < len
        match = matches[i]
        matchElement = matchElements[i]
        action = validateAction(match.getAction(pointer, this, matchElement), match)
        if action and withinInteractionLimit(match, matchElement, action)
          @target = match
          @element = matchElement
          return action
        i++
      return

    setSnapping: (pageCoords, status) ->
      snap = @target.options.snap
      anchors = snap.anchors
      page = undefined
      closest = undefined
      range = undefined
      inRange = undefined
      snapChanged = undefined
      dx = undefined
      dy = undefined
      distance = undefined
      i = undefined
      len = undefined
      status = status or @snapStatus
      if status.useStatusXY
        page =
          x: status.x
          y: status.y
      else
        origin = getOriginXY(@target, @element)
        page = extend({}, pageCoords)
        page.x -= origin.x
        page.y -= origin.y
      page.x -= @inertiaStatus.resumeDx
      page.y -= @inertiaStatus.resumeDy
      status.realX = page.x
      status.realY = page.y
      snap.range = Infinity  if snap.range < 0
      if snap.mode is "path"
        anchors = []
        i = 0
        len = snap.paths.length

        while i < len
          path = snap.paths[i]
          path = path(page.x, page.y)  if isFunction(path)
          anchors.push
            x: (if isNumber(path.x) then path.x else page.x)
            y: (if isNumber(path.y) then path.y else page.y)
            range: (if isNumber(path.range) then path.range else snap.range)

          i++
      if (snap.mode is "anchor" or snap.mode is "path") and anchors.length
        closest =
          anchor: null
          distance: 0
          range: 0
          dx: 0
          dy: 0

        i = 0
        len = anchors.length

        while i < len
          anchor = anchors[i]
          range = (if isNumber(anchor.range) then anchor.range else snap.range)
          dx = anchor.x - page.x + @snapOffset.x
          dy = anchor.y - page.y + @snapOffset.y
          distance = hypot(dx, dy)
          inRange = distance < range
          inRange = false  if range is Infinity and closest.inRange and closest.range isnt Infinity
          if not closest.anchor or ((if inRange then (if (closest.inRange and range isnt Infinity) then distance / range < closest.distance / closest.range else distance < closest.distance) else (not closest.inRange and distance < closest.distance)))
            inRange = true  if range is Infinity
            closest.anchor = anchor
            closest.distance = distance
            closest.range = range
            closest.inRange = inRange
            closest.dx = dx
            closest.dy = dy
            status.range = range
          i++
        inRange = closest.inRange
        snapChanged = (closest.anchor.x isnt status.x or closest.anchor.y isnt status.y)
        status.snappedX = closest.anchor.x
        status.snappedY = closest.anchor.y
        status.dx = closest.dx
        status.dy = closest.dy
      else if snap.mode is "grid"
        gridx = Math.round((page.x - snap.gridOffset.x - @snapOffset.x) / snap.grid.x)
        gridy = Math.round((page.y - snap.gridOffset.y - @snapOffset.y) / snap.grid.y)
        newX = gridx * snap.grid.x + snap.gridOffset.x + @snapOffset.x
        newY = gridy * snap.grid.y + snap.gridOffset.y + @snapOffset.y
        dx = newX - page.x
        dy = newY - page.y
        distance = hypot(dx, dy)
        inRange = distance < snap.range
        snapChanged = (newX isnt status.snappedX or newY isnt status.snappedY)
        status.snappedX = newX
        status.snappedY = newY
        status.dx = dx
        status.dy = dy
        status.range = snap.range
      status.changed = (snapChanged or (inRange and not status.locked))
      status.locked = inRange
      status

    setRestriction: (pageCoords, status) ->
      target = @target
      action = (if /resize/.test(@prepared) then "resize" else @prepared)
      restrict = target and target.options.restrict
      restriction = restrict and restrict[action]
      page = undefined
      return status  unless restriction
      status = status or @restrictStatus
      page = (if status.useStatusXY then page =
        x: status.x
        y: status.y
       else page = extend({}, pageCoords))
      if status.snap and status.snap.locked
        page.x += status.snap.dx or 0
        page.y += status.snap.dy or 0
      page.x -= @inertiaStatus.resumeDx
      page.y -= @inertiaStatus.resumeDy
      status.dx = 0
      status.dy = 0
      status.restricted = false
      rect = undefined
      restrictedX = undefined
      restrictedY = undefined
      if isString(restriction)
        if restriction is "parent"
          restriction = @element.parentNode
        else if restriction is "self"
          restriction = target.getRect(@element)
        else
          restriction = matchingParent(@element, restriction)
        return status  unless restriction
      restriction = restriction(page.x, page.y, @element)  if isFunction(restriction)
      restriction = getElementRect(restriction)  if isElement(restriction)
      rect = restriction
      if "x" of restriction and "y" of restriction
        restrictedX = Math.max(Math.min(rect.x + rect.width - @restrictOffset.right, page.x), rect.x + @restrictOffset.left)
        restrictedY = Math.max(Math.min(rect.y + rect.height - @restrictOffset.bottom, page.y), rect.y + @restrictOffset.top)
      else
        restrictedX = Math.max(Math.min(rect.right - @restrictOffset.right, page.x), rect.left + @restrictOffset.left)
        restrictedY = Math.max(Math.min(rect.bottom - @restrictOffset.bottom, page.y), rect.top + @restrictOffset.top)
      status.dx = restrictedX - page.x
      status.dy = restrictedY - page.y
      status.changed = status.restrictedX isnt restrictedX or status.restrictedY isnt restrictedY
      status.restricted = !!(status.dx or status.dy)
      status.restrictedX = restrictedX
      status.restrictedY = restrictedY
      status

    checkAndPreventDefault: (event, interactable, element) ->
      return  unless interactable = interactable or @target
      options = interactable.options
      prevent = options.preventDefault
      if prevent is "auto" and element and not /^input$|^textarea$/i.test(element.nodeName)
        return  if /down|start/i.test(event.type) and @prepared is "drag" and options.dragAxis isnt "xy"
        event.preventDefault()
        return
      if prevent is true
        event.preventDefault()
        return

    calcInertia: (status) ->
      inertiaOptions = @target.options.inertia
      lambda = inertiaOptions.resistance
      inertiaDur = -Math.log(inertiaOptions.endSpeed / status.v0) / lambda
      status.x0 = @prevEvent.pageX
      status.y0 = @prevEvent.pageY
      status.t0 = status.startEvent.timeStamp / 1000
      status.sx = status.sy = 0
      status.modifiedXe = status.xe = (status.vx0 - inertiaDur) / lambda
      status.modifiedYe = status.ye = (status.vy0 - inertiaDur) / lambda
      status.te = inertiaDur
      status.lambda_v0 = lambda / status.v0
      status.one_ve_v0 = 1 - inertiaOptions.endSpeed / status.v0
      return

  InteractEvent:: =
    preventDefault: blank
    stopImmediatePropagation: ->
      @immediatePropagationStopped = @propagationStopped = true
      return

    stopPropagation: ->
      @propagationStopped = true
      return

  listeners = {}
  interactionListeners = [

  ]
  i = 0
  len = interactionListeners.length

  while i < len
    name = interactionListeners[i]
    listeners[name] = doOnInteractions(name)
    i++
  interactables.indexOfElement = indexOfElement = (element, context) ->
    i = 0

    while i < @length
      interactable = this[i]
      return i  if (interactable.selector is element and (interactable._context is (context or document))) or (not interactable.selector and interactable._element is element)
      i++
    -1

  interactables.get = interactableGet = (element, options) ->
    this[@indexOfElement(element, options and options.context)]

  interactables.forEachSelector = (callback) ->
    i = 0

    while i < @length
      interactable = this[i]
      continue  unless interactable.selector
      ret = callback(interactable, interactable.selector, interactable._context, i, this)
      return ret  if ret isnt 'undefined'
      i++
    return

  IOptions:: = defaultOptions
  Interactable:: =
    setOnEvents: (action, phases) ->
      if action is "drop"
        drop = phases.ondrop or phases.onDrop or phases.drop
        dropactivate = phases.ondropactivate or phases.onDropActivate or phases.dropactivate or phases.onactivate or phases.onActivate or phases.activate
        dropdeactivate = phases.ondropdeactivate or phases.onDropDeactivate or phases.dropdeactivate or phases.ondeactivate or phases.onDeactivate or phases.deactivate
        dragenter = phases.ondragenter or phases.onDropEnter or phases.dragenter or phases.onenter or phases.onEnter or phases.enter
        dragleave = phases.ondragleave or phases.onDropLeave or phases.dragleave or phases.onleave or phases.onLeave or phases.leave
        dropmove = phases.ondropmove or phases.onDropMove or phases.dropmove or phases.onmove or phases.onMove or phases.move
        @ondrop = drop  if isFunction(drop)
        @ondropactivate = dropactivate  if isFunction(dropactivate)
        @ondropdeactivate = dropdeactivate  if isFunction(dropdeactivate)
        @ondragenter = dragenter  if isFunction(dragenter)
        @ondragleave = dragleave  if isFunction(dragleave)
        @ondropmove = dropmove  if isFunction(dropmove)
      else
        start = phases.onstart or phases.onStart or phases.start
        move = phases.onmove or phases.onMove or phases.move
        end = phases.onend or phases.onEnd or phases.end
        inertiastart = phases.oninertiastart or phases.onInertiaStart or phases.inertiastart
        action = "on" + action
        this[action + "start"] = start  if isFunction(start)
        this[action + "move"] = move  if isFunction(move)
        this[action + "end"] = end  if isFunction(end)
        this[action + "inertiastart"] = inertiastart  if isFunction(inertiastart)
      this

    draggable: (options) ->
      if isObject(options)
        @options.draggable = true
        @setOnEvents "drag", options
        @options.dragMax = options.max  if isNumber(options.max)
        @options.dragMaxPerElement = options.maxPerElement  if isNumber(options.maxPerElement)
        if /^x$|^y$|^xy$/.test(options.axis)
          @options.dragAxis = options.axis
        else delete @options.dragAxis  if options.axis is null
        return this
      if isBool(options)
        @options.draggable = options
        return this
      if options is null
        delete @options.draggable

        return this
      @options.draggable

    dropzone: (options) ->
      if isObject(options)
        @options.dropzone = true
        @setOnEvents "drop", options
        @accept options.accept
        if /^(pointer|center)$/.test(options.overlap)
          @options.dropOverlap = options.overlap
        else @options.dropOverlap = Math.max(Math.min(1, options.overlap), 0)  if isNumber(options.overlap)
        return this
      if isBool(options)
        @options.dropzone = options
        return this
      if options is null
        delete @options.dropzone

        return this
      @options.dropzone

    dropCheck: (pointer, draggable, draggableElement, dropElement, rect) ->
      return false  unless rect = rect or @getRect(dropElement)
      dropOverlap = @options.dropOverlap
      if dropOverlap is "pointer"
        page = getPageXY(pointer)
        origin = getOriginXY(draggable, draggableElement)
        horizontal = undefined
        vertical = undefined
        page.x += origin.x
        page.y += origin.y
        horizontal = (page.x > rect.left) and (page.x < rect.right)
        vertical = (page.y > rect.top) and (page.y < rect.bottom)
        return horizontal and vertical
      dragRect = draggable.getRect(draggableElement)
      if dropOverlap is "center"
        cx = dragRect.left + dragRect.width / 2
        cy = dragRect.top + dragRect.height / 2
        return cx >= rect.left and cx <= rect.right and cy >= rect.top and cy <= rect.bottom
      if isNumber(dropOverlap)
        overlapArea = (Math.max(0, Math.min(rect.right, dragRect.right) - Math.max(rect.left, dragRect.left)) * Math.max(0, Math.min(rect.bottom, dragRect.bottom) - Math.max(rect.top, dragRect.top)))
        overlapRatio = overlapArea / (dragRect.width * dragRect.height)
        overlapRatio >= dropOverlap

    dropChecker: (checker) ->
      if isFunction(checker)
        @dropCheck = checker
        return this
      @dropCheck

    accept: (newValue) ->
      if isElement(newValue)
        @options.accept = newValue
        return this
      if trySelector(newValue)
        @options.accept = newValue
        return this
      if newValue is null
        delete @options.accept

        return this
      @options.accept

    resizable: (options) ->
      if isObject(options)
        @options.resizable = true
        @setOnEvents "resize", options
        @options.resizeMax = options.max  if isNumber(options.max)
        @options.resizeMaxPerElement = options.maxPerElement  if isNumber(options.maxPerElement)
        if /^x$|^y$|^xy$/.test(options.axis)
          @options.resizeAxis = options.axis
        else @options.resizeAxis = defaultOptions.resizeAxis  if options.axis is null
        return this
      if isBool(options)
        @options.resizable = options
        return this
      @options.resizable

    resizeable: blank
    squareResize: (newValue) ->
      if isBool(newValue)
        @options.squareResize = newValue
        return this
      if newValue is null
        delete @options.squareResize

        return this
      @options.squareResize

    gesturable: (options) ->
      if isObject(options)
        @options.gesturable = true
        @setOnEvents "gesture", options
        @options.gestureMax = options.max  if isNumber(options.max)
        @options.gestureMaxPerElement = options.maxPerElement  if isNumber(options.maxPerElement)
        return this
      if isBool(options)
        @options.gesturable = options
        return this
      if options is null
        delete @options.gesturable

        return this
      @options.gesturable

    gestureable: blank
    autoScroll: (options) ->
      defaults = defaultOptions.autoScroll
      if isObject(options)
        autoScroll = @options.autoScroll
        if autoScroll is defaults
          autoScroll = @options.autoScroll =
            margin: defaults.margin
            distance: defaults.distance
            interval: defaults.interval
            container: defaults.container
        autoScroll.margin = @validateSetting("autoScroll", "margin", options.margin)
        autoScroll.speed = @validateSetting("autoScroll", "speed", options.speed)
        autoScroll.container = ((if isElement(options.container) or options.container instanceof window.Window then options.container else defaults.container))
        @options.autoScrollEnabled = true
        @options.autoScroll = autoScroll
        return this
      if isBool(options)
        @options.autoScrollEnabled = options
        return this
      if options is null
        delete @options.autoScrollEnabled

        delete @options.autoScroll

        return this
      (if @options.autoScrollEnabled then @options.autoScroll else false)

    snap: (options) ->
      defaults = defaultOptions.snap
      if isObject(options)
        snap = @options.snap
        snap = {}  if snap is defaults
        snap.mode = @validateSetting("snap", "mode", options.mode)
        snap.endOnly = @validateSetting("snap", "endOnly", options.endOnly)
        snap.actions = @validateSetting("snap", "actions", options.actions)
        snap.range = @validateSetting("snap", "range", options.range)
        snap.paths = @validateSetting("snap", "paths", options.paths)
        snap.grid = @validateSetting("snap", "grid", options.grid)
        snap.gridOffset = @validateSetting("snap", "gridOffset", options.gridOffset)
        snap.anchors = @validateSetting("snap", "anchors", options.anchors)
        snap.elementOrigin = @validateSetting("snap", "elementOrigin", options.elementOrigin)
        @options.snapEnabled = true
        @options.snap = snap
        return this
      if isBool(options)
        @options.snapEnabled = options
        return this
      if options is null
        delete @options.snapEnabled

        delete @options.snap

        return this
      (if @options.snapEnabled then @options.snap else false)

    inertia: (options) ->
      defaults = defaultOptions.inertia
      if isObject(options)
        inertia = @options.inertia
        if inertia is defaults
          inertia = @options.inertia =
            resistance: defaults.resistance
            minSpeed: defaults.minSpeed
            endSpeed: defaults.endSpeed
            actions: defaults.actions
            allowResume: defaults.allowResume
            zeroResumeDelta: defaults.zeroResumeDelta
            smoothEndDuration: defaults.smoothEndDuration
        inertia.resistance = @validateSetting("inertia", "resistance", options.resistance)
        inertia.minSpeed = @validateSetting("inertia", "minSpeed", options.minSpeed)
        inertia.endSpeed = @validateSetting("inertia", "endSpeed", options.endSpeed)
        inertia.actions = @validateSetting("inertia", "actions", options.actions)
        inertia.allowResume = @validateSetting("inertia", "allowResume", options.allowResume)
        inertia.zeroResumeDelta = @validateSetting("inertia", "zeroResumeDelta", options.zeroResumeDelta)
        inertia.smoothEndDuration = @validateSetting("inertia", "smoothEndDuration", options.smoothEndDuration)
        @options.inertiaEnabled = true
        @options.inertia = inertia
        return this
      if isBool(options)
        @options.inertiaEnabled = options
        return this
      if options is null
        delete @options.inertiaEnabled

        delete @options.inertia

        return this
      (if @options.inertiaEnabled then @options.inertia else false)

    getAction: (pointer, interaction, element) ->
      action = @defaultActionChecker(pointer, interaction, element)
      action = @options.actionChecker(pointer, action, this, element, interaction)  if @options.actionChecker
      action

    defaultActionChecker: defaultActionChecker
    actionChecker: (newValue) ->
      if isFunction(newValue)
        @options.actionChecker = newValue
        return this
      if newValue is null
        delete @options.actionChecker

        return this
      @options.actionChecker

    getRect: rectCheck = (element) ->
      element = element or @_element
      element = @_context.querySelector(@selector)  if @selector and not (isElement(element))
      getElementRect element

    rectChecker: (checker) ->
      if isFunction(checker)
        @getRect = checker
        return this
      if checker is null
        delete @options.getRect

        return this
      @getRect

    styleCursor: (newValue) ->
      if isBool(newValue)
        @options.styleCursor = newValue
        return this
      if newValue is null
        delete @options.styleCursor

        return this
      @options.styleCursor

    preventDefault: (newValue) ->
      if isBool(newValue) or newValue is "auto"
        @options.preventDefault = newValue
        return this
      if newValue is null
        delete @options.preventDefault

        return this
      @options.preventDefault

    origin: (newValue) ->
      if trySelector(newValue)
        @options.origin = newValue
        return this
      else if isObject(newValue)
        @options.origin = newValue
        return this
      if newValue is null
        delete @options.origin

        return this
      @options.origin

    deltaSource: (newValue) ->
      if newValue is "page" or newValue is "client"
        @options.deltaSource = newValue
        return this
      if newValue is null
        delete @options.deltaSource

        return this
      @options.deltaSource

    restrict: (newValue) ->
      return @options.restrict  if newValue is 'undefined'
      if isBool(newValue)
        defaultOptions.restrictEnabled = newValue
      else if isObject(newValue)
        newRestrictions = {}
        newRestrictions.drag = newValue.drag  if isObject(newValue.drag) or trySelector(newValue.drag)
        newRestrictions.resize = newValue.resize  if isObject(newValue.resize) or trySelector(newValue.resize)
        newRestrictions.gesture = newValue.gesture  if isObject(newValue.gesture) or trySelector(newValue.gesture)
        newRestrictions.endOnly = newValue.endOnly  if isBool(newValue.endOnly)
        newRestrictions.elementRect = newValue.elementRect  if isObject(newValue.elementRect)
        @options.restrictEnabled = true
        @options.restrict = newRestrictions
      else if newValue is null
        delete @options.restrict

        delete @options.restrictEnabled
      this

    context: ->
      @_context

    _context: document
    ignoreFrom: (newValue) ->
      if trySelector(newValue)
        @options.ignoreFrom = newValue
        return this
      if isElement(newValue)
        @options.ignoreFrom = newValue
        return this
      if newValue is null
        delete @options.ignoreFrom

        return this
      @options.ignoreFrom

    allowFrom: (newValue) ->
      if trySelector(newValue)
        @options.allowFrom = newValue
        return this
      if isElement(newValue)
        @options.allowFrom = newValue
        return this
      if newValue is null
        delete @options.allowFrom

        return this
      @options.allowFrom

    validateSetting: (context, option, value) ->
      defaults = defaultOptions[context]
      current = @options[context]
      if defaults isnt 'undefined' and defaults[option] isnt 'undefined'
        if "objectTypes" of defaults and defaults.objectTypes.test(option)
          if isObject(value)
            return value
          else
            return ((if option of current and isObject(current[option]) then current[option] else defaults[option]))
        if "arrayTypes" of defaults and defaults.arrayTypes.test(option)
          if isArray(value)
            return value
          else
            return ((if option of current and isArray(current[option]) then current[option] else defaults[option]))
        if "stringTypes" of defaults and defaults.stringTypes.test(option)
          if isString(value)
            return value
          else
            return ((if option of current and isString(current[option]) then current[option] else defaults[option]))
        if "numberTypes" of defaults and defaults.numberTypes.test(option)
          if isNumber(value)
            return value
          else
            return ((if option of current and isNumber(current[option]) then current[option] else defaults[option]))
        if "boolTypes" of defaults and defaults.boolTypes.test(option)
          if isBool(value)
            return value
          else
            return ((if option of current and isBool(current[option]) then current[option] else defaults[option]))
        if "elementTypes" of defaults and defaults.elementTypes.test(option)
          if isElement(value)
            return value
          else
            return ((if option of current and isElement(current[option]) then current[option] else defaults[option]))
      null

    element: ->
      @_element

    fire: (iEvent) ->
      return this  if not (iEvent and iEvent.type) or not contains(eventTypes, iEvent.type)
      listeners = undefined
      i = undefined
      len = undefined
      onEvent = "on" + iEvent.type
      funcName = ""
      if iEvent.type of @_iEvents
        listeners = @_iEvents[iEvent.type]
        i = 0
        len = listeners.length

        while i < len and not iEvent.immediatePropagationStopped
          funcName = listeners[i].name
          listeners[i] iEvent
          i++
      if isFunction(this[onEvent])
        funcName = this[onEvent].name
        this[onEvent] iEvent
      if iEvent.type of globalEvents and (listeners = globalEvents[iEvent.type])
        i = 0
        len = listeners.length

        while i < len and not iEvent.immediatePropagationStopped
          funcName = listeners[i].name
          listeners[i] iEvent
          i++
      this

    on: (eventType, listener, useCapture) ->
      eventType = wheelEvent  if eventType is "wheel"
      useCapture = (if useCapture then true else false)
      if contains(eventTypes, eventType)
        unless eventType of @_iEvents
          @_iEvents[eventType] = [listener]
        else @_iEvents[eventType].push listener  unless contains(@_iEvents[eventType], listener)
      else if @selector
        unless delegatedEvents[eventType]
          delegatedEvents[eventType] =
            selectors: []
            contexts: []
            listeners: []

          events.addToElement @_context, eventType, delegateListener
          events.addToElement @_context, eventType, delegateUseCapture, true
        delegated = delegatedEvents[eventType]
        index = undefined
        index = delegated.selectors.length - 1
        while index >= 0
          break  if delegated.selectors[index] is @selector and delegated.contexts[index] is @_context
          index--
        if index is -1
          index = delegated.selectors.length
          delegated.selectors.push @selector
          delegated.contexts.push @_context
          delegated.listeners.push []
        delegated.listeners[index].push [

        ]
      else
        events.add this, eventType, listener, useCapture
      this

    off: (eventType, listener, useCapture) ->
      eventList = undefined
      index = -1
      useCapture = (if useCapture then true else false)
      eventType = wheelEvent  if eventType is "wheel"
      if contains(eventTypes, eventType)
        eventList = @_iEvents[eventType]
        @_iEvents[eventType].splice index, 1  if eventList and (index = indexOf(eventList, listener)) isnt -1
      else if @selector
        delegated = delegatedEvents[eventType]
        matchFound = false
        return this  unless delegated
        index = delegated.selectors.length - 1
        while index >= 0
          if delegated.selectors[index] is @selector and delegated.contexts[index] is @_context
            listeners = delegated.listeners[index]
            i = listeners.length - 1

            while i >= 0
              fn = listeners[i][0]
              useCap = listeners[i][1]
              if fn is listener and useCap is useCapture
                listeners.splice i, 1
                unless listeners.length
                  delegated.selectors.splice index, 1
                  delegated.contexts.splice index, 1
                  delegated.listeners.splice index, 1
                  events.removeFromElement @_context, eventType, delegateListener
                  events.removeFromElement @_context, eventType, delegateUseCapture, true
                  delegatedEvents[eventType] = null  unless delegated.selectors.length
                matchFound = true
                break
              i--
            break  if matchFound
          index--
      else
        events.remove this, listener, useCapture
      this

    set: (options) ->
      options = {}  if not options or not isObject(options)
      @options = new IOptions(options)
      @draggable (if "draggable" of options then options.draggable else @options.draggable)
      @dropzone (if "dropzone" of options then options.dropzone else @options.dropzone)
      @resizable (if "resizable" of options then options.resizable else @options.resizable)
      @gesturable (if "gesturable" of options then options.gesturable else @options.gesturable)
      settings = [

      ]
      i = 0
      len = settings.length

      while i < len
        setting = settings[i]
        this[setting] options[setting]  if setting of options
        i++
      this

    unset: ->
      events.remove this, "all"
      unless isString(@selector)
        events.remove this, "all"
        @_element.style.cursor = ""  if @options.styleCursor
      else
        for type of delegatedEvents
          delegated = delegatedEvents[type]
          i = 0

          while i < delegated.selectors.length
            if delegated.selectors[i] is @selector and delegated.contexts[i] is @_context
              delegated.selectors.splice i, 1
              delegated.contexts.splice i, 1
              delegated.listeners.splice i, 1
              delegatedEvents[type] = null  unless delegated.selectors.length
            events.removeFromElement @_context, type, delegateListener
            events.removeFromElement @_context, type, delegateUseCapture, true
            break
            i++
      @dropzone false
      interactables.splice indexOf(interactables, this), 1
      interact

  Interactable::gestureable = Interactable::gesturable
  Interactable::resizeable = Interactable::resizable
  interact.isSet = (element, options) ->
    interactables.indexOfElement(element, options and options.context) isnt -1

  interact.on = (type, listener, useCapture) ->
    if contains(eventTypes, type)
      unless globalEvents[type]
        globalEvents[type] = [listener]
      else globalEvents[type].push listener  unless contains(globalEvents[type], listener)
    else
      events.add docTarget, type, listener, useCapture
    interact

  interact.off = (type, listener, useCapture) ->
    unless contains(eventTypes, type)
      events.remove docTarget, type, listener, useCapture
    else
      index = undefined
      globalEvents[type].splice index, 1  if type of globalEvents and (index = indexOf(globalEvents[type], listener)) isnt -1
    interact

  interact.simulate = (action, element, pointerEvent) ->
    event = {}
    clientRect = undefined
    action = "resizexy"  if action is "resize"
    return interact  unless /^(drag|resizexy|resizex|resizey)$/.test(action)
    if pointerEvent
      extend event, pointerEvent
    else
      clientRect = (if (element instanceof SVGElement) then element.getBoundingClientRect() else clientRect = element.getClientRects()[0])
      if action is "drag"
        event.pageX = clientRect.left + clientRect.width / 2
        event.pageY = clientRect.top + clientRect.height / 2
      else
        event.pageX = clientRect.right
        event.pageY = clientRect.bottom
    event.target = event.currentTarget = element
    event.preventDefault = event.stopPropagation = blank
    listeners.pointerDown event, action
    interact

  interact.enableDragging = (newValue) ->
    if newValue isnt null and newValue isnt 'undefined'
      actionIsEnabled.drag = newValue
      return interact
    actionIsEnabled.drag

  interact.enableResizing = (newValue) ->
    if newValue isnt null and newValue isnt 'undefined'
      actionIsEnabled.resize = newValue
      return interact
    actionIsEnabled.resize

  interact.enableGesturing = (newValue) ->
    if newValue isnt null and newValue isnt 'undefined'
      actionIsEnabled.gesture = newValue
      return interact
    actionIsEnabled.gesture

  interact.eventTypes = eventTypes
  interact.debug = ->
    interaction = interactions[0] or new Interaction()
    interactions: interactions
    target: interaction.target
    dragging: interaction.dragging
    resizing: interaction.resizing
    gesturing: interaction.gesturing
    prepared: interaction.prepared
    matches: interaction.matches
    matchElements: interaction.matchElements
    prevCoords: interaction.prevCoords
    startCoords: interaction.startCoords
    pointerIds: interaction.pointerIds
    pointers: interaction.pointers
    addPointer: listeners.addPointer
    removePointer: listeners.removePointer
    recordPointer: listeners.recordPointer
    snap: interaction.snapStatus
    restrict: interaction.restrictStatus
    inertia: interaction.inertiaStatus
    downTime: interaction.downTime
    downEvent: interaction.downEvent
    downPointer: interaction.downPointer
    prevEvent: interaction.prevEvent
    Interactable: Interactable
    IOptions: IOptions
    interactables: interactables
    pointerIsDown: interaction.pointerIsDown
    defaultOptions: defaultOptions
    defaultActionChecker: defaultActionChecker
    actionCursors: actionCursors
    dragMove: listeners.dragMove
    resizeMove: listeners.resizeMove
    gestureMove: listeners.gestureMove
    pointerUp: listeners.pointerUp
    pointerDown: listeners.pointerDown
    pointerMove: listeners.pointerMove
    pointerHover: listeners.pointerHover
    events: events
    globalEvents: globalEvents
    delegatedEvents: delegatedEvents

  interact.getTouchAverage = touchAverage
  interact.getTouchBBox = touchBBox
  interact.getTouchDistance = touchDistance
  interact.getTouchAngle = touchAngle
  interact.getElementRect = getElementRect
  interact.matchesSelector = matchesSelector
  interact.margin = (newvalue) ->
    if isNumber(newvalue)
      margin = newvalue
      return interact
    margin

  interact.styleCursor = (newValue) ->
    if isBool(newValue)
      defaultOptions.styleCursor = newValue
      return interact
    defaultOptions.styleCursor

  interact.autoScroll = (options) ->
    defaults = defaultOptions.autoScroll
    if isObject(options)
      defaultOptions.autoScrollEnabled = true
      defaults.margin = options.margin  if isNumber(options.margin)
      defaults.speed = options.speed  if isNumber(options.speed)
      defaults.container = ((if isElement(options.container) or options.container instanceof window.Window then options.container else defaults.container))
      return interact
    if isBool(options)
      defaultOptions.autoScrollEnabled = options
      return interact
    (if defaultOptions.autoScrollEnabled then defaults else false)

  interact.snap = (options) ->
    snap = defaultOptions.snap
    if isObject(options)
      defaultOptions.snapEnabled = true
      snap.mode = options.mode  if isString(options.mode)
      snap.endOnly = options.endOnly  if isBool(options.endOnly)
      snap.range = options.range  if isNumber(options.range)
      snap.actions = options.actions  if isArray(options.actions)
      snap.anchors = options.anchors  if isArray(options.anchors)
      snap.grid = options.grid  if isObject(options.grid)
      snap.gridOffset = options.gridOffset  if isObject(options.gridOffset)
      snap.elementOrigin = options.elementOrigin  if isObject(options.elementOrigin)
      return interact
    if isBool(options)
      defaultOptions.snapEnabled = options
      return interact
    defaultOptions.snapEnabled

  interact.inertia = (options) ->
    inertia = defaultOptions.inertia
    if isObject(options)
      defaultOptions.inertiaEnabled = true
      inertia.resistance = options.resistance  if isNumber(options.resistance)
      inertia.minSpeed = options.minSpeed  if isNumber(options.minSpeed)
      inertia.endSpeed = options.endSpeed  if isNumber(options.endSpeed)
      inertia.smoothEndDuration = options.smoothEndDuration  if isNumber(options.smoothEndDuration)
      inertia.allowResume = options.allowResume  if isBool(options.allowResume)
      inertia.zeroResumeDelta = options.zeroResumeDelta  if isBool(options.zeroResumeDelta)
      inertia.actions = options.actions  if isArray(options.actions)
      return interact
    if isBool(options)
      defaultOptions.inertiaEnabled = options
      return interact
    enabled: defaultOptions.inertiaEnabled
    resistance: inertia.resistance
    minSpeed: inertia.minSpeed
    endSpeed: inertia.endSpeed
    actions: inertia.actions
    allowResume: inertia.allowResume
    zeroResumeDelta: inertia.zeroResumeDelta

  interact.supportsTouch = ->
    supportsTouch

  interact.supportsPointerEvent = ->
    supportsPointerEvent

  interact.currentAction = ->
    i = 0
    len = interactions.length

    while i < len
      action = interactions[i].currentAction()
      return action  if action
      i++
    null

  interact.stop = (event) ->
    i = interactions.length - 1

    while i > 0
      interactions[i].stop event
      i--
    interact

  interact.dynamicDrop = (newValue) ->
    if isBool(newValue)
      dynamicDrop = newValue
      return interact
    dynamicDrop

  interact.deltaSource = (newValue) ->
    if newValue is "page" or newValue is "client"
      defaultOptions.deltaSource = newValue
      return this
    defaultOptions.deltaSource

  interact.restrict = (newValue) ->
    defaults = defaultOptions.restrict
    return defaultOptions.restrict  if newValue is 'undefined'
    if isBool(newValue)
      defaultOptions.restrictEnabled = newValue
    else if isObject(newValue)
      defaults.drag = newValue.drag  if isObject(newValue.drag) or /^parent$|^self$/.test(newValue.drag)
      defaults.resize = newValue.resize  if isObject(newValue.resize) or /^parent$|^self$/.test(newValue.resize)
      defaults.gesture = newValue.gesture  if isObject(newValue.gesture) or /^parent$|^self$/.test(newValue.gesture)
      defaults.endOnly = newValue.endOnly  if isBool(newValue.endOnly)
      defaults.elementRect = newValue.elementRect  if isObject(newValue.elementRect)
      defaultOptions.restrictEnabled = true
    else if newValue is null
      defaults.drag = defaults.resize = defaults.gesture = null
      defaults.endOnly = false
    this

  interact.pointerMoveTolerance = (newValue) ->
    if isNumber(newValue)
      defaultOptions.pointerMoveTolerance = newValue
      return this
    defaultOptions.pointerMoveTolerance

  interact.maxInteractions = (newValue) ->
    if isNumber(newValue)
      maxInteractions = newValue
      return this
    maxInteractions

  if PointerEvent
    if PointerEvent is window.MSPointerEvent
      pEventTypes =
        up: "MSPointerUp"
        down: "MSPointerDown"
        over: "mouseover"
        out: "mouseout"
        move: "MSPointerMove"
        cancel: "MSPointerCancel"
    else
      pEventTypes =
        up: "pointerup"
        down: "pointerdown"
        over: "pointerover"
        out: "pointerout"
        move: "pointermove"
        cancel: "pointercancel"
    events.add docTarget, pEventTypes.up, listeners.collectTaps
    events.add docTarget, pEventTypes.move, listeners.recordPointer
    events.add docTarget, pEventTypes.down, listeners.selectorDown
    events.add docTarget, pEventTypes.move, listeners.pointerMove
    events.add docTarget, pEventTypes.up, listeners.pointerUp
    events.add docTarget, pEventTypes.over, listeners.pointerOver
    events.add docTarget, pEventTypes.out, listeners.pointerOut
    events.add docTarget, pEventTypes.up, listeners.removePointer
    events.add docTarget, pEventTypes.cancel, listeners.removePointer
    events.add docTarget, pEventTypes.move, autoScroll.edgeMove
  else
    events.add docTarget, "mouseup", listeners.collectTaps
    events.add docTarget, "touchend", listeners.collectTaps
    events.add docTarget, "mousemove", listeners.recordPointer
    events.add docTarget, "touchmove", listeners.recordPointer
    events.add docTarget, "mousedown", listeners.selectorDown
    events.add docTarget, "mousemove", listeners.pointerMove
    events.add docTarget, "mouseup", listeners.pointerUp
    events.add docTarget, "mouseover", listeners.pointerOver
    events.add docTarget, "mouseout", listeners.pointerOut
    events.add docTarget, "touchstart", listeners.selectorDown
    events.add docTarget, "touchmove", listeners.pointerMove
    events.add docTarget, "touchend", listeners.pointerUp
    events.add docTarget, "touchcancel", listeners.pointerUp
    events.add docTarget, "touchend", listeners.removePointer
    events.add docTarget, "touchcancel", listeners.removePointer
    events.add docTarget, "mousemove", autoScroll.edgeMove
    events.add docTarget, "touchmove", autoScroll.edgeMove
  events.add windowTarget, "blur", endAllInteractions
  try
    if window.frameElement
      parentDocTarget._element = window.frameElement.ownerDocument
      events.add parentDocTarget, "mouseup", listeners.pointerUp
      events.add parentDocTarget, "touchend", listeners.pointerUp
      events.add parentDocTarget, "touchcancel", listeners.pointerUp
      events.add parentDocTarget, "pointerup", listeners.pointerUp
      events.add parentDocTarget, "MSPointerUp", listeners.pointerUp
      events.add parentWindowTarget, "blur", endAllInteractions
  catch error
    interact.windowParentError = error
  if events.useAttachEvent
    events.add docTarget, "selectstart", (event) ->
      interaction = interactions[0]
      interaction.checkAndPreventDefault event  if interaction.currentAction()
      return


  # For IE8's lack of an Element#matchesSelector
  # taken from http://tanalin.com/en/blog/2012/12/matches-selector-ie8/ and modified
  if (prefixedMatchesSelector not of Element::) or not isFunction(Element::[prefixedMatchesSelector])
    ie8MatchesSelector = (element, selector, elems) ->
      elems = elems or element.parentNode.querySelectorAll(selector)
      i = 0
      len = elems.length

      while i < len
        return true  if elems[i] is element
        i++
      false

  # requestAnimationFrame polyfill
  (->
    lastTime = 0
    vendors = [

    ]
    x = 0

    while x < vendors.length and not window.requestAnimationFrame
      reqFrame = window[vendors[x] + "RequestAnimationFrame"]
      cancelFrame = window[vendors[x] + "CancelAnimationFrame"] or window[vendors[x] + "CancelRequestAnimationFrame"]
      ++x
    unless reqFrame
      reqFrame = (callback) ->
        currTime = new Date().getTime()
        timeToCall = Math.max(0, 16 - (currTime - lastTime))
        id = window.setTimeout(->
          callback currTime + timeToCall
          return
        , timeToCall)
        lastTime = currTime + timeToCall
        id
    unless cancelFrame
      cancelFrame = (id) ->
        clearTimeout id
        return
    return
  )()

  # global exports: true, module, define

  # http://documentcloud.github.io/underscore/docs/underscore.html#section-11
  if typeof exports isnt "undefined"
    exports = module.exports = interact  if typeof module isnt "undefined" and module.exports
    exports.interact = interact

  # AMD
  else if typeof define is "function" and define.amd
    define "interact", ->
      interact

  else
    window.interact = interact
  return
)()
