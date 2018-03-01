class MapHelper
  # Class attributes
  @_sharedAttributes:
    constants:
      geocoding_api_url: 'https://maps.googleapis.com/maps/api/geocode/json?address={address}&key={api_key}'
      google_map_js_api_identifier: '/maps.googleapis.com/maps/api/js'
      google_map_js_api_key_identifier: 'key='
      placeholders:
        address: '{address}'
        api_key: '{api_key}'
      marker:
        unnamed_location: 'unnamed marker'
    errors:
        unable_to_get_geocoding_data: '[WARN] Failed to contact service to get geocoding data'
  _apiKey: ''
  _baseZoomLevel: 8
  _draggedMarker: null
  _element: null
  _map: null,
  _markers: []
  # Constructor
  constructor: (element, lat, long, zoomLevel) ->
    self = @
    # Look for Map API key
    $('script').each( (index) ->
      elem = $(this)
      src = elem.attr 'src'
      if src?
        if src.toLowerCase().indexOf(MapHelper._sharedAttributes.constants.google_map_js_api_identifier) != -1
          self._apiKey = src.substring src.indexOf(MapHelper._sharedAttributes.constants.google_map_js_api_key_identifier) + 4, src.indexOf(MapHelper._sharedAttributes.constants.google_map_js_api_key_identifier) + 43
    )
    # Do something with the google.maps.Maps object
    google.maps.Map.prototype.clearOverlays = ->
      for marker, index in self._markers
        marker.setMap(null);
      self._markers = []
      return
    # Instantiate the object and add values
    @_element = element
    if @_element?
      @_map = @initialise(lat, long, zoomLevel)
    return
  # Initialise the map
  initialise: (lat, long, zoomLevel) =>
    if zoomLevel?
      @_baseZoomLevel = zoomLevel
    new google.maps.Map(@_element,
      center:
        lat: lat
        lng: long
      zoom: @_baseZoomLevel
    )
  addMarker: (lat, long, label, title, image, isDraggable, isCleared, func) ->
    self = @
    self._draggedMarker = null
    if isCleared == true
      @_map.clearOverlays()
    # add marker
    marker = new google.maps.Marker(
      animation: google.maps.Animation.DROP,
      draggable: if isDraggable? then isDraggable else false
      icon: image
      label: if label? then label else null
      position:
        lat: lat
        lng: long
      title: if title? then title else MapHelper._sharedAttributes.constants.marker.unnamed_location
    )
    marker.addListener 'dragend', -> # handle dragend event
      self.focus this, true # center it when dragging ends
      self._draggedMarker =
        lat: this.getPosition().lat()
        lng: this.getPosition().lng()
      geocoder = new google.maps.Geocoder
      geocoder.geocode { 'location': self._draggedMarker }, (results, status) ->
        if status is 'OK'
          if results[0]?
            func(
              address_components: results[0].address_components,
              formatted_address: results[0].formatted_address
            )
      return
    marker.setMap @_map # show marker on map
    @_markers.push marker # add a marker to collection
    return
  focus: (marker, isCentered, zoomLevel) ->
    if zoomLevel?
      @_baseZoomLevel = zoomLevel
    if marker?
      if marker.getPosition?
        @_map.setCenter marker.getPosition()
      else
        @_map.setCenter marker
    return
  getCoordinate: (address) ->
    self = @
    new Promise (resolve, reject) ->
      if self._apiKey.length > 0 and address?
        $.ajax(
          type: 'GET'
          url: MapHelper._sharedAttributes.constants.geocoding_api_url.replace(MapHelper._sharedAttributes.constants.placeholders.address, address).replace(MapHelper._sharedAttributes.constants.placeholders.api_key, self._apiKey)
        ).done( (response) ->
          if response.status isnt 'ZERO_RESULTS'
            if response.results.length?
              if response.results[0].geometry?
                resolve response.results[0].geometry.location
              else
                reject()
            else
              reject()
          else
            reject()
        ).fail( ->
          console.log MapHelper._sharedAttributes.errors.unable_to_get_geocoding_data
          reject()
        )
      else
        reject()


module.exports = MapHelper
