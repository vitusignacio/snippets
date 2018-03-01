class ValidationHelper
  # Class attributes
  @_sharedAttributes:
    constants:
      language: navigator.language or navigator.userLanguage
      regex_email: /^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/
    classes:
      sj_form_group: '.sj-form-element'
      sj_form_validation_indicator: '.sj-validation-indicator'
      sj_form_validation_message: '.sj-validation-message'
      validation_error: 'has-error'
    errors:
      CUSTOM_FUNCTION_NOT_DEFINED: Error('The custom function is not defined')
      CUSTOM_FUNCTION_NOT_RETURN_BOOLEAN: Error('The custom function does not return a proper result object with boolean value')
      FORM_DATA_IS_NULL: Error('Form data is null')
      NO_CUSTOM_ERROR_PROVIDED: Error('No custom error message is provided')
      RESULTING_VALUE_INVALID: Error('The resulting value is not a valid object')
      VALIDATION_URL_FORM_ID_MUST_NOT_BE_NULL: Error('The form identifier must not be null')
    templates:
      validation_error: '<span>{message}</span><br />'
    helpers:
      friendly_name: 'sj-friendly-name'
    validators:
      custom: 'sj-custom'
      custom_message: 'sj-custom-message'
      email: 'sj-email'
      email_message: 'sj-email-message'
      required: 'sj-required'
      required_message: 'sj-required-message'
      regex: 'sj-regex'
      regex_message: 'sj-regex-message'
  # Instance attributes
  _currentState:
    stateId: null
    others: []
  _customValidators: new Object()
  _formId: null
  _isValid: true
  _localeInfo: null
  _validationUrl: null
  _validationUrlMethod: 'GET'
  _validationResult:
    error: false
    messages: []
  # Class content
  constructor: (formId, validationUrl, localeInfo, customValidators) ->
    @_customValidators = customValidators
    @_formId = formId
    if moment?
      if localeInfo?
        @_localeInfo = localeInfo.dateFormat
      else
        locale = moment.localeData(ValidationHelper._sharedAttributes.constants.language)
        if locale?
          @_localeInfo = locale.longDateFormat('L')
    @_validationUrl = validationUrl
    @loadStateFromServer()
  fetchState: ->
    if localStorage?
      localStorage.getItem('stateId')
  setState: ->
    if localStorage?
      localStorage.setItem('stateId', (new Date()).getTime())
    return
  loadStateFromServer: ->
    # Make AJAX call to get state and other attributes
    if localStorage?
      localStorage.setItem('stateId', (new Date()).getTime())
    @_currentState.stateId = (new Date()).getTime()
    @_currentState.others = []
    return
  addValidation: (validator) ->
    @_validationResult.messages.push validator
  disableSubmitButton: ->
    $(@_formId).find(':input[type=submit]').prop 'disabled', true
  enableSubmitButton: ->
    $(@_formId).find(':input[type=submit]').prop 'disabled', false
  hideValidationIndicator: ->
    $(@_formId).find(ValidationHelper._sharedAttributes.classes.sj_form_validation_indicator).fadeOut(50)
  showValidation: (elem, validator) ->
    i = elem.parents(ValidationHelper._sharedAttributes.classes.sj_form_group).find(ValidationHelper._sharedAttributes.classes.sj_form_validation_message)
    j = elem.parents(ValidationHelper._sharedAttributes.classes.sj_form_group)
    if i.length?
      $(i).html('')
      $(i).css('display', 'none')
      if validator.message.length > 0
        for message in validator.message
          $(i).append(ValidationHelper._sharedAttributes.templates.validation_error.replace('{message}', message))
        $(j).addClass ValidationHelper._sharedAttributes.classes.validation_error
        $(i).show()
      else
        $(j).removeClass ValidationHelper._sharedAttributes.classes.validation_error
  showValidationIndicator: ->
    $(@_formId).find(ValidationHelper._sharedAttributes.classes.sj_form_validation_indicator).fadeIn(50)
  processValidation: (resolve, formData) ->
    self = @
    $.each(@_validationResult.messages, (i, j) ->
      if j.message.length > 0
        self._validationResult.error = true
      elem = $(self._formId + ' [name="' + j.name + '"]')
      self.showValidation elem, j
    )
    @_isValid = false if @_validationResult.error == true
    if @_isValid == true
      resolve(
        result: true
        formData: formData
      )
    else
      resolve(
        result: false
        formData: formData
      )
  replacePlaceholders: (message, data, elem) ->
    if elem?
      friendlyName = elem.attr(ValidationHelper._sharedAttributes.helpers.friendly_name)
      console.log friendlyName
      if friendlyName?
        return message.replace('{field}', friendlyName)
    
    return message.replace('{field}', data.name)
  serializeForm: ->
    data = $(@_formId).serializeArray()
    # Get additional fields data
    $(@_formId + ' :input[name]').each( (index, el) ->
      elem = $(el)
      type = elem.prop('type')
      name = elem.prop('name')
      names = []
      for i,j of data
        names.push j.name
      if (names.indexOf(name) == -1)
        value = switch type
          when 'checkbox'
            if elem.is(':checked')
              elem.val()
            else
              ''
          when 'file' then elem.val()
          when 'radio'
            if elem.is(':checked')
              elem.val()
            else
              ''
          else 'na'
        if value isnt 'na'
          data.push
            name: name
            value: value
    )
    data
  validate: ->
    self = @
    formData = @serializeForm()
    @disableSubmitButton()
    @showValidationIndicator()
    new Promise(
      (resolve, reject) ->
        if formData?
          if (self._validationUrl isnt null or self._validationUrl is null) and self._formId isnt null
            # Reset form validity and validation result
            self._isValid = true
            self._validationResult =
              error: false
              messages: []
            # Do some static validation
            for i, j of formData
              elem = $(self._formId + ' [name="' + j.name + '"]')
              validatorErrors = []
              for m, n of ValidationHelper._sharedAttributes.validators
                k = elem.attr(n.toString())
                if k?
                  switch n
                    when ValidationHelper._sharedAttributes.validators.custom # this requires sj-custom and/or sj-custom-message
                      message = elem.attr(ValidationHelper._sharedAttributes.validators.custom_message)
                      if k.length?
                        for l, func of self._customValidators
                          if func?
                            if func.name is k
                              fResult = func.call this, elem, j.name, j.value
                              if fResult is false
                                if message?
                                  validatorErrors.push self.replacePlaceholders(message, j, elem)
                    when ValidationHelper._sharedAttributes.validators.email # sj-email and/or sj-email-message
                      message = elem.attr(ValidationHelper._sharedAttributes.validators.email_message)
                      unless ValidationHelper._sharedAttributes.constants.regex_email.test j.value
                        if message?
                          validatorErrors.push self.replacePlaceholders(message, j, elem)
                    when ValidationHelper._sharedAttributes.validators.regex # sj-regex and/or sj-regex-message
                      regex = new RegExp(elem.attr(n))
                      message = elem.attr(ValidationHelper._sharedAttributes.validators.regex_message)
                      unless regex.test j.value
                        if message?
                          validatorErrors.push self.replacePlaceholders(message, j, elem)
                    when ValidationHelper._sharedAttributes.validators.required # sj-required and/or sj-required-message
                      message = elem.attr(ValidationHelper._sharedAttributes.validators.required_message)
                      if j.value.length is 0
                        if message?
                          validatorErrors.push self.replacePlaceholders(message, j, elem)
                    else 
                      break
              self.addValidation
                name: j.name,
                message: validatorErrors
            # Make AJAX call to server to get validation data
            if self._validationUrl?
              $.ajax(
                type: self._validationUrlMethod
                data: formData
                url: self._validationUrl
                ).done( (response) ->
                  if (response?)
                    for i, j of response.messages
                      for m, n of self._validationResult.messages
                        if (n.name == j.name)
                          if j.message.length > 0
                            for message in j.message
                              n.message.push message
                          break
                    self.processValidation(resolve, formData)
                    self.enableSubmitButton()
                    self.hideValidationIndicator()
                  return
                ).fail( -> 
                  console.warn 'Failed to contact validation service, fall back to client side validation'
                  self.processValidation(resolve, formData)
                  self.enableSubmitButton()
                  self.hideValidationIndicator()
                )
            else
              self.processValidation(resolve, formData)
              self.enableSubmitButton()
              self.hideValidationIndicator()
            return
            # to here
          else
            reject(ValidationHelper._sharedAttributes.errors.VALIDATION_URL_FORM_ID_MUST_NOT_BE_NULL)
            return
        else
          reject(ValidationHelper._sharedAttributes.errors.FORM_DATA_IS_NULL)
          return
    )

module.exports = ValidationHelper
