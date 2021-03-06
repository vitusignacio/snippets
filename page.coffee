ValidationHelper = require './validation_helper.js'
MapHelper = require './map_helper.js'
RgFormHelper = require './rgform_helper.js'

sendDataToServer = (formData) ->
  $.ajax(
    url: 'http://server.local:8080/post.php',
    type: 'POST',
    async: true,
    contentType: false,
    cache: false,
    processData: false,
    data: formData
  )

# Map stuffs
window.initMap = ->
  window.mapHelper = new MapHelper($('#google-map').get(0), LAT, LNG, 15) #TODO: Replace LAT, LNG with actual coordinate
  return

$ ->
    rgformHelper = new RgFormHelper()

    $('input[data-type=currency]:enabled').bind('keyup', (e) ->
      $this = $(this)
      value = $this.val()
      value = value.replace /[\D\s\._\-]+/g, ''
      value = if value then parseInt(value) else 0
      $this.val ->
        if value is 0 then '' else value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
      return
    ).bind('keypress', (e) ->
      e.preventDefault() if e.which < 48 or e.which > 57
      return
    )

    $('#send').bind 'click', (e) ->
      e.preventDefault()
      formData = new FormData($('#money-form').get(0))
      money = formData.get('money').replace(/,/g, '')
      formData.set 'money', money
      sendDataToServer(formData)

    # Map stuffs
    $('#google-location-search').bind 'click', ->
      value = $('#google-location').val()
      window.mapHelper.getCoordinate(value).then( (marker) ->
        window.mapHelper.addMarker marker.lat, marker.lng, null, null, window.sj, true, true, (geoData) ->
          console.log geoData
        window.mapHelper.focus marker
      ).catch( -> 
        console.log '[WARN] Geocoding is not able to retrieve location data'
      )

    # Form stuffs
    $('.needs-validation').each( (index, form) ->
      formId = '#' + $(form).attr('id')

      switch formId 
        when '#form1'
          helper = new ValidationHelper(formId, 'http://www.mocky.io/v2/5a8714cf3200006700f4e8d5', null,
            validate_txt_format: (elem, name, value) ->
              return value.indexOf('.txt') isnt -1
          )
          # helper._validationUrlMethod = 'POST'
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
