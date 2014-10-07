fs        = require("fs")
path      = require("path")
_         = require("lodash")
chalk     = require("chalk")
async     = require("async")

module.exports = (settings, tcp) ->
  {options, files} = settings

  writeVar = (name, val) ->
    tcp.write("#{name}: #{val}\n")

  sendStdin = (callback) ->
    loadStdin = (callback) ->
      data = new Buffer()

      process.stdin.on "data", (_data) ->
        data = Buffer.concat(data, _data)

      process.stdin.on "error", (err) ->
        callback(err)

      process.stdin.on "end", () ->
        callback(null, data)

    loadStdin (err, data) ->
      return callback(err) if err
      return callback() unless data?

      writeVar "data", data.length
      tcp.write data, () ->
        callback()

  sendFile = (file, callback) ->
    stat = fs.statSync file
    return callback new Error("Not a file") unless stat.isFile()
    return callback new Error("Cannot determine file size") unless stat.size?
    writeVar "data", stat.size

    readStream = fs.createReadStream(file)

    readStream.on "error", (err) ->
      callback(err)

    readStream.on "end", () ->
      callback()

    readStream.pipe tcp, end: false

  sendEmptyFile = (callback) ->
    writeVar "data", 0
    tcp.write "0", () ->
      callback()

  sendOpen = (file, idx, callback) ->
    tcp.write("open\n")

    if options.names.length > idx
      writeVar "display-name", options.name[idx]
    else if file is "-"
      writeVar "display-name", "#{tcp.localAddress}:untitled (stdin)"
    else
      writeVar "display-name", "#{tcp.localAddress}:#{file}"

    writeVar "real-path", path.resolve(file) unless file is "-"
    writeVar "data-on-save", "yes"
    writeVar "re-activate", "yes"
    writeVar "token", file
    writeVar "selection", options.lines[idx] if options.lines.length > idx
    writeVar "file-type", "txt" if path is "-"
    writeVar "file-type", options.types[idx] if options.types.length > idx

    sendData = (callback) ->
      if file is "-"
        sendStdin(callback)
      else if fs.existsSync file
        sendFile(file, callback)
      else
        sendEmptyFile(callback)

    sendData (err) ->
      return console.error err if err
      tcp.write "\n", () ->
        callback()

  # send all files (asynchronously)
  pairs = ([file, idx] for file, idx in files)
  itr = (p, callback) -> sendOpen(p[0], p[1], callback)
  async.each pairs, itr, (err) ->
    return console.error err if err




