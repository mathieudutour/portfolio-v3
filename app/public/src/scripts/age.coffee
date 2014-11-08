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
      @fraction = (((new Date().getTime() - @birthday) / @number_of_millisecond_in_a_year).toFixed(@precision) * 1000000000).toString()

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
