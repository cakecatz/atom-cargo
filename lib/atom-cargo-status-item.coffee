{View} = require 'atom'

module.exports = 
class cargoStatusItem
  constructor: ->
    @element = document.createElement 'div'
    @element.id = 'status-bar-atom-cargo'
    
    @container = document.createElement 'div'
    @container.className = 'inline-block'
    @container.appendChild @element
    
  initialize: (@statusBar) ->
    
  update: (title) ->
    @element.textContent = title
    
  attach: ->
    @tile = @statusBar.addRightTile(item: @container, priority: 20)
    
  detach: ->
    @tile.destroy()