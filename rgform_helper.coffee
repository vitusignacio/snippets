class RgFormHelper
  @constants:
    classes:
      spinner: '.js-spinner'
  constructor: ->
    # Track ajax
    $(document).ajaxStart( ->
      console.log 'test'
      RgFormHelper.showOverlay()
      return
    ).ajaxStop( ->
      RgFormHelper.hideOverlay()
      return
    )
    return
  @showOverlay: ->
    $(RgFormHelper.constants.classes.spinner).show()
    return
  @hideOverlay: ->
    $(RgFormHelper.constants.classes.spinner).hide()
    return

module.exports = RgFormHelper
