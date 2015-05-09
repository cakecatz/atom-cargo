{MessagePanelView, PlainMessageView} = require 'atom-message-panel'
{BufferedProcess} = require 'atom'
AnsiFilter = require 'ansi-to-html'

module.exports = 
class LogView 
  
  constructor: ->
    @ansiFilter = new AnsiFilter
    unless @messages?
      @messages = new MessagePanelView
        title: 'Output'
        
  display: (css ,line) ->
    
    line = @ansiFilter.toHtml(line)
    @messages.attach()
    console.log line
    @messages.add new PlainMessageView
      raw: true
      message: line
      className: "atom-cargo-#{css}"
      
  close: ->
    @messages.clear()
    @messages.close()
      
