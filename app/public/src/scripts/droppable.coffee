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

  class Droppable
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
