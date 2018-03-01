class RgFormHelper
  @constants:
    classes:
      spinner: '.js-spinner'
  constructor: ->
    self = this
    # Track ajax
    $(document).ajaxStart( ->
      self.showOverlay()
      return
    ).ajaxStop( ->
      self.hideOverlay()
      return
    )
    return
  changePage: (step) ->
    # do something to change page
  showOverlay: ->
    $(RgFormHelper.constants.classes.spinner).show()
    return
  hideOverlay: ->
    $(RgFormHelper.constants.classes.spinner).hide()
    return

module.exports = RgFormHelper
