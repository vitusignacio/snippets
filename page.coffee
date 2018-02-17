ValidationHelper = require('./validation_helper.js')

sendDataToServer = (formData) ->
  $.ajax(
    url: '/test',
    type: 'POST',
    async: true,
    contentType: false,
    cache: false,
    processData: false,
    data: formData
  );

$ ->
    $('.needs-validation').each( (index, form) ->
      formId = '#' + $(form).attr('id')

      switch formId 
        when '#form1'
          helper = new ValidationHelper(formId, 'http://www.mocky.io/v2/5a8714cf3200006700f4e8d5')
        when '#form2'
          helper = new ValidationHelper(formId, null)
        else
          helper = null

      $(form).bind 'submit', (event) =>
        event.preventDefault()
        if helper?
          new Promise((resolve, reject) ->
            helper.validate()
              .then (data) ->
                # mark the form as validated
                if data.result is true
                  $(event.target).removeClass 'needs-validation'
                  $(event.target).addClass 'was-validated'
                else
                  $(event.target).removeClass 'was-validated'
                  $(event.target).addClass 'needs-validation'
              .catch (error) ->
                # do something
          )
        else
          console.log '[WARN] No validation helpers detected'
        sendDataToServer(new FormData(this))
        return false
        
      return
    )
