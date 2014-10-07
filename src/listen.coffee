fs        = require("fs")
path      = require("path")
_         = require("lodash")
chalk     = require("chalk")
async     = require("async")

module.exports = (settings, tcp, callback) ->
  {options, files, fileIsWritable} = settings
  firstLine = true
  strBuffer = ""

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

  handleCmd = (buff) ->
    console.error "handleCmd: #{buff}"
    [cmd, buff] = readLine buff

    variables = {}
    data = ""

    [line, buff] = readLine buff
    while line?
      break if line is "\n"
      [name, value] = line.split(": ", 2)
      if name is "data"
        size = parseInt(value)
        data = buff[..(size - 1)]
      else
        variables[name] = value
      [line, buff] = readLine buff

    console.error "== debug =="
    console.error cmd
    console.dir variables

    switch cmd
      when "save" then handleSave(variables, data)
      when "close" then handleClose(variables, data)
      else
        console.error "Received unknown command #{cmd}, exiting..."
        process.exit(1)

  handleFirstLine = (line) ->
    console.error "Connection: #{chomp(line)}" if options.verbose

  tcp.on 'data', (data) ->
    console.error "data: #{data}"
    handleData = () ->
      if firstLine
        idx = strBuffer.indexOf "\n"
        return if idx < 0
        line = strBuffer[..idx]
        handleFirstLine line
        strBuffer = strBuffer[(idx + 1)..]
        firstLine = false
        handleData()
      else
        idx = strBuffer.indexOf "\n\n"
        return if idx < 0
        buff = strBuffer[..(idx + 1)]
        handleCmd buff
        strBuffer = strBuffer[(idx + 2)..]
        handleData()

    strBuffer += data.toString("utf8")
    handleData()

  tcp.on 'end', () ->
    tcp.end()
    callback()

  tcp.on 'error', (err) ->
    callback(err)
