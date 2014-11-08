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
