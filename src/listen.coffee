fs        = require("fs")
path      = require("path")
async     = require("async")
settings  = require("./settings")

module.exports = (tcp, callback) ->
  {options, fileIsWritable} = settings
  firstLine = true
  strBuffer = ""
  cmdObj = {}

  chomp = (line) ->
    return line.replace /(\n|\r)+$/, ""

  handleSave = (variables, data) ->
    file = variables.token
    if fs.existsSync file or fileIsWritable file
      try
        console.error "Saving file #{file}" if options.verbose
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
    file = variables.token
    console.error "Closed file #{file}" if options.verbose

  readLine = (buff, chomp = true) ->
    idx = buff.indexOf("\n")
    return [null, buff] if idx < 0
    return ["", buff[1..]] if chomp and idx == 0
    line = buff[..(if chomp then (idx - 1) else idx)]
    buff = buff[(idx + 1)..]
    #console.log "line: #{line}"
    return [line, buff]

  # this is difficult to parse because we don't know in advance if we have the full message
  # or due to lack of unique delimiter, so we need to make this function reentrant
  handleCmd = () ->
    console.log "handleCmd: #{strBuffer}"
    unless cmdObj.cmd?
      [cmd, strBuffer] = readLine strBuffer
      return false unless cmd?
      cmdObj.cmd = cmd

    cmdObj.variables = {}

    assignData = () ->
      {size} = cmdObj
      return false unless strBuffer.length >= size
      cmdObj.data = strBuffer[..(size - 1)]
      strBuffer = strBuffer[size..]
      return true

    # in case we exited after we got data size, but not the whole data payload
    if cmdObj.size? and not cmdObj.data?
      return false unless assignData()

    # read in variables
    [line, strBuffer] = readLine strBuffer
    #console.log "foo1"
    return false unless line?
    while line isnt "\n"
      #console.log "foo2"
      [name, value] = line.split(": ", 2)
      if name is "data"
        cmdObj.size = parseInt(value)
        return false unless assignData()
      else
        cmdObj.variables[name] = value
      [line, strBuffer] = readLine strBuffer
      return false unless line?

    #console.dir cmdObj

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
    console.error "Editor: #{chomp(line)}" if options.verbose
    strBuffer = strBuffer[(idx + 1)..]
    firstLine = false
    return true

  tcp.on 'data', (data) ->
    handleData = () ->
      return unless strBuffer.length > 0
      if firstLine
        handleData() if handleFirstLine()
      else
#         strBuffer = """close
# token: testfile.txt

# """
        handleData() if handleCmd()

    strBuffer += data.toString("utf8")
    handleData()

  tcp.on 'end', () ->
    tcp.end()
    callback()

  tcp.on 'error', (err) ->
    callback(err)
