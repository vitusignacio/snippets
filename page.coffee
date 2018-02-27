ValidationHelper = require './validation_helper.js'
MapHelper = require './map_helper.js'

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
