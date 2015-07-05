LogView = require './log-view.coffee'
{CompositeDisposable, BufferedProcess, BufferedNodeProcess} = require 'atom'
ProjectSelector = require './project-selector.coffee'
cargoStatusItem = require './atom-cargo-status-item.coffee'
path = require 'path'

module.exports = AtomCargo =
  cargoPath: null
  subscriptions: null
  projectName: ''
  projectInfo: null
  projectType: 'bin'
  
  config:
    cargoPath:
      type: 'string' 
      default: path.normalize('/usr/local/bin')

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    
    @subscriptions.add atom.commands.add 'atom-text-editor', 'atom-cargo:run', =>
      @start(this)
      
    @subscriptions.add atom.commands.add 'atom-text-editor', 'atom-cargo:change-type', =>
      @changeType()

    @cargoPath = atom.config.get('atom-cargo.cargoPath')
    
  changeType: ->
    if @projectType is 'bin'
      @projectType = 'lib'
    else
      @projectType = 'bin'
      
    @statusItem.update "cargo:#{@projectType}"
    console.log @projectType
    
  consumeStatusBar: (statusBar) ->
    @statusItem = new cargoStatusItem()
    
    @statusItem.initialize statusBar
    @statusItem.attach()
    @statusItem.update "cargo:#{@projectType}"

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'atom-cargo'
    @addButtonToToolBar()

  addButtonToToolBar: ->
    @runButton = @toolBar.addButton
      icon: 'playback-play'
      tooltip: 'cargo run'
      callback: @start
      data: this
    @runButton.css 'color', '#2ecc71'
    @runButton.setEnabled false unless @cargoPath?

    @stopButton = @toolBar.addButton
      icon: 'primitive-square'
      tooltip: 'stop'
      callback: @stop
      data: this
    @stopButton.css 'color', '#e74c3c'
    @stopButton.setEnabled false

  stop: (app) ->
    ps = require 'child_process'
    
    if app.projectInfo? && app.projectInfo.hasOwnProperty('bin')
      processName = app.projectInfo.bin[0].name
    else
      processName = app.projectInfo.package.name
    
    ps.spawn 'pkill', [processName]

  start: (app) ->
    console.log this
    app.runButton.setEnabled false
    if app.logView?
      app.logView.close()

    app.logView = new LogView
    
    projects = atom.project.getPaths()
    
    if projects.length is 1
      path = projects[0]
      app.run {app, path}
        
    else
      selector = new ProjectSelector projects, ->
        #on cancelled
        app.runButton.setEnabled true
        
      selector.setCallback (path) =>
        app.run {app, path}
          
      selector.show()
      
  run: ({app, path}) ->
    command = 'cargo'
    stdout = (output) => app.logView.display 'stdout', output
    stderr = (output) => app.logView.display 'stderr', output
    exit = (code) ->
      console.log "Exited with #{code}"
      app.runButton.setEnabled true
      app.stopButton.setEnabled false  
    
    options = 
      env: process.env
      cwd: path
      
    options.env.PATH += ":#{app.cargoPath}"
      
    tomlPath = app.findCargoToml path
    if tomlPath isnt ''
      app.projectInfo = app.getProjectInfo tomlPath
      
      if app.projectType is 'lib'
        args = ['build'] 
      else if app.projectType is 'bin'
        args = ['run']
        
      app.currentProcess = new BufferedProcess {command, args, stdout, stderr, exit, options}
      app.stopButton.setEnabled true
    else
      app.runButton.setEnabled true

  deactivate: ->
    @subscriptions.dispose()
    @statusItem?.detach()

  serialize: ->
    
  getProjectInfo: (cargoTomlPath) ->
    toml = require 'toml'
    fs = require 'fs'
    
    tomlString = fs.readFileSync cargoTomlPath,
      encoding: 'utf8'
      
    return toml.parse(tomlString)
    
  findCargoToml: (projectPath) ->
    fs = require 'fs-plus'
    list = fs.listSync projectPath
    for p in list
      return p if p.indexOf('Cargo.toml') >= 0
    
    return ''
    
