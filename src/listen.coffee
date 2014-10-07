fs        = require("fs")
path      = require("path")
_         = require("lodash")
chalk     = require("chalk")
async     = require("async")

module.exports = (settings, tcp, callback) ->
  {options, files, fileIsWritable} = settings
  firstLine = true
  strBuffer = ""
  cmdObj = {}

  chomp = (line) ->
    return line.replace /(\n|\r)+$/, ""

  handleSave = (variables, data) ->
    console.error "handleSave"
    file = variables.token
    if fs.existsSync file or fileIsWritable file
      try
        console.error "Saving #{file}" if options.verbose
        if fs.existsSync file
          backupFile = backupFileBase = "#{file}.bak"
          bakCount = 2
          while fs.existsSync backupFile
            backupFile = "#{backupFileBase}.bak#{bakCount}"
            bakCount += 1
          console.error "Backing up file to #{backupFile}" if options.verbose
          fs.linkSync file, backupFile
        writeStream = fs.createWriteStream file
        writeStream.end data, "utf8", () ->
          if fs.existsSync backupFile
            console.error "Removing backup file #{backupFile}" if options.verbose
            fs.unlinkSync backupFile
      catch ex
        console.error "Save failed: #{ex}" if options.verbose

    else
      console.error "Skipping save, file is not writable" if options.verbose


  handleClose = (variables, data) ->
    console.error "handleClose"
    file = variables.token
    console.error "Closed #{file}" if options.verbose

  readLine = (buff, chomp = true) ->
    idx = buff.indexOf("\n")
    return [null, buff] if idx < 0
    line = buff[..(if chomp then (idx - 1) else idx)]
    buff = buff[(idx + 1)..]
    return [line, buff]

  # this is difficult to parse because we don't know in advance if we have the full message
  # or due to lack of unique delimiter, so we need to make this function reentrant
  handleCmd = () ->
    console.error "handleCmd: #{strBuffer}"

    console.error "foo1"

    unless cmdObj.cmd?
      [cmd, strBuffer] = readLine strBuffer
      return false unless cmd?
      cmdObj.cmd = cmd

    console.error "foo2"

    cmdObj.variables = {}

    assignData = () ->
      console.error "foo7.1"
      {size} = cmdObj
      return false unless strBuffer.length >= size
      cmdObj.data = strBuffer[..(size - 1)]
      strBuffer = strBuffer[size..]
      console.error "foo7.2"
      return true

    console.error "foo3"

    # in case we exited after we got data size, but not the whole data payload
    if cmdObj.size? and not cmdObj.data?
      return false unless assignData()

    console.error "foo4"

    # read in variables
    [line, strBuffer] = readLine strBuffer
    return false unless line?
    console.error "foo5"
    while line isnt "\n"
      console.error "foo6"
      [name, value] = line.split(": ", 2)
      if name is "data"
        cmdObj.size = parseInt(value)
        return false unless assignData()
      else
        cmdObj.variables[name] = value
      [line, strBuffer] = readLine strBuffer
      return false unless line?

    console.error "foo8"

    console.error "== debug =="
    console.error cmdObj.cmd
    console.dir cmdObj.variables

    switch cmdObj.cmd
      when "save" then handleSave(cmdObj.variables, cmdObj.data)
      when "close" then handleClose(cmdObj.variables, cmdObj.data)
      else
        console.error "Received unknown command #{cmd}, exiting..."
        process.exit(1)

    cmdObj = {}
    return true

  handleFirstLine = () ->
    idx = strBuffer.indexOf "\n"
    return false if idx < 0
    line = strBuffer[..idx]
    console.error "Connection: #{chomp(line)}" if options.verbose
    strBuffer = strBuffer[(idx + 1)..]
    firstLine = false
    return true

  tcp.on 'data', (data) ->
    console.error "data: #{data}"
    handleData = () ->
      return unless strBuffer.length > 0
      if firstLine
        handleData() if handleFirstLine()
      else
        handleData() if handleCmd()

    strBuffer += data.toString("utf8")
    handleData()

  tcp.on 'end', () ->
    tcp.end()
    callback()

  tcp.on 'error', (err) ->
    callback(err)
