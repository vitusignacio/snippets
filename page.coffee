ValidationHelper = require('./validation_helper.js')

sendDataToServer = (formData) ->
  $.ajax(
    url: 'http://server.local:8080/post.php',
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
          helper = new ValidationHelper(formId, 'http://www.mocky.io/v2/5a8714cf3200006700f4e8d5', null,
            validate_txt_format: (elem, name, value) ->
              return value.indexOf('.txt') isnt -1
          )
        when '#form2'
          helper = new ValidationHelper(formId, null)
        else
          helper = null

      $(form).bind 'submit', (event) =>
        self = this
        event.preventDefault()
        if helper?
          new Promise((resolve, reject) ->
            helper.validate()
              .then (data) ->
                # mark the form as validated
                if data.result is true
                  $(event.target).removeClass 'needs-validation'
                  $(event.target).addClass 'was-validated'
                  sendDataToServer(new FormData(self))
                else
                  $(event.target).removeClass 'was-validated'
                  $(event.target).addClass 'needs-validation'
              .catch (error) ->
                # do something
          )
        else
          console.log '[WARN] No validation helpers detected'
        return false
        
      return
    )
