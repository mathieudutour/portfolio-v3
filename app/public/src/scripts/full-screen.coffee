do (window, document) ->
  class FullScreen
    constructor: (@element, @background) ->
      @classNameExpanded = 'expanded'
      @classNameAnimating = 'animating'

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
      @close.addEventListener('click', @onClose)

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
