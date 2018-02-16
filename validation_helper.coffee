class ValidationHelper
  # Class attributes
  @_sharedAttributes:
    constants:
      regex_email: /^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/
    classes:
      bootstrap_form_group: '.sj-form-element'
      validation_error: 'has-error'
    errors:
      CUSTOM_FUNCTION_NOT_DEFINED: Error('The custom function is not defined')
      CUSTOM_FUNCTION_NOT_RETURN_BOOLEAN: Error('The custom function does not return a proper result object with boolean value')
      FORM_DATA_IS_NULL: Error('Form data is null')
      RESULTING_VALUE_INVALID: Error('The resulting value is not a valid object')
      VALIDATION_URL_FORM_ID_MUST_NOT_BE_NULL: Error('The form identifier must not be null')
    messages:
      IS_REQUIRED: 'the field {name} is required.'
      IS_INVALID_EMAIL: 'the field {name} is not a valid email.'
    templates:
      validation_error: '<span>{message}</span><br />'
    validators:
      required: 'sj-required'
      custom: 'sj-custom'
      email: 'sj-email'
  # Instance attributes
  _currentState:
    stateId: null
    others: []
  _customValidators: new Object()
  _formId: null
  _isValid: true
  _validationUrl: null
  _validationUrlMethod: 'GET'
  _validationResult:
    error: false
    messages: []
  # Class content
  constructor: (formId, validationUrl, customValidators) ->
    @_customValidators = customValidators
    @_formId = formId
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
  showValidation: (elem, validator) ->
    i = elem.parents(ValidationHelper._sharedAttributes.classes.bootstrap_form_group).find('.sj-validation-message')
    j = elem.parents(ValidationHelper._sharedAttributes.classes.bootstrap_form_group)
    if i.length?
      $(i).html('')
      $(i).css('display', 'none')
      if validator.message.length > 0
        for message in validator.message
          $(i).append(ValidationHelper._sharedAttributes.templates.validation_error.replace('{message}', message))
        $(j).addClass ValidationHelper._sharedAttributes.classes.validation_error
        $(i).fadeIn(100)
      else
        $(j).removeClass ValidationHelper._sharedAttributes.classes.validation_error
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
  serializeForm: ->
    $(@_formId).serializeArray()
  validate: ->
    self = @
    formData = @serializeForm()
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
                    when ValidationHelper._sharedAttributes.validators.required
                      if j.value.length == 0
                        validatorErrors.push ValidationHelper._sharedAttributes.messages.IS_REQUIRED.replace('{name}', j.name)
                    when ValidationHelper._sharedAttributes.validators.email
                      unless ValidationHelper._sharedAttributes.constants.regex_email.test j.value
                        validatorErrors.push ValidationHelper._sharedAttributes.messages.IS_INVALID_EMAIL.replace('{name}', j.name)
                    when ValidationHelper._sharedAttributes.validators.custom # this requires sj-custom
                        if k.length == 0
                          throw Error(ValidationHelper._sharedAttributes.errors.CUSTOM_FUNCTION_NOT_DEFINED)
                        for l, func of self._customValidators
                          if func?
                            if func.name is k
                              fResult = func.call this, elem, j.name, j.value
                              if typeof fResult is 'object'
                                if not (typeof fResult.result is 'boolean')
                                  throw Error(ValidationHelper._sharedAttributes.errors.CUSTOM_FUNCTION_NOT_RETURN_BOOLEAN)
                                if fResult.result == false
                                  validatorErrors.push fResult.message if fResult.message?
                              else
                                throw Error(ValidationHelper._sharedAttributes.errors.RESULTING_VALUE_INVALID)
                    else 
                      break
              self.addValidation
                name: j.name,
                message: validatorErrors
            # Make AJAX call to server to get validation data
            if self._validationUrl?
              $.ajax(
                method: self._validationUrlMethod
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
                  return
                ).fail( -> 
                  console.log '[WARN] Failed to contact validation service, fall back to client side validation'
                  self.processValidation(resolve, formData)
                )
            else
              self.processValidation(resolve, formData)
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
