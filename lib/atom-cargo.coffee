LogView = require './log-view.coffee'
{CompositeDisposable, BufferedProcess, BufferedNodeProcess} = require 'atom'
ProjectSelector = require './project-selector.coffee'
path = require 'path'

module.exports = AtomCargo =
  cargoPath: null
  subscriptions: null
  projectName: ''
  projectInfo: null
  
  config:
    cargoPath:
      type: 'string' 
      default: path.normalize('/usr/local/bin')

  activate: (state) ->
    @subscriptions = new CompositeDisposable

    @cargoPath = atom.config.get('atom-cargo.cargoPath')

  consumeToolBar: (toolBar) ->
    @toolBar = toolBar 'atom-cargo'
    @addButtonToToolBar()

  addButtonToToolBar: ->
    @runButton = @toolBar.addButton
      icon: 'playback-play'
      tooltip: 'cargo run'
      callback: @run
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
    
    console.log app
    
    if app.projectInfo? && app.projectInfo.hasOwnProperty('bin')
      processName = app.projectInfo.bin[0].name
    else
      processName = app.projectInfo.package.name
    
    ps.spawn 'pkill', [processName]

  run: (app) ->
    app.runButton.setEnabled false
    if app.logView?
      app.logView.close()

    app.logView = new LogView
    command = 'cargo'
    args = ['run']
    
    stdout = (output) => app.logView.display 'stdout', output
    stderr = (output) => app.logView.display 'stderr', output
    exit = (code) ->
      console.log "Exited with #{code}"
      app.runButton.setEnabled true
      app.stopButton.setEnabled false    
      
    options = 
      env: process.env

    projects = atom.project.getPaths()
    options.env.PATH += ":#{app.cargoPath}"
    
    if projects.length is 1
      options['cwd'] = projects[0]
      tomlPath = app.findCargoToml projects[0]
      if tomlPath isnt ''
        app.projectInfo = app.getProjectInfo tomlPath
        app.currentProcess = new BufferedProcess {command, args, stdout, stderr, exit, options}
        app.stopButton.setEnabled true
      else
        app.runButton.setEnabled true
        
    else
      selector = new ProjectSelector projects, ->
        #on cancelled
        app.runButton.setEnabled true
        
      selector.setCallback (path) =>
        options['cwd'] = path
        tomlPath = app.findCargoToml path
        
        if tomlPath isnt ''
          app.projectInfo = app.getProjectInfo tomlPath
          app.currentProcess = new BufferedProcess {command, args, stdout, stderr, exit, options}
          app.stopButton.setEnabled true
        
        else
          app.runButton.setEnabled true
          
      selector.show()

  deactivate: ->
    @subscriptions.dispose()

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
    
