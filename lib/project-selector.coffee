{SelectListView, $$} = require 'atom-space-pen-views'

module.exports =
class ProjectSelector extends SelectListView
  initialize: (@listOfItems, @onCanceled) ->
    super
    @addClass('cargo-project-select-list')
    @setItems(@listOfItems)

  viewForItem: (item) ->
    $$ -> @li(item)

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()

    @storeFocusedElement()

    @focusFilterEditor()

  toggle: ->
    if @panel?.isVisible()
      @cancel()
    else
      @show()

  cancel: ->
    @cancelled()

  cancelled: ->
    @hide()
    @restoreFocus()
    if @onCanceled?
      @onCanceled()

  hide: ->
    @panel?.hide()

  setCallback: (cb) ->
    @callback = cb

  confirmed: (item) ->
    @cancel()
    @callback(item)
